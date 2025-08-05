import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/closure.dart';
import 'package:dart_eval/src/eval/compiler/helpers/equality.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../util.dart';
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
      macroBranch(ctx, null, condition: (ctx) {
        return checkNotEqual(ctx, L!, out);
      }, thenBranch: (ctx, rt) {
        final V = _invokeWithTarget(ctx, L!, e);
        out = out.copyWith(type: V.type.copyWith(nullable: true));
        ctx.pushOp(CopyValue.make(out.scopeFrameOffset, V.scopeFrameOffset),
            CopyValue.LEN);
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
    return invokeClosure(ctx, null, method, e.argumentList).result;
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

  var dec0 = ctx.topLevelDeclarationsMap[offset.file]![e.methodName.name];
  if (dec0 == null ||
      (!dec0.isBridge && dec0.declaration! is ClassDeclaration)) {
    dec0 = ctx.topLevelDeclarationsMap[offset.file]![
        offset.name ?? '${e.methodName.name}.'];
    if (dec0 == null) {
      // Call to default constructor
      final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.length);
      if (offset.offset == null) {
        ctx.offsetTracker.setOffset(loc, offset);
      }
      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
      mReturnType = method.methodReturnType
              ?.toAlwaysReturnType(ctx, TypeRef.$this(ctx), [], {}) ??
          AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
      final returnType = mReturnType.type?.copyWith(
          boxed: L != null ||
              !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ?? false));
      final v = Variable.alloc(
          ctx,
          mReturnType.type?.copyWith(
                  boxed: L != null ||
                      !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ??
                          false)) ??
              CoreTypes.dynamic.ref(ctx),
          concreteTypes: returnType == null ? [] : [returnType]);

      return v;
    }
  }

  final List<Variable> args;
  final Map<String, Variable> namedArgs;

  final resolveGenerics = <String, TypeRef>{};
  var isConstructor = false;

  if (dec0.isBridge) {
    final bridge = dec0.bridge;

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

    args = argsPair.first;
    namedArgs = argsPair.second;
    isConstructor = bridge is BridgeClassDef;
  } else {
    final dec = dec0.declaration!;

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
    args = argsPair.first;
    namedArgs = argsPair.second;
  }

  final argTypes = args.map((e) => e.type).toList();
  final namedArgTypes =
      namedArgs.map((key, value) => MapEntry(key, value.type));

  if (dec0.isBridge) {
    final bridge = dec0.bridge!;
    if (bridge is BridgeClassDef && !bridge.wrap) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);

      final $null = BuiltinValue().push(ctx);
      final op = BridgeInstantiate.make($null.scopeFrameOffset,
          ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.']!);
      ctx.pushOp(op, BridgeInstantiate.len(op));
    } else {
      final op = InvokeExternal.make(
          ctx.bridgeStaticFunctionIndices[offset.file]![offset.name]!);
      ctx.pushOp(op, InvokeExternal.LEN);
      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    }
  } else {
    final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.length);
    if (offset.offset == null) {
      ctx.offsetTracker.setOffset(loc, offset);
    }
    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  }

  TypeRef? thisType;
  if (ctx.currentClass != null) {
    thisType = ctx.visibleTypes[ctx.library]![ctx.currentClass!.name.lexeme]!;
  }

  mReturnType ??= method.methodReturnType
          ?.toAlwaysReturnType(ctx, thisType, argTypes, namedArgTypes) ??
      AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
  final returnType = mReturnType.type?.copyWith(
      boxed: dec0.isBridge ||
          !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ?? false));

  final v = Variable.alloc(ctx, returnType ?? CoreTypes.dynamic.ref(ctx),
      concreteTypes: [if (isConstructor && returnType != null) returnType]);

  return v;
}

Variable _invokeWithTarget(
    CompilerContext ctx, Variable L, MethodInvocation e) {
  AlwaysReturnType? mReturnType;

  DeclarationOrBridge<ClassMember, BridgeDeclaration>? dec0;
  final bool isStatic;
  TypeRef? staticType;

  Pair<List<Variable>, Map<String, Variable>> argsPair;

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
    dec0 = resolveStaticMethod(ctx, staticType, e.methodName.name);
    isStatic = true;
  } else if (L.type != CoreTypes.dynamic.ref(ctx)) {
    dec0 = resolveInstanceMethod(ctx, L.type, e.methodName.name, e);
    isStatic = false;
  } else {
    isStatic = false;
  }

  if (dec0?.isBridge == true) {
    final br = dec0!.bridge!;
    final fd = br is BridgeMethodDef
        ? br.functionDescriptor
        : (br as BridgeConstructorDef).functionDescriptor;
    argsPair =
        compileArgumentListWithBridge(ctx, e.argumentList, fd, before: []);
  } else if (L.type == CoreTypes.dynamic.ref(ctx)) {
    argsPair = compileArgumentListWithDynamic(ctx, e.argumentList, before: [L]);
  } else {
    final dec = dec0!.declaration!;
    final fpl = (dec is MethodDeclaration
            ? dec.parameters?.parameters
            : (dec as ConstructorDeclaration).parameters.parameters) ??
        <FormalParameter>[];

    argsPair = compileArgumentList(
        ctx, e.argumentList, (isStatic ? staticType! : L.type).file, fpl, dec,
        before: [if (!isStatic) L], source: e);
  }

  final args = argsPair.first;
  final namedArgs = argsPair.second;

  final argTypes = args.map((e) => e.type).toList();
  final namedArgTypes =
      namedArgs.map((key, value) => MapEntry(key, value.type));

  if (isStatic) {
    if (dec0!.isBridge) {
      final ix = InvokeExternal.make(ctx.bridgeStaticFunctionIndices[
          staticType!.file]!['${staticType.name}.${e.methodName.name}']!);
      ctx.pushOp(ix, InvokeExternal.LEN);
    } else {
      final offset = DeferredOrOffset.lookupStatic(
          ctx, staticType!.file, staticType.name, e.methodName.name);
      final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.length);
      if (offset.offset == null) {
        ctx.offsetTracker.setOffset(loc, offset);
      }
    }
  } else if (L.concreteTypes.length == 1 && !dec0!.isBridge) {
    // If the concrete type is known we can use a static call
    final actualType = L.concreteTypes[0];
    final offset = DeferredOrOffset(
        file: actualType.file,
        className: actualType.name,
        methodType: 2,
        name: e.methodName.name);
    final loc = ctx.pushOp(Call.make(-1), Call.length);
    ctx.offsetTracker.setOffset(loc, offset);
  } else {
    final op = InvokeDynamic.make(L.boxIfNeeded(ctx).scopeFrameOffset,
        ctx.constantPool.addOrGet(e.methodName.name));
    ctx.pushOp(op, InvokeDynamic.len(op));
  }

  mReturnType = AlwaysReturnType.fromInstanceMethodOrBuiltin(
      ctx,
      isStatic ? staticType! : L.type,
      e.methodName.name,
      argTypes,
      namedArgTypes,
      $static: isStatic);

  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

  final v = Variable.alloc(ctx,
      mReturnType?.type?.copyWith(boxed: true) ?? CoreTypes.dynamic.ref(ctx));

  return v;
}

DeclarationOrBridge<MethodDeclaration, BridgeMethodDef> resolveInstanceMethod(
    CompilerContext ctx, TypeRef instanceType, String methodName,
    [AstNode? source, TypeRef? bottomType]) {
  final dec0 =
      ctx.topLevelDeclarationsMap[instanceType.file]![instanceType.name]!;
  final bottomType0 = bottomType ?? instanceType;
  if (dec0.isBridge) {
    // Bridge
    final bridge = dec0.bridge!;
    final method = bridge is BridgeClassDef
        ? bridge.methods[methodName]
        : (bridge as BridgeEnumDef).methods[methodName];
    if (method == null) {
      final $extendsBridgeType =
          bridge is BridgeClassDef ? bridge.type.$extends : null;
      if ($extendsBridgeType == null && bridge is! BridgeEnumDef) {
        throw CompileError('Unknown method $bottomType0.$methodName', source);
      }
      final $extendsType = bridge is BridgeEnumDef
          ? CoreTypes.enumType.ref(ctx)
          : TypeRef.fromBridgeTypeRef(ctx, $extendsBridgeType!);
      return resolveInstanceMethod(
          ctx, $extendsType, methodName, source, bottomType0);
    }
    return DeclarationOrBridge(instanceType.file, bridge: method);
  }

  final dec = ctx.instanceDeclarationsMap[instanceType.file]![
      instanceType.name]![methodName];

  if (dec != null) {
    return DeclarationOrBridge(instanceType.file,
        declaration: dec as MethodDeclaration);
  } else {
    final $class = dec0.declaration as ClassDeclaration;
    if ($class.extendsClause == null) {
      return resolveInstanceMethod(
          ctx, CoreTypes.object.ref(ctx), methodName, source, bottomType0);
    }
    final $supertype = ctx.visibleTypes[instanceType.file]![
        $class.extendsClause!.superclass.name2.value()]!;
    return resolveInstanceMethod(
        ctx, $supertype, methodName, source, bottomType0);
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
