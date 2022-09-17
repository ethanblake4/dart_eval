import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../../../../dart_eval_bridge.dart';
import '../builtins.dart';
import '../context.dart';
import '../errors.dart';
import '../type.dart';
import '../util.dart';
import '../variable.dart';

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
      named[param.name!.value() as String] = param;
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
      if (parameterHost is MethodDeclaration || !unboxedAcrossFunctionBoundaries.contains(_arg.type)) {
        _arg = _arg.boxIfNeeded(ctx);
      } else if (unboxedAcrossFunctionBoundaries.contains(_arg.type)) {
        _arg = _arg.unboxIfNeeded(ctx);
      }

      if (!_arg.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError(
            'Cannot assign argument of type ${_arg.type} to parameter "${param.name!.value() as String}" of type $paramType');
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
      if (parameterHost is MethodDeclaration || !unboxedAcrossFunctionBoundaries.contains(_arg.type)) {
        _arg = _arg.boxIfNeeded(ctx);
      } else if (unboxedAcrossFunctionBoundaries.contains(_arg.type)) {
        _arg = _arg.unboxIfNeeded(ctx);
      }
      if (!_arg.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError(
            'Cannot assign argument of type ${_arg.type} to parameter "${param.name!.value() as String}" of type $paramType');
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

      var _arg = compileExpression(arg, ctx);
      _arg = _arg.boxIfNeeded(ctx);
      if (!_arg.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
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

  for (final param in namedParams.values) {
    var paramType = param.type ?? EvalTypes.dynamicType;
    if (namedExpr.containsKey(param.name)) {
      final _arg = compileExpression(namedExpr[param.name]!, ctx).boxIfNeeded(ctx);
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
    {List<Variable> before = const []}) {
  final _args = <Variable>[];
  final _push = <Variable>[];
  final _namedArgs = <String, Variable>{};
  final namedExpr = <String, Expression>{};

  var i = 0;
  Variable? $null;

  for (final param in function.params) {
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
      var paramType = TypeRef.fromBridgeAnnotation(ctx, param.type);

      var _arg = compileExpression(arg, ctx);
      _arg = _arg.boxIfNeeded(ctx);
      if (!_arg.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
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

  for (final param in function.namedParams) {
    var paramType = TypeRef.fromBridgeAnnotation(ctx, param.type);
    if (namedExpr.containsKey(param.name)) {
      final _arg = compileExpression(namedExpr[param.name]!, ctx).boxIfNeeded(ctx);
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
  final field =
      ctx.instanceDeclarationsMap[decLibrary]![$class.name2.value() as String]![param.name.value() as String]!;
  if (field is! VariableDeclaration) {
    throw CompileError('Resolved field is not a FieldDeclaration');
  }
  final vdl = field.parent as VariableDeclarationList;
  if (vdl.type != null) {
    return TypeRef.fromAnnotation(ctx, decLibrary, vdl.type!);
  }
  return EvalTypes.dynamicType;
}
