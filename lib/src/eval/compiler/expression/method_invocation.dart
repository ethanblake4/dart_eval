import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/bridge/declaration/class.dart';
import 'package:dart_eval/src/eval/bridge/declaration/function.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/funcexpr_invocation.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
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
    final DeclarationOrBridge<MethodDeclaration, BridgeDeclaration> _dec;
    final bool isStatic;
    TypeRef? staticType;
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

    int? offset;
    if (_dec.isBridge) {
      final br = _dec.bridge!;
      final fd = br is BridgeMethodDeclaration
          ? br.functionDescriptor
          : (br as BridgeConstructorDeclaration).functionDescriptor;
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
  } else {
    //final methodRef = compileIdentifierAsReference(e.methodName, ctx);
    final method = compileIdentifier(e.methodName, ctx);

    if (method.methodOffset == null) {
      throw CompileError('Cannot call ${e.methodName.name} as it is not a valid method');
    }

    if (method.callingConvention == CallingConvention.dynamic) {
      return invokeClosure(ctx, null, method, e.argumentList);
    }

    final offset = method.methodOffset!;
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
      final fnDescriptor = bridge is BridgeClassDeclaration
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
      if (bridge is BridgeClassDeclaration) {
        final type = TypeRef.fromBridgeTypeReference(ctx, bridge.type);

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
      mReturnType?.type?.copyWith(boxed: L != null || !unboxedAcrossFunctionBoundaries.contains(mReturnType.type)) ??
          EvalTypes.dynamicType);

  return v;
}

DeclarationOrBridge<MethodDeclaration, BridgeMethodDeclaration> resolveInstanceMethod(
    CompilerContext ctx, TypeRef instanceType, String methodName) {
  final _dec = ctx.topLevelDeclarationsMap[instanceType.file]![instanceType.name]!;
  if (_dec.isBridge) {
    // Bridge
    final bridge = _dec.bridge! as BridgeClassDeclaration;
    return DeclarationOrBridge(bridge: bridge.methods[methodName]!);
  }

  final dec = ctx.instanceDeclarationsMap[instanceType.file]![instanceType.name]![methodName];

  if (dec != null) {
    return DeclarationOrBridge(declaration: dec as MethodDeclaration);
  } else {
    final $class = ctx.topLevelDeclarationsMap[instanceType.file]![instanceType.name] as ClassDeclaration;
    if ($class.extendsClause == null) {
      throw CompileError('Cannot resolve instance method');
    }
    final $supertype = ctx.visibleTypes[instanceType.file]![$class.extendsClause!.superclass2.name.name]!;
    return resolveInstanceMethod(ctx, $supertype, methodName);
  }
}

DeclarationOrBridge<MethodDeclaration, BridgeDeclaration> resolveStaticMethod(
    CompilerContext ctx, TypeRef classType, String methodName) {
  final method = ctx.topLevelDeclarationsMap[classType.file]![classType.name + '.' + methodName];
  if (method != null) {
    if (method.declaration != null) {
      return DeclarationOrBridge(declaration: method.declaration! as MethodDeclaration);
    } else {
      return DeclarationOrBridge(bridge: method.bridge! as BridgeMethodDeclaration);
    }
  }

  final cls = ctx.topLevelDeclarationsMap[classType.file]![classType.name];

  if (cls?.isBridge ?? false) {
    final bridge = cls!.bridge!;
    if (bridge is BridgeClassDeclaration) {
      return DeclarationOrBridge(bridge: bridge.constructors[methodName]!);
    }
  }

  throw UnimplementedError();
}

Pair<List<Variable>, Map<String, Variable>> compileArgumentList(CompilerContext ctx, ArgumentList argumentList,
    int decLibrary, List<FormalParameter> fpl, Declaration parameterHost,
    {List<Variable> before = const []}) {
  final _args = <Variable>[];
  final _push = <Variable>[];
  final _namedArgs = <String, Variable>{};

  final positional = <FormalParameter>[];
  final named = <String, FormalParameter>{};
  final namedExpr = <String, Expression>{};

  for (final param in fpl) {
    if (param.isNamed) {
      named[param.identifier!.name] = param;
    } else {
      positional.add(param);
    }
  }

  var i = 0;
  Variable? $null;

  for (final param in positional) {
    final arg = argumentList.arguments[i];
    if (arg is NamedExpression) {
      if (param.isRequired) {
        throw CompileError('Not enough positional arguments');
      } else {
        $null ??= BuiltinValue().push(ctx);
        _push.add($null);
      }
    } else {
      var paramType = EvalTypes.dynamicType;
      if (param is SimpleFormalParameter) {
        if (param.type != null) {
          paramType = TypeRef.fromAnnotation(ctx, decLibrary, param.type!);
        }
      } else if (param is FieldFormalParameter) {
        paramType = _resolveFieldFormalType(ctx, decLibrary, param, parameterHost);
      } else {
        throw CompileError('Unknown formal type ${param.runtimeType}');
      }

      var _arg = compileExpression(arg, ctx);
      if (parameterHost is MethodDeclaration) {
        _arg = _arg.boxIfNeeded(ctx);
      }

      if (!_arg.type.resolveTypeChain(ctx).isAssignableTo(paramType)) {
        throw CompileError(
            'Cannot assign argument of type ${_arg.type} to parameter "${param.identifier}" of type $paramType');
      }

      _args.add(_arg);
      _push.add(_arg);
    }

    i++;
  }

  for (final arg in argumentList.arguments) {
    if (arg is NamedExpression) {
      namedExpr[arg.name.label.name] = arg.expression;
    }
  }

  named.forEach((name, _param) {
    final param = (_param is DefaultFormalParameter ? _param.parameter : _param) as NormalFormalParameter;
    var paramType = EvalTypes.dynamicType;
    if (param is SimpleFormalParameter) {
      if (param.type != null) {
        paramType = TypeRef.fromAnnotation(ctx, decLibrary, param.type!);
      }
    } else if (param is FieldFormalParameter) {
      paramType = _resolveFieldFormalType(ctx, decLibrary, param, parameterHost);
    } else {
      throw CompileError('Unknown formal type ${param.runtimeType}');
    }
    if (namedExpr.containsKey(name)) {
      var _arg = compileExpression(namedExpr[name]!, ctx);
      if (parameterHost is MethodDeclaration) {
        _arg = _arg.boxIfNeeded(ctx);
      }
      if (!_arg.type.resolveTypeChain(ctx).isAssignableTo(paramType)) {
        throw CompileError(
            'Cannot assign argument of type ${_arg.type} to parameter "${param.identifier}" of type $paramType');
      }

      _push.add(_arg);

      _namedArgs[name] = _arg;
    } else {
      $null ??= BuiltinValue().push(ctx);
      _push.add($null!);
    }
  });

  for (final _arg in <Variable>[...before, ..._push]) {
    final argOp = PushArg.make(_arg.scopeFrameOffset);
    ctx.pushOp(argOp, PushArg.LEN);
  }

  return Pair(_args, _namedArgs);
}

Pair<List<Variable>, Map<String, Variable>> compileArgumentListWithBridge(
    CompilerContext ctx, ArgumentList argumentList, BridgeFunctionDescriptor function,
    {List<Variable> before = const []}) {
  final _args = <Variable>[];
  final _push = <Variable>[];
  final _namedArgs = <String, Variable>{};
  final namedExpr = <String, Expression>{};

  var i = 0;
  Variable? $null;

  for (final param in function.positionalParams) {
    final arg = argumentList.arguments[i];
    if (arg is NamedExpression) {
      if (!param.optional) {
        throw CompileError('Not enough positional arguments');
      } else {
        $null ??= BuiltinValue().push(ctx);
        _push.add($null);
      }
    } else {
      var paramType = TypeRef.fromBridgeAnnotation(ctx, param.typeAnnotation);

      var _arg = compileExpression(arg, ctx);
      _arg = _arg.boxIfNeeded(ctx);
      if (!_arg.type.resolveTypeChain(ctx).isAssignableTo(paramType)) {
        throw CompileError('Cannot assign argument of type ${_arg.type} to parameter of type $paramType');
      }
      _args.add(_arg);
      _push.add(_arg);
    }

    i++;
  }

  for (final arg in argumentList.arguments) {
    if (arg is NamedExpression) {
      namedExpr[arg.name.label.name] = arg.expression;
    }
  }

  function.namedParams.forEach((name, param) {
    var paramType = TypeRef.fromBridgeAnnotation(ctx, param.typeAnnotation);
    if (namedExpr.containsKey(name)) {
      final _arg = compileExpression(namedExpr[name]!, ctx).boxIfNeeded(ctx);
      if (!_arg.type.resolveTypeChain(ctx).isAssignableTo(paramType)) {
        throw CompileError('Cannot assign argument of type ${_arg.type} to parameter of type $paramType');
      }
      _push.add(_arg);
      _namedArgs[name] = _arg;
    } else {
      $null ??= BuiltinValue().push(ctx);
      _push.add($null!);
    }
  });

  for (final _arg in [...before, ..._push]) {
    final argOp = PushArg.make(_arg.scopeFrameOffset);
    ctx.pushOp(argOp, PushArg.LEN);
  }

  return Pair(_args, _namedArgs);
}

TypeRef _resolveFieldFormalType(
    CompilerContext ctx, int decLibrary, FieldFormalParameter param, Declaration parameterHost) {
  if (!(parameterHost is ConstructorDeclaration)) {
    throw CompileError('Field formals can only occur in constructors');
  }
  final $class = parameterHost.parent as ClassDeclaration;
  final field = ctx.instanceDeclarationsMap[decLibrary]![$class.name.name]![param.identifier.name]!;
  if (!(field is VariableDeclaration)) {
    throw CompileError('Resolved field is not a FieldDeclaration');
  }
  final vdl = field.parent as VariableDeclarationList;
  if (vdl.type != null) {
    return TypeRef.fromAnnotation(ctx, decLibrary, vdl.type!);
  }
  return EvalTypes.dynamicType;
}
