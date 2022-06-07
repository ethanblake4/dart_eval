import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/funcexpr_invocation.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../util.dart';
import 'expression.dart';
import 'identifier.dart';

Variable compileMethodInvocation(CompilerContext ctx, MethodInvocation e) {
  Variable? L;
  if (e.target != null) {
    L = compileExpression(e.target!, ctx);
  }

  AlwaysReturnType? mReturnType;

  if (L != null) {
    return _invokeWithTarget(ctx, L, e);
  } else {
    final method = compileIdentifier(e.methodName, ctx);

    if (method.methodOffset == null) {
      throw CompileError('Cannot call ${e.methodName.name} as it is not a valid method');
    }

    if (method.callingConvention == CallingConvention.dynamic) {
      return invokeClosure(ctx, null, method, e.argumentList);
    }

    final offset = method.methodOffset!;
    if (offset.file == ctx.library && offset.className != null && offset.className == ctx.currentClass?.name.name) {
      final $this = ctx.lookupLocal('#this')!;
      return _invokeWithTarget(ctx, $this, e);
    }

    var _dec = ctx.topLevelDeclarationsMap[offset.file]![e.methodName.name];
    if (_dec == null || (!_dec.isBridge && _dec.declaration! is ClassDeclaration)) {
      _dec = ctx.topLevelDeclarationsMap[offset.file]![offset.name ?? e.methodName.name + '.'] ??
          (throw CompileError(
              'Cannot instantiate: The class ${e.methodName.name} does not have a default constructor'));
    }

    final List<Variable> _args;
    final Map<String, Variable> _namedArgs;

    if (_dec.isBridge) {
      final bridge = _dec.bridge;
      final fnDescriptor = bridge is BridgeClassDef
          ? bridge.constructors['']!.functionDescriptor
          : (bridge as BridgeFunctionDeclaration).function;

      final argsPair = compileArgumentListWithBridge(ctx, e.argumentList, fnDescriptor, before: L != null ? [L] : []);

      _args = argsPair.first;
      _namedArgs = argsPair.second;
    } else {
      final dec = _dec.declaration!;

      List<FormalParameter> fpl;
      if (dec is FunctionDeclaration) {
        fpl = dec.functionExpression.parameters?.parameters ?? <FormalParameter>[];
      } else if (dec is MethodDeclaration) {
        fpl = dec.parameters?.parameters ?? <FormalParameter>[];
      } else if (dec is ConstructorDeclaration) {
        fpl = dec.parameters.parameters;
      } else {
        throw CompileError('Invalid declaration type ${dec.runtimeType}');
      }

      final argsPair = compileArgumentList(ctx, e.argumentList, offset.file!, fpl, dec, before: L != null ? [L] : []);
      _args = argsPair.first;
      _namedArgs = argsPair.second;
    }

    final _argTypes = _args.map((e) => e.type).toList();
    final _namedArgTypes = _namedArgs.map((key, value) => MapEntry(key, value.type));

    if (_dec.isBridge) {
      final bridge = _dec.bridge!;
      if (bridge is BridgeClassDef && !bridge.wrap) {
        final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);

        final $null = BuiltinValue().push(ctx);
        final op = BridgeInstantiate.make(
            $null.scopeFrameOffset, ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.']!);
        ctx.pushOp(op, BridgeInstantiate.len(op));
      } else {
        final op = InvokeExternal.make(ctx.bridgeStaticFunctionIndices[offset.file]![offset.name]!);
        ctx.pushOp(op, InvokeExternal.LEN);
        ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
      }
    } else {
      final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.LEN);
      if (offset.offset == null) {
        ctx.offsetTracker.setOffset(loc, offset);
      }
      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    }

    TypeRef? thisType;
    if (ctx.currentClass != null) {
      thisType = ctx.visibleTypes[ctx.library]![ctx.currentClass!.name.name]!;
    }
    mReturnType = method.methodReturnType?.toAlwaysReturnType(thisType, _argTypes, _namedArgTypes) ??
        AlwaysReturnType(EvalTypes.dynamicType, true);
  }

  final v = Variable.alloc(
      ctx,
      mReturnType.type?.copyWith(boxed: L != null || !unboxedAcrossFunctionBoundaries.contains(mReturnType.type)) ??
          EvalTypes.dynamicType);

  return v;
}

Variable _invokeWithTarget(CompilerContext ctx, Variable L, MethodInvocation e) {
  AlwaysReturnType? mReturnType;

  final DeclarationOrBridge<MethodDeclaration, BridgeDeclaration> _dec;
  final bool isStatic;
  TypeRef? staticType;

  if (L.type.file == -1 && L.type != EvalTypes.typeType) {
    return L.invoke(ctx, e.methodName.name, []).result;
  }

  if (L.type == EvalTypes.typeType && L.concreteTypes.length == 1) {
    // Static method
    staticType = L.concreteTypes[0];
    _dec = resolveStaticMethod(ctx, staticType, e.methodName.name);
    isStatic = true;
  } else {
    _dec = resolveInstanceMethod(ctx, L.type, e.methodName.name);
    isStatic = false;
  }

  Pair<List<Variable>, Map<String, Variable>> argsPair;

  if (_dec.isBridge) {
    final br = _dec.bridge!;
    final fd = br is BridgeMethodDef ? br.functionDescriptor : (br as BridgeConstructorDef).functionDescriptor;
    argsPair = compileArgumentListWithBridge(ctx, e.argumentList, fd, before: []);
  } else {
    final dec = _dec.declaration!;
    final fpl = dec.parameters?.parameters ?? <FormalParameter>[];

    argsPair = compileArgumentList(ctx, e.argumentList, (isStatic ? staticType! : L.type).file, fpl, dec,
        before: [if (!isStatic) L]);
  }

  final _args = argsPair.first;
  final _namedArgs = argsPair.second;

  final _argTypes = _args.map((e) => e.type).toList();
  final _namedArgTypes = _namedArgs.map((key, value) => MapEntry(key, value.type));

  if (isStatic) {
    if (_dec.isBridge) {
      final ix = InvokeExternal.make(
          ctx.bridgeStaticFunctionIndices[staticType!.file]!['${staticType.name}.${e.methodName.name}']!);
      ctx.pushOp(ix, InvokeExternal.LEN);
    } else {
      final offset = DeferredOrOffset.lookupStatic(ctx, staticType!.file, staticType.name, e.methodName.name);
      final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.LEN);
      if (offset.offset == null) {
        ctx.offsetTracker.setOffset(loc, offset);
      }
    }
  } else {
    final op = InvokeDynamic.make(L.scopeFrameOffset, e.methodName.name);
    ctx.pushOp(op, InvokeDynamic.len(op));
  }

  mReturnType = AlwaysReturnType.fromInstanceMethodOrBuiltin(
      ctx, isStatic ? staticType! : L.type, e.methodName.name, _argTypes, _namedArgTypes,
      $static: isStatic);

  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

  final v = Variable.alloc(ctx, mReturnType?.type?.copyWith(boxed: true) ?? EvalTypes.dynamicType);

  return v;
}

DeclarationOrBridge<MethodDeclaration, BridgeMethodDef> resolveInstanceMethod(
    CompilerContext ctx, TypeRef instanceType, String methodName) {
  final _dec = ctx.topLevelDeclarationsMap[instanceType.file]![instanceType.name]!;
  if (_dec.isBridge) {
    // Bridge
    final bridge = _dec.bridge! as BridgeClassDef;
    return DeclarationOrBridge(instanceType.file, bridge: bridge.methods[methodName]!);
  }

  final dec = ctx.instanceDeclarationsMap[instanceType.file]![instanceType.name]![methodName];

  if (dec != null) {
    return DeclarationOrBridge(instanceType.file, declaration: dec as MethodDeclaration);
  } else {
    final $class = _dec.declaration as ClassDeclaration;
    if ($class.extendsClause == null) {
      throw CompileError('Cannot resolve instance method');
    }
    // ignore: deprecated_member_use
    final $supertype = ctx.visibleTypes[instanceType.file]![$class.extendsClause!.superclass2.name.name]!;
    return resolveInstanceMethod(ctx, $supertype, methodName);
  }
}

DeclarationOrBridge<MethodDeclaration, BridgeDeclaration> resolveStaticMethod(
    CompilerContext ctx, TypeRef classType, String methodName) {
  final method = ctx.topLevelDeclarationsMap[classType.file]![classType.name + '.' + methodName];
  if (method != null) {
    if (method.declaration != null) {
      return DeclarationOrBridge(classType.file, declaration: method.declaration! as MethodDeclaration);
    } else {
      return DeclarationOrBridge(classType.file, bridge: method.bridge! as BridgeMethodDef);
    }
  }

  final cls = ctx.topLevelDeclarationsMap[classType.file]![classType.name];

  if (cls?.isBridge ?? false) {
    final bridge = cls!.bridge!;
    if (bridge is BridgeClassDef) {
      return DeclarationOrBridge(classType.file, bridge: bridge.constructors[methodName]!);
    }
  }

  throw UnimplementedError();
}
