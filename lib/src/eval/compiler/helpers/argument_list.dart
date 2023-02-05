import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';

import '../../../../dart_eval_bridge.dart';
import '../builtins.dart';
import '../context.dart';
import '../errors.dart';
import '../type.dart';
import '../util.dart';
import '../variable.dart';

Pair<List<Variable>, Map<String, Variable>> compileArgumentList(CompilerContext ctx, ArgumentList argumentList,
    int decLibrary, List<FormalParameter> fpl, Declaration parameterHost,
    {List<Variable> before = const [], List<String> superParams = const [], AstNode? source}) {
  final _args = <Variable>[];
  final _push = <Variable>[];
  final _namedArgs = <String, Variable>{};

  final positional = <FormalParameter>[];
  final named = <String, FormalParameter>{};
  final namedExpr = <String, Expression>{};

  for (final param in fpl) {
    if (param.isNamed) {
      named[param.name!.value() as String] = param;
    } else {
      positional.add(param);
    }
  }

  var i = 0;
  Variable? $null;

  for (final param in positional) {
    // First check super params. Super params do not contain an expression.
    if (superParams.contains(param.name!.value() as String)) {
      final V = ctx.lookupLocal(param.name!.value() as String)!;
      _push.add(V);
      _args.add(V);
      i++;
      continue;
    }
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
      } else if (param is SuperFormalParameter) {
        paramType = resolveSuperFormalType(ctx, decLibrary, param, parameterHost);
      } else {
        throw CompileError('Unknown formal type ${param.runtimeType}');
      }

      var _arg = compileExpression(arg, ctx, paramType);
      if (parameterHost is MethodDeclaration || !_arg.type.isUnboxedAcrossFunctionBoundaries) {
        _arg = _arg.boxIfNeeded(ctx);
      } else if (_arg.type.isUnboxedAcrossFunctionBoundaries) {
        _arg = _arg.unboxIfNeeded(ctx);
      }

      if (_arg.type == EvalTypes.functionType && _arg.scopeFrameOffset == -1) {
        _arg = _arg.tearOff(ctx);
      }

      if (!_arg.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError(
            'Cannot assign argument of type ${_arg.type.toStringClear(ctx, paramType)} '
            'to parameter "${param.name!.value() as String}" of type ${paramType.toStringClear(ctx, _arg.type)}',
            source ?? parameterHost);
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
    if (superParams.contains(name)) {
      final V = ctx.lookupLocal(name)!;
      _push.add(V);
      _namedArgs[name] = V;
      return;
    }
    final param = (_param is DefaultFormalParameter ? _param.parameter : _param) as NormalFormalParameter;
    var paramType = EvalTypes.dynamicType;
    if (param is SimpleFormalParameter) {
      if (param.type != null) {
        paramType = TypeRef.fromAnnotation(ctx, decLibrary, param.type!);
      }
    } else if (param is FieldFormalParameter) {
      paramType = _resolveFieldFormalType(ctx, decLibrary, param, parameterHost);
    } else if (param is SuperFormalParameter) {
      paramType = resolveSuperFormalType(ctx, decLibrary, param, parameterHost);
    } else {
      throw CompileError('Unknown formal type ${param.runtimeType}');
    }
    if (namedExpr.containsKey(name)) {
      var _arg = compileExpression(namedExpr[name]!, ctx, paramType);
      if (parameterHost is MethodDeclaration || !_arg.type.isUnboxedAcrossFunctionBoundaries) {
        _arg = _arg.boxIfNeeded(ctx);
      } else if (_arg.type.isUnboxedAcrossFunctionBoundaries) {
        _arg = _arg.unboxIfNeeded(ctx);
      }

      if (_arg.type == EvalTypes.functionType && _arg.scopeFrameOffset == -1) {
        _arg = _arg.tearOff(ctx);
      }

      if (!_arg.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError('Cannot assign argument of type ${_arg.type.toStringClear(ctx, paramType)}'
            ' to parameter "${param.name!.value() as String}" of type ${paramType.toStringClear(ctx, _arg.type)}');
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

Pair<List<Variable>, Map<String, Variable>> compileArgumentListWithKnownMethodArgs(CompilerContext ctx,
    ArgumentList argumentList, List<KnownMethodArg> params, Map<String, KnownMethodArg> namedParams,
    {List<Variable> before = const []}) {
  final _args = <Variable>[];
  final _push = <Variable>[];
  final _namedArgs = <String, Variable>{};
  final namedExpr = <String, Expression>{};

  var i = 0;
  Variable? $null;

  for (final param in params) {
    if (param.optional && argumentList.arguments.length <= i) {
      break;
    }
    final arg = argumentList.arguments[i];
    if (arg is NamedExpression) {
      if (!param.optional) {
        throw CompileError('Not enough positional arguments');
      } else {
        $null ??= BuiltinValue().push(ctx);
        _push.add($null);
      }
    } else {
      var paramType = param.type ?? EvalTypes.dynamicType;

      var _arg = compileExpression(arg, ctx, paramType);
      _arg = _arg.boxIfNeeded(ctx);

      if (_arg.type == EvalTypes.functionType && _arg.scopeFrameOffset == -1) {
        _arg = _arg.tearOff(ctx);
      }

      if (!_arg.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError('Cannot assign argument of type ${_arg.type} to parameter of type $paramType', argumentList);
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

  for (final param in namedParams.values) {
    var paramType = param.type ?? EvalTypes.dynamicType;
    if (namedExpr.containsKey(param.name)) {
      final _arg = compileExpression(namedExpr[param.name]!, ctx, paramType).boxIfNeeded(ctx);
      if (!_arg.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError('Cannot assign argument of type ${_arg.type} to parameter of type $paramType');
      }
      _push.add(_arg);
      _namedArgs[param.name] = _arg;
    } else {
      $null ??= BuiltinValue().push(ctx);
      _push.add($null);
    }
  }

  for (final _arg in [...before, ..._push]) {
    final argOp = PushArg.make(_arg.scopeFrameOffset);
    ctx.pushOp(argOp, PushArg.LEN);
  }

  return Pair(_args, _namedArgs);
}

Pair<List<Variable>, Map<String, Variable>> compileArgumentListWithBridge(
    CompilerContext ctx, ArgumentList argumentList, BridgeFunctionDef function,
    {List<Variable> before = const [], List<String> superParams = const []}) {
  final _args = <Variable>[];
  final _push = <Variable>[];
  final _namedArgs = <String, Variable>{};
  final namedExpr = <String, Expression>{};

  var i = 0;
  Variable? $null;

  for (final param in function.params) {
    if (superParams.contains(param.name)) {
      final V = ctx.lookupLocal(param.name)!;
      _push.add(V);
      _args.add(V);
      i++;
      continue;
    }
    if (param.optional && argumentList.arguments.length <= i) {
      $null ??= BuiltinValue().push(ctx);
      _push.add($null);
      break;
    }
    final arg = argumentList.arguments[i];
    if (arg is NamedExpression) {
      if (!param.optional) {
        throw CompileError('Not enough positional arguments');
      } else {
        $null ??= BuiltinValue().push(ctx);
        _push.add($null);
      }
    } else {
      var paramType = TypeRef.fromBridgeAnnotation(ctx, param.type);

      var _arg = compileExpression(arg, ctx, paramType);
      _arg = _arg.boxIfNeeded(ctx);
      if (_arg.type == EvalTypes.functionType && _arg.scopeFrameOffset == -1) {
        _arg = _arg.tearOff(ctx);
      }
      if (!(param.type.nullable && _arg.type == EvalTypes.nullType) &&
          !_arg.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError('Cannot assign argument of type ${_arg.type} to parameter of type $paramType', argumentList);
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

  for (final param in function.namedParams) {
    if (superParams.contains(param.name)) {
      final V = ctx.lookupLocal(param.name)!;
      _push.add(V);
      _namedArgs[param.name] = V;
    }
    var paramType = TypeRef.fromBridgeAnnotation(ctx, param.type);
    if (namedExpr.containsKey(param.name)) {
      var _arg = compileExpression(namedExpr[param.name]!, ctx, paramType).boxIfNeeded(ctx);
      if (_arg.type == EvalTypes.functionType && _arg.scopeFrameOffset == -1) {
        _arg = _arg.tearOff(ctx);
      }
      if (!_arg.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError('Cannot assign argument of type ${_arg.type} to parameter of type $paramType');
      }
      _push.add(_arg);
      _namedArgs[param.name] = _arg;
    } else {
      $null ??= BuiltinValue().push(ctx);
      _push.add($null);
    }
  }

  for (final _arg in [...before, ..._push]) {
    final argOp = PushArg.make(_arg.scopeFrameOffset);
    ctx.pushOp(argOp, PushArg.LEN);
  }

  return Pair(_args, _namedArgs);
}

TypeRef _resolveFieldFormalType(
    CompilerContext ctx, int decLibrary, FieldFormalParameter param, Declaration parameterHost) {
  if (parameterHost is! ConstructorDeclaration) {
    throw CompileError('Field formals can only occur in constructors');
  }
  final $class = parameterHost.parent as ClassDeclaration;
  return TypeRef.lookupFieldType(
          ctx, TypeRef.lookupClassDeclaration(ctx, decLibrary, $class), param.name.value() as String,
          forFieldFormal: true) ??
      EvalTypes.dynamicType;
}

TypeRef resolveSuperFormalType(
    CompilerContext ctx, int decLibrary, SuperFormalParameter param, Declaration parameterHost) {
  if (parameterHost is! ConstructorDeclaration) {
    throw CompileError('Super formals can only occur in constructors');
  }
  var superConstructorName = '';
  final lastInit = parameterHost.initializers.isEmpty ? null : parameterHost.initializers.last;
  if (lastInit is SuperConstructorInvocation) {
    superConstructorName = lastInit.constructorName?.name ?? '';
  }
  final $class = parameterHost.parent as ClassDeclaration;
  final type = TypeRef.lookupClassDeclaration(ctx, decLibrary, $class);
  final $super = type.resolveTypeChain(ctx).extendsType ??
      (throw CompileError('Class $type has no super class, so cannot use super formals', param));
  final superCstr = ctx.topLevelDeclarationsMap[$super.file]!['${$super.name}.$superConstructorName']!;
  if (superCstr.isBridge) {
    final fd = (superCstr.bridge as BridgeConstructorDef).functionDescriptor;
    for (final _param in (param.isNamed ? fd.namedParams : fd.params)) {
      if (_param.name == param.name.value() as String) {
        return TypeRef.fromBridgeAnnotation(ctx, _param.type);
      }
    }
  } else {
    final cstr = superCstr.declaration as ConstructorDeclaration;
    for (final _param in cstr.parameters.parameters) {
      if (_param is SimpleFormalParameter && _param.name!.stringValue == param.name.stringValue) {
        final _type = _param.type;
        if (_type == null) {
          return EvalTypes.dynamicType;
        }
        return TypeRef.fromAnnotation(ctx, $super.file, _type);
      } else if (_param is FieldFormalParameter) {
        return _resolveFieldFormalType(ctx, decLibrary, _param, cstr);
      } else if (_param is SuperFormalParameter) {
        return resolveSuperFormalType(ctx, decLibrary, _param, cstr);
      }
    }
  }

  throw CompileError('Could not find parameter ${param.name.value()} in the referenced superclass constructor', param);
}
