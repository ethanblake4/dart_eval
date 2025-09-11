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

Pair<List<Variable>, Map<String, Variable>> compileArgumentList(
    CompilerContext ctx,
    ArgumentList argumentList,
    int decLibrary,
    List<FormalParameter> fpl,
    Declaration parameterHost,
    {List<Variable> before = const [],
    Map<String, TypeRef> resolveGenerics = const {},
    List<String> superParams = const [],
    AstNode? source}) {
  final args = <Variable>[];
  final push = <Variable>[];
  final namedArgs = <String, Variable>{};

  final positional = <FormalParameter>[];
  final named = <String, FormalParameter>{};
  final namedExpr = <String, Expression>{};

  for (final param in fpl) {
    if (param.isNamed) {
      named[param.name!.lexeme] = param;
    } else {
      positional.add(param);
    }
  }

  var i = 0;
  Variable? $null;

  final resolveGenericsMap = <String, Set<TypeRef>>{};

  for (final param in positional) {
    // First check super params. Super params do not contain an expression.
    if (superParams.contains(param.name!.lexeme)) {
      final V = ctx.lookupLocal(param.name!.lexeme)!;
      push.add(V);
      args.add(V);
      i++;
      continue;
    }
    final arg =
        argumentList.arguments.length <= i ? null : argumentList.arguments[i];
    if (arg is NamedExpression) {
      if (param.isRequired) {
        throw CompileError('Not enough positional arguments');
      } else {
        $null ??= BuiltinValue().push(ctx);
        push.add($null);
      }
    } else if (arg == null) {
      if (param.isRequired) {
        throw CompileError('Not enough positional arguments');
      } else if (param is DefaultFormalParameter) {
        // Default parameter values are handled at the call site
        $null ??= BuiltinValue().push(ctx);
        push.add($null);
      } else {
        $null ??= BuiltinValue().push(ctx);
        push.add($null);
      }
    } else {
      var paramType = CoreTypes.dynamic.ref(ctx);
      TypeAnnotation? typeAnnotation;
      if (param is SimpleFormalParameter) {
        typeAnnotation = param.type;
      } else if (param is FieldFormalParameter) {
        paramType =
            _resolveFieldFormalType(ctx, decLibrary, param, parameterHost);
      } else if (param is SuperFormalParameter) {
        paramType =
            resolveSuperFormalType(ctx, decLibrary, param, parameterHost);
      } else if (param is DefaultFormalParameter) {
        final p = param.parameter;
        typeAnnotation = p is SimpleFormalParameter ? p.type : null;
      } else {
        throw CompileError('Unknown formal type ${param.runtimeType}');
      }

      if (typeAnnotation != null) {
        paramType = TypeRef.fromAnnotation(ctx, decLibrary, typeAnnotation);
      }

      var arg0 = compileExpression(arg, ctx, paramType);
      if (parameterHost is MethodDeclaration ||
          !paramType.isUnboxedAcrossFunctionBoundaries) {
        arg0 = arg0.boxIfNeeded(ctx);
      } else if (paramType.isUnboxedAcrossFunctionBoundaries) {
        arg0 = arg0.unboxIfNeeded(ctx);
      }

      if (arg0.type == CoreTypes.function.ref(ctx) &&
          arg0.scopeFrameOffset == -1) {
        arg0 = arg0.tearOff(ctx);
      }

      if (!arg0.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError(
            'Cannot assign argument of type ${arg0.type.toStringClear(ctx, paramType)} '
            'to parameter "${param.name!.lexeme}" of type ${paramType.toStringClear(ctx, arg0.type)}',
            source ?? parameterHost);
      }

      if (typeAnnotation != null) {
        final n = typeAnnotation is NamedType
            ? (typeAnnotation.name2.stringValue ?? typeAnnotation.name2.lexeme)
            : null;
        if (n != null && resolveGenerics.containsKey(n)) {
          resolveGenericsMap[n] ??= {};
          resolveGenericsMap[n]!.add(arg0.type);
        }
      }

      args.add(arg0);
      push.add(arg0);
    }

    i++;
  }

  for (final arg in argumentList.arguments) {
    if (arg is NamedExpression) {
      namedExpr[arg.name.label.name] = arg.expression;
    }
  }

  for (final n in named.entries) {
    final name = n.key;
    final param0 = n.value;
    if (superParams.contains(name)) {
      final V = ctx.lookupLocal(name)!;
      push.add(V);
      namedArgs[name] = V;
      continue;
    }
    final param = (param0 is DefaultFormalParameter ? param0.parameter : param0)
        as NormalFormalParameter;
    var paramType = CoreTypes.dynamic.ref(ctx);
    TypeAnnotation? typeAnnotation;
    if (param is SimpleFormalParameter) {
      typeAnnotation = param.type;
      if (typeAnnotation != null) {
        paramType = TypeRef.fromAnnotation(ctx, decLibrary, typeAnnotation);
      }
    } else if (param is FieldFormalParameter) {
      paramType =
          _resolveFieldFormalType(ctx, decLibrary, param, parameterHost);
    } else if (param is SuperFormalParameter) {
      paramType = resolveSuperFormalType(ctx, decLibrary, param, parameterHost);
    } else {
      throw CompileError('Unknown formal type ${param.runtimeType}');
    }

    if (namedExpr.containsKey(name)) {
      var arg0 = compileExpression(namedExpr[name]!, ctx, paramType);
      if (parameterHost is MethodDeclaration ||
          !paramType.isUnboxedAcrossFunctionBoundaries) {
        arg0 = arg0.boxIfNeeded(ctx);
      } else if (paramType.isUnboxedAcrossFunctionBoundaries) {
        arg0 = arg0.unboxIfNeeded(ctx);
      }

      if (arg0.type == CoreTypes.function.ref(ctx) &&
          arg0.scopeFrameOffset == -1) {
        arg0 = arg0.tearOff(ctx);
      }

      if (!arg0.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError(
            'Cannot assign argument of type ${arg0.type.toStringClear(ctx, paramType)}'
            ' to parameter "${param.name!.lexeme}" of type ${paramType.toStringClear(ctx, arg0.type)}',
            source ?? parameterHost);
      }

      if (typeAnnotation != null) {
        final n = typeAnnotation is NamedType
            ? (typeAnnotation.name2.stringValue ?? typeAnnotation.name2.lexeme)
            : null;
        if (n != null && resolveGenerics.containsKey(n)) {
          resolveGenericsMap[n] ??= {};
          resolveGenericsMap[n]!.add(arg0.type);
        }
      }

      push.add(arg0);
      namedArgs[name] = arg0;
    } else {
      $null ??= BuiltinValue().push(ctx);
      push.add($null);
    }
  }

  for (final generic in resolveGenericsMap.keys) {
    resolveGenerics[generic] =
        TypeRef.commonBaseType(ctx, resolveGenericsMap[generic]!);
  }

  for (final restArg in <Variable>[...before, ...push]) {
    final argOp = PushArg.make(restArg.scopeFrameOffset);
    ctx.pushOp(argOp, PushArg.LEN);
  }

  return Pair(args, namedArgs);
}

Pair<List<Variable>, Map<String, Variable>> compileSuperParams(
    CompilerContext ctx, List<FormalParameter> fpl, Declaration parameterHost,
    {List<Variable> before = const [],
    List<String> superParams = const [],
    AstNode? source}) {
  final args = <Variable>[];
  final push = <Variable>[];
  final namedArgs = <String, Variable>{};

  final positional = <FormalParameter>[];
  final named = <String, FormalParameter>{};

  for (final param in fpl) {
    if (param.isNamed) {
      named[param.name!.lexeme] = param;
    } else {
      positional.add(param);
    }
  }

  Variable? $null;

  for (final param in positional) {
    // First check super params. Super params do not contain an expression.
    if (superParams.contains(param.name!.lexeme)) {
      final V = ctx.lookupLocal(param.name!.lexeme)!;
      push.add(V);
      args.add(V);
    } else {
      if (param.isRequired) {
        throw CompileError('Not enough positional arguments');
      } else {
        $null ??= BuiltinValue().push(ctx);
        push.add($null);
      }
    }
  }

  for (final n in named.entries) {
    final name = n.key;
    if (superParams.contains(name)) {
      final V = ctx.lookupLocal(name)!;
      push.add(V);
      namedArgs[name] = V;
    } else {
      $null ??= BuiltinValue().push(ctx);
      push.add($null);
    }
  }

  for (final restArg in <Variable>[...before, ...push]) {
    final argOp = PushArg.make(restArg.scopeFrameOffset);
    ctx.pushOp(argOp, PushArg.LEN);
  }

  return Pair(args, namedArgs);
}

Pair<List<Variable>, Map<String, Variable>> compileSuperParamsWithBridge(
    CompilerContext ctx, BridgeFunctionDef function,
    {List<Variable> before = const [], List<String> superParams = const []}) {
  final args = <Variable>[];
  final push = <Variable>[];
  final namedArgs = <String, Variable>{};

  Variable? $null;

  for (final param in function.params) {
    // First check super params. Super params do not contain an expression.
    if (superParams.contains(param.name)) {
      final V = ctx.lookupLocal(param.name)!;
      push.add(V);
      args.add(V);
    } else {
      if (param.optional) {
        $null ??= BuiltinValue().push(ctx);
        push.add($null);
      } else {
        throw CompileError('Not enough positional arguments');
      }
    }
  }

  for (final param in function.namedParams) {
    if (superParams.contains(param.name)) {
      final V = ctx.lookupLocal(param.name)!;
      push.add(V);
      namedArgs[param.name] = V;
    } else {
      $null ??= BuiltinValue().push(ctx);
      push.add($null);
    }
  }

  for (final restArg in <Variable>[...before, ...push]) {
    final argOp = PushArg.make(restArg.scopeFrameOffset);
    ctx.pushOp(argOp, PushArg.LEN);
  }

  return Pair(args, namedArgs);
}

/// Best effort method to compile an argument list against a dynamic target.
/// This will not always work, but it's better than nothing for simple cases.
Pair<List<Variable>, Map<String, Variable>> compileArgumentListWithDynamic(
    CompilerContext ctx, ArgumentList argumentList,
    {List<Variable> before = const [],
    Map<String, TypeRef> resolveGenerics = const {},
    AstNode? source}) {
  final args = <Variable>[];
  final push = <Variable>[];
  final namedArgs = <String, Variable>{};

  for (var i = 0; i < argumentList.arguments.length; i++) {
    final arg = argumentList.arguments[i];

    if (arg is NamedExpression) {
      throw CompileError(
          'dart_eval does not support passing named arguments '
          'to dynamic targets.',
          source ?? argumentList);
    }

    var arg0 = compileExpression(arg, ctx);
    if (arg0.type.isUnboxedAcrossFunctionBoundaries) {
      arg0 = arg0.boxIfNeeded(ctx);
    } else {
      arg0 = arg0.unboxIfNeeded(ctx);
    }

    if (arg0.type == CoreTypes.function.ref(ctx) &&
        arg0.scopeFrameOffset == -1) {
      arg0 = arg0.tearOff(ctx);
    }

    args.add(arg0);
    push.add(arg0);
  }

  for (final restArg in <Variable>[...before, ...push]) {
    final argOp = PushArg.make(restArg.scopeFrameOffset);
    ctx.pushOp(argOp, PushArg.LEN);
  }

  return Pair(args, namedArgs);
}

Pair<List<Variable>, Map<String, Variable>>
    compileArgumentListWithKnownMethodArgs(
        CompilerContext ctx,
        ArgumentList argumentList,
        List<KnownMethodArg> params,
        Map<String, KnownMethodArg> namedParams,
        {List<Variable> before = const [],
        AstNode? source}) {
  final args = <Variable>[];
  final push = <Variable>[];
  final namedArgs = <String, Variable>{};
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
        push.add($null);
      }
    } else {
      var paramType = param.type ?? CoreTypes.dynamic.ref(ctx);

      var arg0 = compileExpression(arg, ctx, paramType);
      arg0 = arg0.boxIfNeeded(ctx);

      if (arg0.type == CoreTypes.function.ref(ctx) &&
          arg0.scopeFrameOffset == -1) {
        arg0 = arg0.tearOff(ctx);
      }

      if (!arg0.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError(
            'Cannot assign argument of type ${arg0.type} to parameter of type $paramType',
            argumentList);
      }
      args.add(arg0);
      push.add(arg0);
    }

    i++;
  }

  for (final arg in argumentList.arguments) {
    if (arg is NamedExpression) {
      namedExpr[arg.name.label.name] = arg.expression;
    }
  }

  for (final param in namedParams.values) {
    var paramType = param.type ?? CoreTypes.dynamic.ref(ctx);
    if (namedExpr.containsKey(param.name)) {
      final arg0 = compileExpression(namedExpr[param.name]!, ctx, paramType)
          .boxIfNeeded(ctx);
      if (!arg0.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError(
            'Cannot assign argument of type ${arg0.type} to parameter of type $paramType',
            source);
      }
      push.add(arg0);
      namedArgs[param.name] = arg0;
    } else {
      $null ??= BuiltinValue().push(ctx);
      push.add($null);
    }
  }

  for (final restArg in [...before, ...push]) {
    final argOp = PushArg.make(restArg.scopeFrameOffset);
    ctx.pushOp(argOp, PushArg.LEN);
  }

  return Pair(args, namedArgs);
}

Pair<List<Variable>, Map<String, Variable>> compileArgumentListWithBridge(
    CompilerContext ctx, ArgumentList argumentList, BridgeFunctionDef function,
    {List<Variable> before = const [], List<String> superParams = const []}) {
  final args = <Variable>[];
  final push = <Variable>[];
  final namedArgs = <String, Variable>{};
  final namedExpr = <String, Expression>{};

  var i = 0;
  Variable? $null;

  for (final param in function.params) {
    if (superParams.contains(param.name)) {
      final V = ctx.lookupLocal(param.name)!;
      push.add(V);
      args.add(V);
      i++;
      continue;
    }
    if (param.optional && argumentList.arguments.length <= i) {
      $null ??= BuiltinValue().push(ctx);
      push.add($null);
      continue;
    }
    final arg = argumentList.arguments[i];
    if (arg is NamedExpression) {
      if (!param.optional) {
        throw CompileError('Not enough positional arguments');
      } else {
        $null ??= BuiltinValue().push(ctx);
        push.add($null);
      }
    } else {
      var paramType = TypeRef.fromBridgeAnnotation(ctx, param.type);

      var arg0 = compileExpression(arg, ctx, paramType);
      arg0 = arg0.boxIfNeeded(ctx);
      if (arg0.type == CoreTypes.function.ref(ctx) &&
          arg0.scopeFrameOffset == -1) {
        arg0 = arg0.tearOff(ctx);
      }
      if (!(param.type.nullable && arg0.type == CoreTypes.nullType.ref(ctx)) &&
          !arg0.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError(
            'Cannot assign argument of type ${arg0.type} to parameter of type $paramType',
            argumentList);
      }
      args.add(arg0);
      push.add(arg0);
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
      push.add(V);
      namedArgs[param.name] = V;
    }
    var paramType = TypeRef.fromBridgeAnnotation(ctx, param.type);
    if (namedExpr.containsKey(param.name)) {
      var arg0 = compileExpression(namedExpr[param.name]!, ctx, paramType)
          .boxIfNeeded(ctx);
      if (arg0.type == CoreTypes.function.ref(ctx) &&
          arg0.scopeFrameOffset == -1) {
        arg0 = arg0.tearOff(ctx);
      }
      if (!arg0.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError(
            'Cannot assign argument of type ${arg0.type} to parameter of type $paramType',
            argumentList);
      }
      push.add(arg0);
      namedArgs[param.name] = arg0;
    } else {
      $null ??= BuiltinValue().push(ctx);
      push.add($null);
    }
  }

  for (final restArg in [...before, ...push]) {
    final argOp = PushArg.make(restArg.scopeFrameOffset);
    ctx.pushOp(argOp, PushArg.LEN);
  }

  return Pair(args, namedArgs);
}

TypeRef _resolveFieldFormalType(CompilerContext ctx, int decLibrary,
    FieldFormalParameter param, Declaration parameterHost) {
  if (parameterHost is! ConstructorDeclaration) {
    throw CompileError('Field formals can only occur in constructors');
  }
  final $class = parameterHost.parent as NamedCompilationUnitMember;
  return TypeRef.lookupFieldType(ctx,
          TypeRef.lookupDeclaration(ctx, decLibrary, $class), param.name.lexeme,
          forFieldFormal: true, source: param) ??
      CoreTypes.dynamic.ref(ctx);
}

TypeRef resolveSuperFormalType(CompilerContext ctx, int decLibrary,
    SuperFormalParameter param, Declaration parameterHost) {
  if (parameterHost is! ConstructorDeclaration) {
    throw CompileError('Super formals can only occur in constructors');
  }
  var superConstructorName = '';
  final lastInit = parameterHost.initializers.isEmpty
      ? null
      : parameterHost.initializers.last;
  if (lastInit is SuperConstructorInvocation) {
    superConstructorName = lastInit.constructorName?.name ?? '';
  }
  final $class = parameterHost.parent as ClassDeclaration;
  final type = TypeRef.lookupDeclaration(ctx, decLibrary, $class);
  final $super = type.resolveTypeChain(ctx).extendsType ??
      (throw CompileError(
          'Class $type has no super class, so cannot use super formals',
          param));
  final superCstr = ctx.topLevelDeclarationsMap[$super.file]![
      '${$super.name}.$superConstructorName']!;
  if (superCstr.isBridge) {
    final fd = (superCstr.bridge as BridgeConstructorDef).functionDescriptor;
    for (final bridgeParam in (param.isNamed ? fd.namedParams : fd.params)) {
      if (bridgeParam.name == param.name.lexeme) {
        return TypeRef.fromBridgeAnnotation(ctx, bridgeParam.type);
      }
    }
  } else {
    final cstr = superCstr.declaration as ConstructorDeclaration;
    for (final cstrParam in cstr.parameters.parameters) {
      var param0 =
          cstrParam is DefaultFormalParameter ? cstrParam.parameter : cstrParam;
      if (param0.name?.lexeme != param.name.lexeme) {
        continue;
      }
      if (param0 is SimpleFormalParameter) {
        final type0 = param0.type;
        if (type0 == null) {
          return CoreTypes.dynamic.ref(ctx);
        }
        return TypeRef.fromAnnotation(ctx, $super.file, type0);
      } else if (param0 is FieldFormalParameter) {
        return _resolveFieldFormalType(ctx, decLibrary, param0, cstr);
      } else if (param0 is SuperFormalParameter) {
        return resolveSuperFormalType(ctx, decLibrary, param0, cstr);
      } else {
        throw CompileError(
            'Unknown parameter type ${param0.runtimeType}', param0);
      }
    }
  }

  throw CompileError(
      'Could not find parameter ${param.name.value()} in the referenced superclass constructor',
      param,
      decLibrary);
}
