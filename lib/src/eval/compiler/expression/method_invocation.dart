import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/funcexpr_invocation.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/equality.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/model/registers.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/shared/registers.dart';

import 'expression.dart';
import 'identifier.dart';

Variable compileMethodInvocation(CompilerContext ctx, MethodInvocation e,
    {TypeRef? bound, Variable? cascadeTarget}) {
  Variable? L = cascadeTarget;
  var isPrefix = false;
  if (e.target != null && cascadeTarget == null) {
    try {
      L = compileExpression(e.target!, ctx);
    } on PrefixError {
      isPrefix = true;
    }
  }

  AlwaysReturnType? mReturnType;

  if (L != null) {
    if (e.operator?.type == TokenType.QUESTION_PERIOD) {
      var out = BuiltinValue().push(ctx).boxIfNeeded(ctx);
      if (L.concreteTypes.length == 1 &&
          L.concreteTypes[0] == CoreTypes.nullType.ref(ctx)) {
        return out;
      }
      macroBranch(ctx, null, condition: (_ctx) {
        return checkNotEqual(ctx, L!, out);
      }, thenBranch: (_ctx, rt) {
        final V = _invokeWithTarget(ctx, L!, e);
        out = out.copyWith(type: V.type.copyWith(nullable: true));
        ctx.pushOp(Assign(out.ssa, V.ssa));
        return StatementInfo(-1);
      });
      return out;
    }
    return _invokeWithTarget(ctx, L, e);
  }
  final method = isPrefix
      ? compilePrefixedIdentifier(
          (e.target as Identifier).name, e.methodName.name, ctx)
      : compileIdentifier(e.methodName, ctx);

  if (method.callingConvention == CallingConvention.dynamic ||
      (method.type == CoreTypes.function.ref(ctx) &&
          method.methodOffset == null)) {
    return invokeClosure(ctx, null, method, e.argumentList);
  }

  if (method.methodOffset == null) {
    throw CompileError(
        'Cannot call ${e.methodName.name} as it is not a valid method');
  }

  final offset = method.methodOffset!;
  if (offset.file == ctx.library &&
      offset.className != null &&
      offset.className == (ctx.currentClass?.name.lexeme)) {
    final $this = ctx.lookupLocal('#this')!;
    return _invokeWithTarget(ctx, $this, e);
  }

  var _dec = ctx.topLevelDeclarationsMap[offset.file]![e.methodName.name];
  if (_dec == null ||
      (!_dec.isBridge && _dec.declaration! is ClassDeclaration)) {
    _dec = ctx.topLevelDeclarationsMap[offset.file]![
        offset.name ?? '${e.methodName.name}.'];
    if (_dec == null) {
      // Call to default constructor
      ctx.pushOp(Call(offset, []));
      mReturnType = method.methodReturnType
              ?.toAlwaysReturnType(ctx, TypeRef.$this(ctx), [], {}) ??
          AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
      final _returnType = mReturnType.type?.copyWith(
          boxed: L != null ||
              !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ?? false));
      final v = Variable.ssa(
          ctx,
          AssignRegister(ctx.svar('new_${e.methodName.name}_result'), regGPR1),
          mReturnType.type?.copyWith(
                  boxed: L != null ||
                      !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ??
                          false)) ??
              CoreTypes.dynamic.ref(ctx),
          concreteTypes: _returnType == null ? [] : [_returnType]);

      return v;
    }
  }

  final List<Variable> _args;
  final List<SSA> ssaArgs;
  final Map<String, Variable> _namedArgs;

  final resolveGenerics = <String, TypeRef>{};
  var isConstructor = false;

  if (_dec.isBridge) {
    final bridge = _dec.bridge;

    /// If we're invoking a class identifier directly (like ClassName()), call
    /// its default constructor
    final fnDescriptor = bridge is BridgeClassDef
        ? (bridge.constructors['']?.functionDescriptor ??
            (throw CompileError(
                'Class "${e.methodName.name}" does not have a default constructor',
                e)))
        : (bridge as BridgeFunctionDeclaration).function;

    final argsPair = compileArgumentListWithBridge(
        ctx, e.argumentList, fnDescriptor,
        before: L != null ? [L] : []);

    _args = argsPair.args;
    _namedArgs = argsPair.namedArgs;
    ssaArgs = argsPair.ssa.map((e) => SSA(e)).toList();
    isConstructor = bridge is BridgeClassDef;
  } else {
    final dec = _dec.declaration!;

    List<FormalParameter> fpl;
    List<TypeParameter>? typeParams;
    TypeAnnotation? returnAnnotation;
    if (dec is FunctionDeclaration) {
      fpl =
          dec.functionExpression.parameters?.parameters ?? <FormalParameter>[];
      typeParams = dec.functionExpression.typeParameters?.typeParameters;
      returnAnnotation = dec.returnType;
    } else if (dec is MethodDeclaration) {
      fpl = dec.parameters?.parameters ?? <FormalParameter>[];
      typeParams = dec.typeParameters?.typeParameters;
      returnAnnotation = dec.returnType;
    } else if (dec is ConstructorDeclaration) {
      fpl = dec.parameters.parameters;
      isConstructor = true;
    } else {
      throw CompileError('Invalid declaration type ${dec.runtimeType}');
    }

    if (typeParams != null) {
      for (final param in typeParams) {
        final bound = param.bound;
        final name = param.name.lexeme;
        if (bound != null) {
          resolveGenerics[name] =
              TypeRef.fromAnnotation(ctx, offset.file!, bound);
        } else {
          resolveGenerics[name] = CoreTypes.dynamic.ref(ctx);
        }
      }
    }

    final argsPair = compileArgumentList(
        ctx, e.argumentList, offset.file!, fpl, dec,
        before: L != null ? [L] : [],
        source: e,
        resolveGenerics: resolveGenerics);

    if (returnAnnotation != null && returnAnnotation is NamedType) {
      final g = resolveGenerics[returnAnnotation.name2.value()];
      if (g != null) {
        mReturnType = AlwaysReturnType(g, returnAnnotation.question != null);
      }
    }
    _args = argsPair.args;
    ssaArgs = argsPair.ssa.map((e) => SSA(e)).toList();
    _namedArgs = argsPair.namedArgs;
  }

  final _argTypes = _args.map((e) => e.type).toList();
  final _namedArgTypes =
      _namedArgs.map((key, value) => MapEntry(key, value.type));

  final invokeResult = ctx.svar('${e.methodName.name}_result');

  TypeRef? thisType;
  if (ctx.currentClass != null) {
    thisType = ctx.visibleTypes[ctx.library]![ctx.currentClass!.name.lexeme]!;
  }

  mReturnType ??= method.methodReturnType
          ?.toAlwaysReturnType(ctx, thisType, _argTypes, _namedArgTypes) ??
      AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
  final _returnType = mReturnType.type?.copyWith(
      boxed: _dec.isBridge ||
          !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ?? false));

  if (_dec.isBridge) {
    final bridge = _dec.bridge!;
    if (bridge is BridgeClassDef && !bridge.wrap) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);

      final $null = BuiltinValue().push(ctx);
      final op = BridgeInstantiate(
          invokeResult,
          ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.']!,
          $null.ssa,
          ssaArgs);
      ctx.pushOp(op);
    } else {
      ctx.pushOp(InvokeExternal(
          invokeResult,
          ctx.bridgeStaticFunctionIndices[offset.file]![offset.name]!,
          ssaArgs));
    }
  } else {
    ctx.pushOp(Call(offset, ssaArgs));
    ctx.pushOp(AssignRegister(invokeResult,
        returnTypeToRegister(ctx, _returnType ?? CoreTypes.dynamic.ref(ctx))));
  }

  final v = Variable.of(
      ctx, invokeResult, _returnType ?? CoreTypes.dynamic.ref(ctx),
      concreteTypes: [if (isConstructor && _returnType != null) _returnType]);

  return v;
}

Variable _invokeWithTarget(
    CompilerContext ctx, Variable L, MethodInvocation e) {
  AlwaysReturnType? mReturnType;

  final DeclarationOrBridge<ClassMember, BridgeDeclaration> _dec;
  final bool isStatic;
  TypeRef? staticType;

  ArgumentListResult argsPair;

  final knownMethod = getKnownMethods(ctx)[L.type]?[e.methodName.name];

  if (knownMethod != null &&
      L.type != CoreTypes.type.ref(ctx) &&
      L.type != CoreTypes.dynamic.ref(ctx)) {
    argsPair = compileArgumentListWithKnownMethodArgs(
        ctx, e.argumentList, knownMethod.args, knownMethod.namedArgs);
    return L.invoke(ctx, e.methodName.name, []).result;
  }

  if (L.type == CoreTypes.type.ref(ctx) && L.concreteTypes.length == 1) {
    // Static method
    staticType = L.concreteTypes[0];
    _dec = resolveStaticMethod(ctx, staticType, e.methodName.name);
    isStatic = true;
  } else {
    _dec = resolveInstanceMethod(ctx, L.type, e.methodName.name, e);
    isStatic = false;
  }

  if (_dec.isBridge) {
    final br = _dec.bridge!;
    final fd = br is BridgeMethodDef
        ? br.functionDescriptor
        : (br as BridgeConstructorDef).functionDescriptor;
    argsPair =
        compileArgumentListWithBridge(ctx, e.argumentList, fd, before: []);
  } else {
    final dec = _dec.declaration!;
    final fpl = (dec is MethodDeclaration
            ? dec.parameters?.parameters
            : (dec as ConstructorDeclaration).parameters.parameters) ??
        <FormalParameter>[];

    argsPair = compileArgumentList(
        ctx, e.argumentList, (isStatic ? staticType! : L.type).file, fpl, dec,
        before: [if (!isStatic) L], source: e);
  }

  final _args = argsPair.args;
  final _namedArgs = argsPair.namedArgs;
  final _ssaArgs = argsPair.ssa.map((e) => SSA(e)).toList();

  final _argTypes = _args.map((e) => e.type).toList();
  final _namedArgTypes =
      _namedArgs.map((key, value) => MapEntry(key, value.type));

  mReturnType = AlwaysReturnType.fromInstanceMethodOrBuiltin(
      ctx,
      isStatic ? staticType! : L.type,
      e.methodName.name,
      _argTypes,
      _namedArgTypes,
      $static: isStatic);

  final returnType =
      mReturnType?.type?.copyWith(boxed: true) ?? CoreTypes.dynamic.ref(ctx);

  final result = ctx.svar('${e.methodName.name}_result');

  if (isStatic) {
    if (_dec.isBridge) {
      ctx.pushOp(InvokeExternal(
          result,
          ctx.bridgeStaticFunctionIndices[staticType!.file]![
              '${staticType.name}.${e.methodName.name}']!,
          _ssaArgs));
    } else {
      final offset = DeferredOrOffset.lookupStatic(
          ctx, staticType!.file, staticType.name, e.methodName.name);
      ctx.pushOp(Call(offset, _ssaArgs));
      ctx.pushOp(AssignRegister(result, returnTypeToRegister(ctx, returnType)));
    }
  } else if (L.concreteTypes.length == 1 && !_dec.isBridge) {
    // If the concrete type is known we can use a static call
    final actualType = L.concreteTypes[0];
    final offset = DeferredOrOffset(
        file: actualType.file,
        className: actualType.name,
        methodType: 2,
        name: e.methodName.name);
    ctx.pushOp(Call(offset, _args.map((e) => e.ssa).toList()));
    ctx.pushOp(AssignRegister(result, returnTypeToRegister(ctx, returnType)));
  } else {
    ctx.pushOp(InvokeDynamic(
        result, L.boxIfNeeded(ctx).ssa, e.methodName.name, _ssaArgs));
  }

  return Variable.of(ctx, result, returnType);
}

DeclarationOrBridge<MethodDeclaration, BridgeMethodDef> resolveInstanceMethod(
    CompilerContext ctx, TypeRef instanceType, String methodName,
    [AstNode? source, TypeRef? bottomType]) {
  final _dec =
      ctx.topLevelDeclarationsMap[instanceType.file]![instanceType.name]!;
  final _bottomType = bottomType ?? instanceType;
  if (_dec.isBridge) {
    // Bridge
    final bridge = _dec.bridge!;
    final method = bridge is BridgeClassDef
        ? bridge.methods[methodName]
        : (bridge as BridgeEnumDef).methods[methodName];
    if (method == null) {
      final $extendsBridgeType =
          bridge is BridgeClassDef ? bridge.type.$extends : null;
      if ($extendsBridgeType == null && bridge is! BridgeEnumDef) {
        throw CompileError('Unknown method $_bottomType.$methodName', source);
      }
      final $extendsType = bridge is BridgeEnumDef
          ? CoreTypes.enumType.ref(ctx)
          : TypeRef.fromBridgeTypeRef(ctx, $extendsBridgeType!);
      return resolveInstanceMethod(
          ctx, $extendsType, methodName, source, _bottomType);
    }
    return DeclarationOrBridge(instanceType.file, bridge: method);
  }

  final dec = ctx.instanceDeclarationsMap[instanceType.file]![
      instanceType.name]![methodName];

  if (dec != null) {
    return DeclarationOrBridge(instanceType.file,
        declaration: dec as MethodDeclaration);
  } else {
    final $class = _dec.declaration as ClassDeclaration;
    if ($class.extendsClause == null) {
      return resolveInstanceMethod(
          ctx, CoreTypes.object.ref(ctx), methodName, source, _bottomType);
    }
    final $supertype = ctx.visibleTypes[instanceType.file]![
        $class.extendsClause!.superclass.name2.value()]!;
    return resolveInstanceMethod(
        ctx, $supertype, methodName, source, _bottomType);
  }
}

DeclarationOrBridge<ClassMember, BridgeDeclaration> resolveStaticMethod(
    CompilerContext ctx, TypeRef classType, String methodName) {
  final method = ctx.topLevelDeclarationsMap[classType.file]![
      '${classType.name}.$methodName'];
  if (method != null) {
    if (method.declaration != null) {
      return DeclarationOrBridge(classType.file,
          declaration: method.declaration! as ClassMember);
    } else {
      return DeclarationOrBridge(classType.file, bridge: method.bridge!);
    }
  }

  throw CompileError('Cannot find static method $classType.$methodName');
}
