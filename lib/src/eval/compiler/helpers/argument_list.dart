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
import '../values/abi.dart';
import '../../ir/bridge.dart' show PrepareBridgeArgument;
import '../../ir/types.dart' show ResolveTypeId;

Variable _providedBridgeArgument(CompilerContext ctx, Variable argument) {
  final type = argument.type;
  if (!type.nullable &&
      !type.isSpec(CoreTypes.nullType) &&
      !type.isSpec(CoreTypes.dynamic)) {
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

/// Converts an already-compiled argument to the representation the callee's
/// ABI expects for [param]: boxed unless the parameter type crosses the
/// function boundary unboxed (never for [MethodDeclaration] hosts, whose
/// dynamic dispatch ABI is always boxed). Tear-offs materialize last.
Variable coerceArgumentForParameter(
  CompilerContext ctx,
  Variable arg0,
  TypeRef paramType,
  FormalParameter param,
  Declaration parameterHost, {
  bool genericParameter = false,
  AstNode? source,
}) {
  final paramRep = Abi.parameter(
    paramType,
    parameterHost is MethodDeclaration
        ? CallableKind.method
        : CallableKind.function,
    erased: genericParameter,
  );
  arg0 = convertForAssignment(
    ctx,
    arg0,
    paramType,
    representation: paramRep.bank,
    source: source ?? parameterHost,
    description:
        'Cannot assign argument of type ${arg0.type.toStringClear(ctx, paramType)} '
        'to parameter "${param.name!.lexeme}" of type '
        '${paramType.toStringClear(ctx, arg0.type)}',
  );
  arg0 = paramRep == ValueRep.boxed
      ? arg0.boxIfNeeded(ctx)
      : arg0.unboxIfNeeded(ctx);

  if (arg0.type.isFunctionLike &&
      arg0.name == null &&
      arg0.methodOffset != null) {
    arg0 = arg0.tearOff(ctx);
  }
  return arg0;
}

/// Pushes an integer carrying [type]'s runtime type id, resolving embedded
/// type parameters against the frame's type environment at runtime.
SSA pushRuntimeTypeId(CompilerContext ctx, TypeRef type) {
  final typeId = ctx.runtimeTypes.idOf(type);
  if (!type.requiresTypeEnvironment) {
    return BuiltinValue(intval: typeId).push(ctx).ssa;
  }
  final ssa = ctx.svar('typeId');
  ctx.pushOp(ResolveTypeId(ssa, typeId));
  return ssa;
}

/// Compiles the fallback value for [parameter] when the caller supplies no
/// argument: the parameter's default expression, or null.
Variable compileOmittedArgument(
  CompilerContext ctx,
  int library,
  FormalParameter parameter,
  Declaration host, {
  Map<String, TypeRef> typeParameters = const {},
}) {
  if (parameter.isRequired) {
    throw CompileError(
      'Missing required argument ${parameter.name!.lexeme}',
      parameter,
    );
  }
  // The default expression and parameter annotations resolve in the host
  // declaration's own library — its private names aren't visible in the
  // caller's, and the caller's `library` may differ (e.g. class type alias
  // forwarding ctors expose a foreign host's parameters).
  final hostParent = switch (host) {
    ConstructorDeclaration() || MethodDeclaration() => host.parent?.parent,
    _ => null,
  };
  if (hostParent is Declaration) {
    final memberName = switch (host) {
      ConstructorDeclaration() => host.name?.lexeme ?? '',
      MethodDeclaration() => host.name.lexeme,
      _ => '',
    };
    final hostKey = '${declarationName(hostParent)}.$memberName';
    // A declaration may be registered under alias keys in other libraries
    // (`P1.` forwards to `B2.`); match the key that is the host's own name.
    for (final entry in ctx.topLevelDeclarationsMap.entries) {
      final d = entry.value[hostKey];
      if (d != null && identical(d.declaration, host)) {
        library = entry.key;
        break;
      }
    }
  }
  final (declaredType, _) = getFormalParameterType(
    ctx,
    parameter,
    library,
    host,
    typeParameters: typeParameters,
  );
  final type = declaredType ?? CoreTypes.dynamic.ref(ctx);
  // Scalar defaults push as native constants; anything else (tear-offs, const
  // objects) compiles the constant expression normally. Super formals inherit
  // their default from the bound super-constructor parameter, evaluated in
  // the super constructor's library.
  var defaultExpr = parameter.defaultClause?.value;
  if (defaultExpr == null &&
      parameter is SuperFormalParameter &&
      host is ConstructorDeclaration) {
    final inherited = superFormalDefault(ctx, library, parameter, host);
    if (inherited != null) {
      (defaultExpr, library) = inherited;
    }
  }
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
    // The default expression resolves in the declaring library — its private
    // names aren't visible in the caller's library.
    final previousLibrary = ctx.library;
    ctx.library = library;
    try {
      variable = compileExpression(defaultExpr!, ctx, type);
    } finally {
      ctx.library = previousLibrary;
    }
  } else {
    if (value is int && type.isSpec(CoreTypes.double)) {
      value = value.toDouble();
    }
    variable = pushDefaultValue(ctx, value);
  }
  return host is MethodDeclaration || Abi.unboxedAcrossCalls(type).isBoxed
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
  SuperParams superParams = const (positional: [], named: {}),
  AstNode? source,
  // Explicit extension application (`E.m(receiver, ...)`) leads the
  // argument list with the receiver, which has no declared formal — the
  // receiver is compiled separately and passed via [before], so indexing
  // into the argument list starts past it.
  int argIndexOffset = 0,
}) {
  // A redirecting factory (`factory F(...) = T.g`) exposes the redirect
  // target's signature to callers: argument binding, conversion, and omitted
  // defaults all resolve against the target constructor's parameters.
  if (parameterHost is ConstructorDeclaration &&
      parameterHost.redirectedConstructor != null) {
    final redirect = parameterHost.redirectedConstructor!;
    final (typeName, ctorName) = splitConstructorTypeName(
      ctx,
      decLibrary,
      redirect.type,
      redirect.name?.name,
    );
    final targetRef = ctx.visibleTypes[decLibrary]![typeName];
    final targetDecl = targetRef == null
        ? null
        : ctx
              .topLevelDeclarationsMap[targetRef
                  .file]!['${targetRef.name}.$ctorName']
              ?.declaration;
    if (targetDecl is ConstructorDeclaration) {
      decLibrary = targetRef!.file;
      fpl = targetDecl.parameters.parameters;
      parameterHost = targetDecl;
    }
  }

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

  // Parameters whose annotations name one of the host class's type
  // parameters use the erased-object ABI — even when the call site supplies
  // no seed (e.g. an alias constructor whose own class has no parameters).
  final ctorClassParams =
      parameterHost is ConstructorDeclaration &&
          parameterHost.parent?.parent is Declaration
      ? classLikeClauses(
              parameterHost.parent!.parent! as Declaration,
            ).$4?.typeParameters ??
            const <TypeParameter>[]
      : const <TypeParameter>[];
  final ctorClassParamNames = <String>{
    for (final p in ctorClassParams) p.name.lexeme,
  };
  // Field/super formals resolve to class type-parameter references; the call
  // site's bindings instantiate them (e.g. `C<num, double>(0, 0.5)` makes
  // `this.field2`'s declared `S` check against `double`). The same
  // parameters appear as name-keyed references so annotations on ordinary
  // (non-formal) params like `T z` resolve inside the ctor.
  final ctorClassParamRefs = <String, TypeRef>{};
  if (ctorClassParams.isNotEmpty) {
    final hostName = declarationName(
      parameterHost.parent!.parent! as Declaration,
    );
    declareTypeParameters(
      TypeParameterOwner(
        TypeParameterOwnerKind.classLike,
        decLibrary,
        hostName,
      ),
      ctorClassParams,
      ctorClassParamRefs,
      (bound) => TypeRef.fromAnnotation(
        ctx,
        decLibrary,
        bound,
        typeParameters: {...ctorClassParamRefs, ...resolveGenerics},
      ),
    );
  }
  final ctorClassParamSubs = Substitution.wrap(<TypeParameterDef, TypeRef>{
    for (final param in ctorClassParams)
      ctorClassParamRefs[param.name.lexeme]!.parameter!: ?resolveGenerics[param
          .name
          .lexeme],
  });
  final paramTypeParameters = {...ctorClassParamRefs, ...resolveGenerics};

  final resolveGenericsMap = <String, Set<TypeRef>>{};

  for (final param in positional) {
    // First check super params. Super params do not contain an expression;
    // positional ones bind to the callee's positional parameters in order.
    if (i < superParams.positional.length) {
      final V = _forwardedSuperParam(
        ctx,
        param,
        parameterHost,
        decLibrary,
        superParams.positional[i],
        typeParameters: paramTypeParameters,
        ctorClassParamSubs: ctorClassParamSubs,
        genericParameterNames: {
          ...resolveGenerics.keys,
          ...ctorClassParamNames,
        },
        source: source,
      );
      push.add(V);
      args.add(V);
      i++;
      continue;
    }
    final arg = argumentList.arguments.length <= i + argIndexOffset
        ? null
        : argumentList.arguments[i + argIndexOffset];
    if (arg is NamedArgument) {
      if (param.isRequired) {
        throw CompileError('Not enough positional arguments');
      } else {
        final value = compileOmittedArgument(
          ctx,
          decLibrary,
          param,
          parameterHost,
          typeParameters: paramTypeParameters,
        );
        push.add(value);
        args.add(value);
      }
    } else if (arg == null) {
      if (param.isRequired) {
        throw CompileError('Not enough positional arguments');
      } else {
        final value = compileOmittedArgument(
          ctx,
          decLibrary,
          param,
          parameterHost,
          typeParameters: paramTypeParameters,
        );
        push.add(value);
        args.add(value);
      }
    } else {
      var (paramType, typeAnnotation) = getFormalParameterType(
        ctx,
        param,
        decLibrary,
        parameterHost,
        typeParameters: paramTypeParameters,
      );

      paramType ??= CoreTypes.dynamic.ref(ctx);
      if (ctorClassParamSubs.isNotEmpty) {
        paramType = paramType.substituteTypeParameters(ctorClassParamSubs);
      }
      final genericParameter =
          typeAnnotation is NamedType &&
          (resolveGenerics.containsKey(typeAnnotation.name.lexeme) ||
              ctorClassParamNames.contains(typeAnnotation.name.lexeme));

      var arg0 = compileExpression(arg.argumentExpression, ctx, paramType);
      arg0 = coerceArgumentForParameter(
        ctx,
        arg0,
        paramType,
        param,
        parameterHost,
        genericParameter: genericParameter,
        source: source,
      );

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
    if (superParams.named.contains(name)) {
      final V = _forwardedSuperParam(
        ctx,
        param0,
        parameterHost,
        decLibrary,
        name,
        typeParameters: paramTypeParameters,
        ctorClassParamSubs: ctorClassParamSubs,
        genericParameterNames: {
          ...resolveGenerics.keys,
          ...ctorClassParamNames,
        },
        source: source,
      );
      push.add(V);
      namedArgs[name] = V;

      continue;
    }
    final param = param0;
    var (paramType, typeAnnotation) = getFormalParameterType(
      ctx,
      param,
      decLibrary,
      parameterHost,
      typeParameters: paramTypeParameters,
    );
    paramType ??= CoreTypes.dynamic.ref(ctx);
    if (ctorClassParamSubs.isNotEmpty) {
      paramType = paramType.substituteTypeParameters(ctorClassParamSubs);
    }

    if (namedExpr.containsKey(name)) {
      final genericParameter =
          typeAnnotation is NamedType &&
          (resolveGenerics.containsKey(typeAnnotation.name.lexeme) ||
              ctorClassParamNames.contains(typeAnnotation.name.lexeme));
      var arg0 = compileExpression(namedExpr[name]!, ctx, paramType);
      arg0 = coerceArgumentForParameter(
        ctx,
        arg0,
        paramType,
        param,
        parameterHost,
        genericParameter: genericParameter,
        source: source,
      );

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
      final value = compileOmittedArgument(
        ctx,
        decLibrary,
        param0,
        parameterHost,
        typeParameters: paramTypeParameters,
      );
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

/// A constructor's `super` parameters split for forwarding: positional super
/// parameters bind the superclass constructor's positional parameters in
/// order (their local names need not match the callee's), named ones by name.
typedef SuperParams = ({List<String> positional, Set<String> named});

/// The value a `super` parameter forwards to the callee: the caller's local
/// [localName] coerced to the callee [param]'s boundary representation.
/// Locals may have been boxed for field storage while the callee takes them
/// unboxed, or vice versa — without the coercion the SSA keeps the wrong
/// representation.
Variable _forwardedSuperParam(
  CompilerContext ctx,
  FormalParameter param,
  Declaration parameterHost,
  int decLibrary,
  String localName, {
  Map<String, TypeRef> typeParameters = const {},
  Substitution ctorClassParamSubs = Substitution.empty,
  Set<String> genericParameterNames = const {},
  AstNode? source,
}) {
  var (paramType, typeAnnotation) = getFormalParameterType(
    ctx,
    param,
    decLibrary,
    parameterHost,
    typeParameters: typeParameters,
  );
  paramType ??= CoreTypes.dynamic.ref(ctx);
  if (ctorClassParamSubs.isNotEmpty) {
    paramType = paramType.substituteTypeParameters(ctorClassParamSubs);
  }
  final genericParameter =
      typeAnnotation is NamedType &&
      genericParameterNames.contains(typeAnnotation.name.lexeme);
  return coerceArgumentForParameter(
    ctx,
    ctx.lookupLocal(localName)!,
    paramType,
    param,
    parameterHost,
    genericParameter: genericParameter,
    source: source,
  );
}

ArgumentListResult compileSuperParams(
  CompilerContext ctx,
  List<FormalParameter> fpl,
  Declaration parameterHost, {
  required int decLibrary,
  List<Variable> before = const [],
  SuperParams superParams = const (positional: [], named: {}),
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

  var positionalSuperIndex = 0;
  for (final param in positional) {
    // First check super params. Super params do not contain an expression;
    // positional ones bind to the callee's positional parameters in order.
    if (positionalSuperIndex < superParams.positional.length) {
      final V = _forwardedSuperParam(
        ctx,
        param,
        parameterHost,
        decLibrary,
        superParams.positional[positionalSuperIndex++],
        source: source,
      );
      push.add(V);
      args.add(V);
    } else {
      if (param.isRequired) {
        throw CompileError('Not enough positional arguments');
      } else {
        final value = compileOmittedArgument(
          ctx,
          decLibrary,
          param,
          parameterHost,
        );
        push.add(value);
        args.add(value);
      }
    }
  }

  for (final n in named.entries) {
    final name = n.key;
    if (superParams.named.contains(name)) {
      final V = _forwardedSuperParam(
        ctx,
        n.value,
        parameterHost,
        decLibrary,
        name,
        source: source,
      );
      push.add(V);
      namedArgs[name] = V;
    } else {
      final value = compileOmittedArgument(
        ctx,
        decLibrary,
        n.value,
        parameterHost,
      );
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
  SuperParams superParams = const (positional: [], named: {}),
}) {
  final ssa = <SSA>[];
  final args = <Variable>[];
  final push = <Variable>[...before];
  final namedArgs = <String, Variable>{};

  Variable? $null;
  var positionalSuperIndex = 0;

  for (final param in function.params) {
    // First check super params. Super params do not contain an expression;
    // positional ones bind to the callee's positional parameters in order.
    if (positionalSuperIndex < superParams.positional.length) {
      final V = _providedBridgeArgument(
        ctx,
        ctx.lookupLocal(superParams.positional[positionalSuperIndex++])!,
      );
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
    if (superParams.named.contains(param.name)) {
      final V = _providedBridgeArgument(ctx, ctx.lookupLocal(param.name)!);
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
    if (arg0.type.isFunctionLike &&
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
  SuperParams superParams = const (positional: [], named: {}),
  Map<String, TypeRef> typeParameters = const {},
}) {
  final ssa = <SSA>[];
  final args = <Variable>[];
  final push = <Variable>[...before];
  final namedArgs = <String, Variable>{};
  final namedExpr = <String, Expression>{};

  var i = 0;
  Variable? $null;
  var positionalSuperIndex = 0;

  for (final param in function.params) {
    if (positionalSuperIndex < superParams.positional.length) {
      final V = _providedBridgeArgument(
        ctx,
        ctx.lookupLocal(superParams.positional[positionalSuperIndex])!,
      );
      push.add(V);
      args.add(V);

      i++;
      positionalSuperIndex++;
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
      if (arg0.type.isFunctionLike &&
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
    if (superParams.named.contains(param.name)) {
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
      if (arg0.type.isFunctionLike &&
          arg0.name == null &&
          arg0.methodOffset != null) {
        arg0 = arg0.tearOff(ctx);
      }
      if (arg0.type.assignmentConversionTo(ctx, paramType) ==
          AssignmentConversion.invalid) {
        throw CompileError(
          'Cannot assign argument of type ${arg0.type} to parameter of type $paramType',
          argumentList,
        );
      }
      arg0 = convertForAssignment(
        ctx,
        arg0,
        paramType,
        representation: MachineRepresentation.object,
        source: argumentList,
      );
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
  final (superCstr, target) = superFormalTarget(
    ctx,
    decLibrary,
    param,
    parameterHost,
  );
  if (superCstr.isBridge) {
    if (target is BridgeParameter) {
      return TypeRef.fromBridgeAnnotation(ctx, target.type);
    }
  } else if (target is RegularFormalParameter) {
    final type0 = target.type;
    if (type0 == null) {
      return CoreTypes.dynamic.ref(ctx);
    }
    return TypeRef.fromAnnotation(ctx, superCstr.sourceLib, type0);
  } else if (target is FieldFormalParameter) {
    return resolveFieldFormalType(
      ctx,
      decLibrary,
      target,
      superCstr.declaration as ConstructorDeclaration,
    );
  } else if (target is SuperFormalParameter) {
    return resolveSuperFormalType(
      ctx,
      decLibrary,
      target,
      superCstr.declaration as ConstructorDeclaration,
    );
  } else if (target != null) {
    throw CompileError('Unknown parameter type ${target.runtimeType}', param);
  }

  throw CompileError(
    'Could not find parameter ${param.name.value()} in the referenced superclass constructor',
    param,
    decLibrary,
  );
}
