import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'default_value.dart';

import '../../../../dart_eval_bridge.dart';
import '../builtins.dart';
import '../context.dart';
import '../errors.dart';
import '../type.dart';

import '../variable.dart';
import '../../ir/bridge.dart' show PrepareBridgeArgument;

Variable _providedBridgeArgument(CompilerContext ctx, Variable argument) {
  final type = argument.type;
  if (!type.nullable &&
      type != CoreTypes.nullType.ref(ctx) &&
      type != CoreTypes.dynamic.ref(ctx)) {
    return argument;
  }
  return Variable.ssa(
    ctx,
    PrepareBridgeArgument(ctx.svar('bridgeArgument'), argument.ssa),
    type,
  );
}

class ArgumentListResult {
  final List<SSA> ssa;
  final List<Variable> args;
  final Map<String, Variable> namedArgs;

  /// `ssa` contains the complete flattened argument vector — provided
  /// positionals padded with null placeholders for omitted parameters, then
  /// named arguments in declaration order — which is the wire format bridge
  /// members consume. `args` holds only the provided positional arguments.
  ArgumentListResult(this.ssa, this.args, this.namedArgs);
}

Variable _omittedArgument(
  CompilerContext ctx,
  int library,
  FormalParameter parameter,
  Declaration host,
) {
  if (parameter.isRequired) {
    throw CompileError(
      'Missing required argument ${parameter.name!.lexeme}',
      parameter,
    );
  }
  final (declaredType, _) = getFormalParameterType(
    ctx,
    parameter,
    library,
    host,
  );
  final type = declaredType ?? CoreTypes.dynamic.ref(ctx);
  // Scalar defaults push as native constants; anything else (tear-offs, const
  // objects) compiles the constant expression normally.
  final defaultExpr = parameter.defaultClause?.value;
  Object? value;
  var useExpression = false;
  if (defaultExpr == null) {
    value = null;
  } else {
    try {
      value = evaluateDefaultValue(ctx, library, defaultExpr);
    } on CompileError {
      useExpression = true;
    }
  }
  Variable variable;
  if (useExpression) {
    variable = compileExpression(defaultExpr!, ctx, type);
  } else {
    if (value is int &&
        type.file == dartCoreFile &&
        type.name == 'double') {
      value = value.toDouble();
    }
    variable = pushDefaultValue(ctx, value);
  }
  return host is MethodDeclaration || !type.isUnboxedAcrossFunctionBoundaries
      ? variable.boxIfNeeded(ctx)
      : variable.unboxIfNeeded(ctx);
}

ArgumentListResult compileArgumentList(
  CompilerContext ctx,
  ArgumentList argumentList,
  int decLibrary,
  List<FormalParameter> fpl,
  Declaration parameterHost, {
  List<Variable> before = const [],
  Map<String, TypeRef> resolveGenerics = const {},
  bool inferGenerics = true,
  List<String> superParams = const [],
  AstNode? source,
}) {
  final ssa = <SSA>[];
  final args = <Variable>[];
  final push = <Variable>[...before];
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
    final arg = argumentList.arguments.length <= i
        ? null
        : argumentList.arguments[i];
    if (arg is NamedArgument) {
      if (param.isRequired) {
        throw CompileError('Not enough positional arguments');
      } else {
        final value = _omittedArgument(ctx, decLibrary, param, parameterHost);
        push.add(value);
        args.add(value);
      }
    } else if (arg == null) {
      if (param.isRequired) {
        throw CompileError('Not enough positional arguments');
      } else {
        final value = _omittedArgument(ctx, decLibrary, param, parameterHost);
        push.add(value);
        args.add(value);
      }
    } else {
      var (paramType, typeAnnotation) = getFormalParameterType(
        ctx,
        param,
        decLibrary,
        parameterHost,
        typeParameters: resolveGenerics,
      );

      paramType ??= CoreTypes.dynamic.ref(ctx);
      final genericParameter =
          typeAnnotation is NamedType &&
          resolveGenerics.containsKey(typeAnnotation.name.lexeme);

      var arg0 = compileExpression(arg.argumentExpression, ctx, paramType);
      arg0 = convertForAssignment(
        ctx,
        arg0,
        paramType,
        representation:
            parameterHost is MethodDeclaration ||
                genericParameter ||
                !paramType.isUnboxedAcrossFunctionBoundaries
            ? MachineRepresentation.object
            : representationForType(paramType.copyWith(boxed: false)),
        source: source ?? parameterHost,
        description:
            'Cannot assign argument of type ${arg0.type.toStringClear(ctx, paramType)} '
            'to parameter "${param.name!.lexeme}" of type '
            '${paramType.toStringClear(ctx, arg0.type)}',
      );
      if (parameterHost is MethodDeclaration ||
          genericParameter ||
          !paramType.isUnboxedAcrossFunctionBoundaries) {
        arg0 = arg0.boxIfNeeded(ctx);
      } else if (paramType.isUnboxedAcrossFunctionBoundaries) {
        arg0 = arg0.unboxIfNeeded(ctx);
      }

      if (arg0.type == CoreTypes.function.ref(ctx) &&
          arg0.name == null &&
          arg0.methodOffset != null) {
        arg0 = arg0.tearOff(ctx);
      }

      if (typeAnnotation != null) {
        final n = typeAnnotation is NamedType
            ? (typeAnnotation.name.stringValue ?? typeAnnotation.name.lexeme)
            : null;
        if (inferGenerics && n != null && resolveGenerics.containsKey(n)) {
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
    if (arg is NamedArgument) {
      if (!named.containsKey(arg.name.lexeme)) {
        throw CompileError('Unknown named argument ${arg.name.lexeme}', arg);
      }
      namedExpr[arg.name.lexeme] = arg.argumentExpression;
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
    final param = param0;
    var paramType = CoreTypes.dynamic.ref(ctx);
    TypeAnnotation? typeAnnotation;
    if (param is RegularFormalParameter) {
      typeAnnotation = param.type;
      if (typeAnnotation != null) {
        paramType = TypeRef.fromAnnotation(
          ctx,
          decLibrary,
          typeAnnotation,
          typeParameters: resolveGenerics,
        );
      }
    } else if (param is FieldFormalParameter) {
      paramType = resolveFieldFormalType(ctx, decLibrary, param, parameterHost);
    } else if (param is SuperFormalParameter) {
      paramType = resolveSuperFormalType(ctx, decLibrary, param, parameterHost);
    } else {
      throw CompileError('Unknown formal type ${param.runtimeType}');
    }

    if (namedExpr.containsKey(name)) {
      final genericParameter =
          typeAnnotation is NamedType &&
          resolveGenerics.containsKey(typeAnnotation.name.lexeme);
      var arg0 = compileExpression(namedExpr[name]!, ctx, paramType);
      arg0 = convertForAssignment(
        ctx,
        arg0,
        paramType,
        representation:
            parameterHost is MethodDeclaration ||
                genericParameter ||
                !paramType.isUnboxedAcrossFunctionBoundaries
            ? MachineRepresentation.object
            : representationForType(paramType.copyWith(boxed: false)),
        source: source ?? parameterHost,
        description:
            'Cannot assign argument of type ${arg0.type.toStringClear(ctx, paramType)} '
            'to parameter "${param.name!.lexeme}" of type '
            '${paramType.toStringClear(ctx, arg0.type)}',
      );
      if (parameterHost is MethodDeclaration ||
          genericParameter ||
          !paramType.isUnboxedAcrossFunctionBoundaries) {
        arg0 = arg0.boxIfNeeded(ctx);
      } else if (paramType.isUnboxedAcrossFunctionBoundaries) {
        arg0 = arg0.unboxIfNeeded(ctx);
      }

      if (arg0.type == CoreTypes.function.ref(ctx) &&
          arg0.name == null &&
          arg0.methodOffset != null) {
        arg0 = arg0.tearOff(ctx);
      }

      if (typeAnnotation != null) {
        final n = typeAnnotation is NamedType
            ? (typeAnnotation.name.stringValue ?? typeAnnotation.name.lexeme)
            : null;
        if (inferGenerics && n != null && resolveGenerics.containsKey(n)) {
          resolveGenericsMap[n] ??= {};
          resolveGenericsMap[n]!.add(arg0.type);
        }
      }

      push.add(arg0);
      namedArgs[name] = arg0;
    } else {
      final value = _omittedArgument(ctx, decLibrary, param0, parameterHost);
      push.add(value);
      namedArgs[name] = value;
    }
  }

  if (inferGenerics) {
    for (final generic in resolveGenericsMap.keys) {
      resolveGenerics[generic] = TypeRef.commonBaseType(
        ctx,
        resolveGenericsMap[generic]!,
      );
    }
  }

  ssa.addAll(push.map((argument) => argument.ssa));
  return ArgumentListResult(ssa, args, namedArgs);
}

ArgumentListResult compileSuperParams(
  CompilerContext ctx,
  List<FormalParameter> fpl,
  Declaration parameterHost, {
  List<Variable> before = const [],
  List<String> superParams = const [],
  AstNode? source,
}) {
  final ssa = <SSA>[];
  final args = <Variable>[];
  final push = <Variable>[...before];
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
        final value = _omittedArgument(ctx, ctx.library, param, parameterHost);
        push.add(value);
        args.add(value);
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
      final value = _omittedArgument(ctx, ctx.library, n.value, parameterHost);
      push.add(value);
      namedArgs[name] = value;
    }
  }

  ssa.addAll(push.map((argument) => argument.ssa));
  return ArgumentListResult(ssa, args, namedArgs);
}

ArgumentListResult compileSuperParamsWithBridge(
  CompilerContext ctx,
  BridgeFunctionDef function, {
  List<Variable> before = const [],
  List<String> superParams = const [],
}) {
  final ssa = <SSA>[];
  final args = <Variable>[];
  final push = <Variable>[...before];
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

  ssa.addAll(push.map((argument) => argument.ssa));
  return ArgumentListResult(ssa, args, namedArgs);
}

/// Compile dynamic arguments in source evaluation order. Binding and default
/// insertion happen after runtime member lookup.
ArgumentListResult compileArgumentListWithDynamic(
  CompilerContext ctx,
  ArgumentList argumentList, {
  List<Variable> before = const [],
  Map<String, TypeRef> resolveGenerics = const {},
  AstNode? source,
}) {
  final ssa = <SSA>[];
  final args = <Variable>[];
  final push = <Variable>[...before];
  final namedArgs = <String, Variable>{};

  for (var i = 0; i < argumentList.arguments.length; i++) {
    final arg = argumentList.arguments[i];

    final expression = arg.argumentExpression;
    var arg0 = compileExpression(expression, ctx);
    if (arg0.type == CoreTypes.function.ref(ctx) &&
        arg0.name == null &&
        arg0.methodOffset != null) {
      arg0 = arg0.tearOff(ctx);
    }
    // Dynamic calls use canonical object values for every argument. Their
    // signature cannot justify unboxing a scalar or a collection here.
    arg0 = arg0.boxIfNeeded(ctx);

    if (arg is NamedArgument) {
      namedArgs[arg.name.lexeme] = arg0;
    } else {
      args.add(arg0);
    }
    push.add(arg0);
  }

  ssa.addAll(push.map((argument) => argument.ssa));
  return ArgumentListResult(ssa, args, namedArgs);
}

ArgumentListResult compileArgumentListWithBridge(
  CompilerContext ctx,
  ArgumentList argumentList,
  BridgeFunctionDef function, {
  List<Variable> before = const [],
  List<String> superParams = const [],
  Map<String, TypeRef> typeParameters = const {},
}) {
  final ssa = <SSA>[];
  final args = <Variable>[];
  final push = <Variable>[...before];
  final namedArgs = <String, Variable>{};
  final namedExpr = <String, Expression>{};

  var i = 0;
  Variable? $null;

  for (final param in function.params) {
    if (superParams.contains(param.name)) {
      final V = _providedBridgeArgument(ctx, ctx.lookupLocal(param.name)!);
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
    if (arg is NamedArgument) {
      if (!param.optional) {
        throw CompileError('Not enough positional arguments');
      } else {
        $null ??= BuiltinValue().push(ctx);
        push.add($null);
      }
    } else {
      // Resolve the receiver's type arguments for every parameter annotation.
      // Simple refs (for example E in List.add) need them as much as generic
      // function types do; dropping them leaves the context type dynamic and
      // defeats argument conversion and reified checks.
      var paramType = TypeRef.fromBridgeAnnotation(
        ctx,
        param.type,
        typeParameters: typeParameters,
      );

      var arg0 = compileExpression(arg.argumentExpression, ctx, paramType);
      arg0 = arg0.boxIfNeeded(ctx);
      if (arg0.type == CoreTypes.function.ref(ctx) &&
          arg0.name == null &&
          arg0.methodOffset != null) {
        arg0 = arg0.tearOff(ctx);
      }
      // Bridge argument conversion lives on the runtime side of the typed
      // boundary (previously the compiler only boxed). Type parameters that
      // resolved through the receiver, nullable matches, and dynamic argument
      // shapes can carry distinct [TypeRef] identities for an equivalent
      // static type, so a failing compile-time [isAssignableTo] here must
      // defer to the boundary conversion instead of rejecting.
      arg0 = _providedBridgeArgument(ctx, arg0);
      args.add(arg0);
      push.add(arg0);
    }

    i++;
  }

  for (final arg in argumentList.arguments) {
    if (arg is NamedArgument) {
      namedExpr[arg.name.lexeme] = arg.argumentExpression;
    }
  }

  for (final param in function.namedParams) {
    if (superParams.contains(param.name)) {
      final V = _providedBridgeArgument(ctx, ctx.lookupLocal(param.name)!);
      push.add(V);
      namedArgs[param.name] = V;
      continue;
    }
    var paramType = TypeRef.fromBridgeAnnotation(
      ctx,
      param.type,
      typeParameters: typeParameters,
    );
    if (namedExpr.containsKey(param.name)) {
      var arg0 = compileExpression(
        namedExpr[param.name]!,
        ctx,
        paramType,
      ).boxIfNeeded(ctx);
      if (arg0.type == CoreTypes.function.ref(ctx) &&
          arg0.name == null &&
          arg0.methodOffset != null) {
        arg0 = arg0.tearOff(ctx);
      }
      if (!arg0.type.resolveTypeChain(ctx).isAssignableTo(ctx, paramType)) {
        throw CompileError(
          'Cannot assign argument of type ${arg0.type} to parameter of type $paramType',
          argumentList,
        );
      }
      arg0 = _providedBridgeArgument(ctx, arg0);
      push.add(arg0);
      namedArgs[param.name] = arg0;
    } else {
      $null ??= BuiltinValue().push(ctx);
      push.add($null);
    }
  }

  ssa.addAll(push.map((argument) => argument.ssa));
  return ArgumentListResult(ssa, args, namedArgs);
}

TypeRef resolveFieldFormalType(
  CompilerContext ctx,
  int decLibrary,
  FieldFormalParameter param,
  Declaration parameterHost,
) {
  if (parameterHost is! ConstructorDeclaration) {
    throw CompileError('Field formals can only occur in constructors');
  }
  final $class = parameterHost.parent!.parent as Declaration;
  return TypeRef.lookupFieldType(
        ctx,
        TypeRef.lookupDeclaration(ctx, decLibrary, $class),
        param.name.lexeme,
        forFieldFormal: true,
        source: param,
      ) ??
      CoreTypes.dynamic.ref(ctx);
}

TypeRef resolveSuperFormalType(
  CompilerContext ctx,
  int decLibrary,
  SuperFormalParameter param,
  Declaration parameterHost,
) {
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
  final $class = parameterHost.parent!.parent as ClassDeclaration;
  final type = TypeRef.lookupDeclaration(ctx, decLibrary, $class);
  final $super =
      type.resolveTypeChain(ctx).extendsType ??
      (throw CompileError(
        'Class $type has no super class, so cannot use super formals',
        param,
      ));
  final superCstr =
      ctx.topLevelDeclarationsMap[$super
          .file]!['${$super.name}.$superConstructorName']!;
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
      var param0 = cstrParam;
      if (param0.name?.lexeme != param.name.lexeme) {
        continue;
      }
      if (param0 is RegularFormalParameter) {
        final type0 = param0.type;
        if (type0 == null) {
          return CoreTypes.dynamic.ref(ctx);
        }
        return TypeRef.fromAnnotation(ctx, $super.file, type0);
      } else if (param0 is FieldFormalParameter) {
        return resolveFieldFormalType(ctx, decLibrary, param0, cstr);
      } else if (param0 is SuperFormalParameter) {
        return resolveSuperFormalType(ctx, decLibrary, param0, cstr);
      } else {
        throw CompileError(
          'Unknown parameter type ${param0.runtimeType}',
          param0,
        );
      }
    }
  }

  throw CompileError(
    'Could not find parameter ${param.name.value()} in the referenced superclass constructor',
    param,
    decLibrary,
  );
}
