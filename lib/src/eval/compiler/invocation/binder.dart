import 'package:dart_eval/src/eval/compiler/context.dart';
import 'deferred.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart' hide Assign;
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import '../builtins.dart';
import '../errors.dart';
import '../member/call_signature.dart';
import '../member/member.dart';
import '../member/member_name.dart';
import '../helpers/argument_list.dart';
import '../../ir/bridge.dart' show PrepareBridgeArgument;
import 'bound_call.dart';
import 'call.dart';
import 'targets.dart';

/// Maps a [CallSite]'s argument shape onto a [CallTarget]'s signature:
/// match, seed the substitution, compile and coerce, solve inference, fill
/// omitted arguments per the target's policy.
final class ArgumentBinder {
  const ArgumentBinder(this.ctx);

  final CompilerContext ctx;

  /// `calleeBinds` — supplied arguments only. Every unboxed argument is
  /// snapshotted into a fresh slot so boxing never rewrites the SSA an
  /// unboxed local still uses.
  BoundCall bindSuppliedOnly(
    CallTarget target,
    CallSite site, {
    required Variable? callee,
  }) {
    // The callee is materialized before any argument compiles — an
    // argument may redefine the SSA slot the callee expression read
    // (`f(f = g())` invokes the old `f`).
    Variable? materializedCallee;
    if (callee != null &&
        !(target is ClosureCall && target.known != null)) {
      final boxed = callee.boxed ? callee : callee.boxIntoFreshSlot(ctx);
      materializedCallee = Variable.ssa(
        ctx,
        Assign(ctx.svar('closure_target'), boxed.ssa),
        boxed.type,
      );
    }

    Variable snapshot(Variable argument) => argument.boxed
        ? argument
        : Variable.ssa(
            ctx,
            Assign(ctx.svar('closure_argument'), argument.ssa),
            argument.type,
          ).boxIfNeeded(ctx);

    final positional = List<BoundArgument?>.filled(
      site.shape.positional.length,
      null,
    );
    final named = List<(String, BoundArgument)?>.filled(
      site.shape.named.length,
      null,
    );
    // Arguments evaluate in source order — the interleave matters.
    for (final i in site.shape.sourceOrder) {
      if (i >= 0) {
        positional[i] = BoundArgument(
          snapshot(_compileArg(ctx, site.shape.positional[i])),
        );
      } else {
        final (name, source) = site.shape.named[-1 - i];
        named[-1 - i] = (name, BoundArgument(snapshot(_compileArg(ctx, source))));
      }
    }
    final positionalArgs = positional.cast<BoundArgument>();
    final namedArgs = named.cast<(String, BoundArgument)>();

    final runtimeTypeArguments =
        site.shape.typeArguments
            ?.map((type) => TypeRef.fromAnnotation(ctx, ctx.library, type))
            .map((type) => ctx.runtimeTypes.idOf(type))
            .toList() ??
        const <int>[];

    final dispatch = target is ClosureCall ? target.known : null;
    final argTypes = [for (final a in positionalArgs) a.value.type];
    final namedArgTypes = {
      for (final e in namedArgs) e.$1: e.$2.value.type,
    };
    final resultType =
        callResultType(
          ctx,
          callee: callee,
          dispatch: dispatch,
          argTypes: argTypes,
          namedArgTypes: namedArgTypes,
        ) ??
        CoreTypes.dynamic.ref(ctx);
    return BoundCall(
      positional: positionalArgs,
      named: namedArgs,
      callee: materializedCallee,
      runtimeTypeArguments: runtimeTypeArguments,
      returnType: resultType,
      trusted: _closureArgumentsProven(
        ctx,
        callee?.type,
        [for (final a in positionalArgs) a.value],
        {for (final e in namedArgs) e.$1: e.$2.value},
      ),
    );
  }

  Variable _compileArg(CompilerContext ctx, ArgSource source) {
    return switch (source) {
      ExpressionArg(:final expression) => compileExpression(expression, ctx),
      ValueArg(:final value) => value,
      ForwardedLocal(:final localName) =>
        ctx.lookupBinding(localName)?.read(ctx) ??
            (throw StateError('missing forwarded local $localName')),
    };
  }
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

BoundCall bindParameterList(
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
  /// When false, unsupplied optional positional and named parameters are
  /// left for the callee to bind (`calleeBinds`) — used for calls that stay
  /// virtual, where the dispatch target's own defaults apply at runtime.
  bool fillOmitted = true,
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
      ctx,
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
  final ctorClassParamSubs = Substitution.of(<TypeParameterDef, TypeRef>{
    for (final param in ctorClassParams)
      (ctorClassParamRefs[param.name.lexeme]! as TypeParameterTypeRef)
          .parameter: ?resolveGenerics[param.name.lexeme],
  });
  final paramTypeParameters = {...ctorClassParamRefs, ...resolveGenerics};

  final resolveGenericsMap = <String, Set<TypeRef>>{};


  // Compiles the supplied argument [expr] for [param]: context-typed
  // compilation, coercion to the formal, and generic-inference recording.
  Variable compileMatched(FormalParameter param, Expression expr) {
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

    // The placeholder-rich parameter shape under [InferenceMode.unify]:
    // built before argument compilation so context-sensitive arguments
    // (closures, generic tear-offs) see the generic form rather than the
    // erased formal type.
    TypeRef? unifyPattern;
    final unifyPlaceholders = <String, TypeRef>{};
    final unifyDefs = <String, TypeParameterDef>{};
    if (inferGenerics &&
        typeAnnotation != null &&
        resolveGenerics.isNotEmpty) {
      var i = 0;
      final callSiteOwner = _callSiteOwner(decLibrary, parameterHost);
      for (final name in resolveGenerics.keys) {
        final def = TypeParameterDef(callSiteOwner, i++, name);
        unifyDefs[name] = def;
        unifyPlaceholders[name] =
            TypeParameterTypeRef(def, file: decLibrary);
      }
      unifyPattern = ctx.typeFactory.formalParameterAnnotationType(
        decLibrary,
        param,
        typeParameters: {...paramTypeParameters, ...unifyPlaceholders},
      );
    }

    // The placeholder-rich shape only serves as context for function-typed
    // parameters — collection literals need the erased formal so their
    // element types stay unconstrained until unification.
    final argBound = unifyPattern is FunctionTypeRef ? unifyPattern : paramType;
    var arg0 = compileExpression(expr, ctx, argBound);
    arg0 = coerceArgumentForParameter(
      ctx,
      arg0,
      paramType,
      param,
      parameterHost,
      genericParameter: genericParameter,
      source: source,
    );

    if (unifyPattern != null) {
      // Deep inference: unify the parameter's declared shape against the
      // supplied type — `List<X>` against `List<int>` binds X to int —
      // recording each bound generic name for the common-base solve.
      {
        final bindings = <TypeParameterDef, TypeRef>{};
        ctx.typeSystem.unify(unifyPattern, arg0.type, bindings);
        for (final e in unifyDefs.entries) {
          final bound = bindings[e.value];
          if (bound != null) {
            resolveGenericsMap[e.key] ??= {};
            resolveGenericsMap[e.key]!.add(bound);
          }
        }
      }
    } else if (typeAnnotation != null) {
      final n = typeAnnotation is NamedType
          ? (typeAnnotation.name.stringValue ?? typeAnnotation.name.lexeme)
          : null;
      if (inferGenerics && n != null && resolveGenerics.containsKey(n)) {
        resolveGenericsMap[n] ??= {};
        resolveGenericsMap[n]!.add(arg0.type);
      }
    }
    return arg0;
  }

  // **Match.** Map arguments to formals without emitting. Under `legacy` a
  // positional parameter consumes the argument at its own index — a named
  // argument in that slot counts as missing, reproducing today's failure.
  // Under `allowNamedBeforePositional` named arguments are skipped during
  // positional matching, as Dart requires.
  final rawArguments = argumentList.arguments;
  final matchPositional = List<Expression?>.filled(positional.length, null);
  final matchNamed = <String, Expression>{};
  final argIndexToPositional = <int, int>{};
  final argIndexToNamed = <int, String>{};
  // Forwarded super parameters occupy the leading positional-param slots.
  var positionalCursor = superParams.positional.length;
  for (var a = argIndexOffset; a < rawArguments.length; a++) {
    final arg = rawArguments[a];
    if (arg is NamedArgument) {
      final name = arg.name.lexeme;
      if (!named.containsKey(name)) {
        throw CompileError('Unknown named argument $name', arg);
      }
      matchNamed[name] = arg.argumentExpression;
      argIndexToNamed[a] = name;
    } else {
      final p = positionalCursor;
      positionalCursor++;
      if (p >= positional.length) {
        throw CompileError(
          'Too many positional arguments: ${positional.length} expected, '
          'but ${p + 1} found.',
        );
      }
      matchPositional[p] = arg.argumentExpression;
      argIndexToPositional[a] = p;
    }
  }

  // **Compile** supplied arguments in source order — a named argument
  // interleaves with positionals.
  final compiledPositional = List<Variable?>.filled(positional.length, null);
  final compiledNamed = <String, Variable>{};
  for (var a = argIndexOffset; a < rawArguments.length; a++) {
    final pi = argIndexToPositional[a];
    if (pi != null) {
      compiledPositional[pi] = compileMatched(
        positional[pi],
        matchPositional[pi]!,
      );
    } else {
      final name = argIndexToNamed[a];
      if (name != null) {
        compiledNamed[name] = compileMatched(named[name]!, matchNamed[name]!);
      }
    }
  }

  // **Emit** the vector in declaration order.
  for (var pi = 0; pi < positional.length; pi++) {
    final param = positional[pi];
    // First check super params. Super params do not contain an expression;
    // positional ones bind to the callee's positional parameters in order.
    if (i < superParams.positional.length) {
      final V = _forwardedSuperParam(

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
    final arg0 = compiledPositional[i];
    if (arg0 != null) {
      args.add(arg0);
      push.add(arg0);
    } else {
      if (param.isRequired) {
        throw CompileError('Not enough positional arguments');
      } else if (fillOmitted) {
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
    }
    i++;
  }

  for (final n in named.entries) {
    final name = n.key;
    final param0 = n.value;
    if (superParams.named.contains(name)) {
      final V = _forwardedSuperParam(

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
    final arg0 = compiledNamed[name];
    if (arg0 != null) {
      push.add(arg0);
      namedArgs[name] = arg0;
    } else if (fillOmitted) {
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
  return BoundCall(
      positional: [for (final a in args) BoundArgument(a)],
      named: [
        for (final e in namedArgs.entries) (e.key, BoundArgument(e.value)),
      ],
      vectorOverride: ssa,
      returnType: CoreTypes.dynamic.ref(ctx),
    );
}


/// The value a `super` parameter forwards to the callee: the caller's local
/// [localName] coerced to the callee [param]'s boundary representation.
/// Locals may have been boxed for field storage while the callee takes them
/// unboxed, or vice versa — without the coercion the SSA keeps the wrong
/// representation.
Variable _forwardedSuperParam(
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

BoundCall bindSuperParams(
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
  return BoundCall(
      positional: [for (final a in args) BoundArgument(a)],
      named: [
        for (final e in namedArgs.entries) (e.key, BoundArgument(e.value)),
      ],
      vectorOverride: ssa,
      returnType: CoreTypes.dynamic.ref(ctx),
    );
}

BoundCall bindSuperParamsBridge(
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
  return BoundCall(
      positional: [for (final a in args) BoundArgument(a)],
      named: [
        for (final e in namedArgs.entries) (e.key, BoundArgument(e.value)),
      ],
      vectorOverride: ssa,
      returnType: CoreTypes.dynamic.ref(ctx),
    );
}

/// Compile dynamic arguments in source evaluation order. Binding and default
/// insertion happen after runtime member lookup.
BoundCall bindDynamicVector(
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
        arg0.unmaterializedCallable != null) {
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
  return BoundCall(
      positional: [for (final a in args) BoundArgument(a)],
      named: [
        for (final e in namedArgs.entries) (e.key, BoundArgument(e.value)),
      ],
      vectorOverride: ssa,
      returnType: CoreTypes.dynamic.ref(ctx),
    );
}

BoundCall bindBridgeVector(
  ArgumentList argumentList,
  BridgeFunctionDef function, {
  List<Variable> before = const [],
  SuperParams superParams = const (positional: [], named: {}),
  Map<String, TypeRef> typeParameters = const {},
}) {
  final args = <Variable>[];
  final push = <Variable>[...before];
  final namedArgs = <String, Variable>{};

  final rawArguments = argumentList.arguments;
  final positional = function.params;
  final namedParamByName = {for (final p in function.namedParams) p.name: p};

  // **Match.** Positional arguments fill positional parameters in order,
  // skipping named arguments; named arguments bind by name and may
  // precede positional ones.
  final matchPositional = List<Expression?>.filled(positional.length, null);
  final matchNamed = <String, Expression>{};
  final argIndexToPositional = <int, int>{};
  final argIndexToNamed = <int, String>{};
  var positionalCursor = 0;
  for (var a = 0; a < rawArguments.length; a++) {
    final arg = rawArguments[a];
    if (arg is NamedArgument) {
      final name = arg.name.lexeme;
      if (!namedParamByName.containsKey(name) &&
          !superParams.named.contains(name)) {
        throw CompileError('Unknown named argument $name', arg);
      }
      matchNamed[name] = arg.argumentExpression;
      argIndexToNamed[a] = name;
      continue;
    }
    if (positionalCursor >= positional.length) {
      throw CompileError(
        'Too many positional arguments: ${positional.length} expected, '
        'but ${positionalCursor + 1} found.',
      );
    }
    matchPositional[positionalCursor] = arg.argumentExpression;
    argIndexToPositional[a] = positionalCursor;
    positionalCursor++;
  }

  Variable? $null;

  // Resolve the receiver's type arguments for every parameter annotation.
  // Simple refs (for example E in List.add) need them as much as generic
  // function types do; dropping them leaves the context type dynamic and
  // defeats argument conversion and reified checks.
  Variable compilePositional(BridgeParameter param, Expression expr) {
    final paramType = TypeRef.fromBridgeAnnotation(
      ctx,
      param.type,
      typeParameters: typeParameters,
    );
    var arg0 = compileExpression(expr, ctx, paramType);
    arg0 = arg0.boxIfNeeded(ctx);
    if (arg0.type.isFunctionLike && arg0.unmaterializedCallable != null) {
      arg0 = arg0.tearOff(ctx, boundContext: paramType);
    }
    // Bridge argument conversion lives on the runtime side of the typed
    // boundary (previously the compiler only boxed). Type parameters that
    // resolved through the receiver, nullable matches, and dynamic argument
    // shapes can carry distinct [TypeRef] identities for an equivalent
    // static type, so a failing compile-time [isAssignableTo] here must
    // defer to the boundary conversion instead of rejecting.
    return _providedBridgeArgument(ctx, arg0);
  }

  Variable compileNamedParam(BridgeParameter param, Expression expr) {
    final paramType = TypeRef.fromBridgeAnnotation(
      ctx,
      param.type,
      typeParameters: typeParameters,
    );
    var arg0 = compileExpression(expr, ctx, paramType).boxIfNeeded(ctx);
    if (arg0.type.isFunctionLike && arg0.unmaterializedCallable != null) {
      arg0 = arg0.tearOff(ctx, boundContext: paramType);
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
    return _providedBridgeArgument(ctx, arg0);
  }

  // **Compile** supplied arguments in source order.
  final compiledPositional = List<Variable?>.filled(positional.length, null);
  final compiledNamed = <String, Variable>{};
  for (var a = 0; a < rawArguments.length; a++) {
    final pi = argIndexToPositional[a];
    if (pi != null) {
      compiledPositional[pi] = compilePositional(
        positional[pi],
        matchPositional[pi]!,
      );
      continue;
    }
    final name = argIndexToNamed[a];
    // Named arguments that reach a forwarded super parameter are dropped:
    // the parameter binds the constructor's local instead.
    if (name != null &&
        namedParamByName.containsKey(name) &&
        !superParams.named.contains(name)) {
      compiledNamed[name] = compileNamedParam(
        namedParamByName[name]!,
        matchNamed[name]!,
      );
    }
  }

  // **Emit** the flattened vector in declaration order.
  for (var pi = 0; pi < positional.length; pi++) {
    final param = positional[pi];
    if (pi < superParams.positional.length) {
      final V = _providedBridgeArgument(
        ctx,
        ctx.lookupLocal(superParams.positional[pi])!,
      );
      push.add(V);
      args.add(V);
      continue;
    }
    final compiled = compiledPositional[pi];
    if (compiled != null) {
      args.add(compiled);
      push.add(compiled);
      continue;
    }
    if (!param.optional) {
      throw CompileError('Not enough positional arguments');
    }
    $null ??= BuiltinValue().push(ctx);
    push.add($null);
  }

  for (final param in function.namedParams) {
    if (superParams.named.contains(param.name)) {
      final V = _providedBridgeArgument(ctx, ctx.lookupLocal(param.name)!);
      push.add(V);
      namedArgs[param.name] = V;
      continue;
    }
    final compiled = compiledNamed[param.name];
    if (compiled != null) {
      push.add(compiled);
      namedArgs[param.name] = compiled;
      continue;
    }
    $null ??= BuiltinValue().push(ctx);
    push.add($null);
  }

  return BoundCall(
      positional: [for (final a in args) BoundArgument(a)],
      named: [
        for (final e in namedArgs.entries) (e.key, BoundArgument(e.value)),
      ],
      vectorOverride: push.map((argument) => argument.ssa).toList(),
      returnType: CoreTypes.dynamic.ref(ctx),
    );
}


void _resolveInvocationGenerics(
  int declarationLibrary,
  List<TypeParameter>? parameters,
  List<TypeAnnotation>? explicitArguments,
  Map<String, TypeRef> resolved,
  AstNode source, {
  required Declaration dec,
}) {
  if (parameters == null || parameters.isEmpty) {
    if (explicitArguments?.isNotEmpty ?? false) {
      throw CompileError('Function does not declare type parameters', source);
    }
    return;
  }
  if (explicitArguments != null &&
      explicitArguments.length != parameters.length) {
    throw CompileError(
      'Expected ${parameters.length} type arguments, '
      'but found ${explicitArguments.length}',
      source,
    );
  }
  // Seed every parameter name before resolving bounds so F-bounds can
  // self-reference (`f<T extends Foo<T>>(...)`). The owner carries the
  // callee's identity — call-site placeholders for `foo<T>` and `bar<U>`
  // in the same library are distinct parameters.
  final callOwner = _callSiteOwner(declarationLibrary, dec);
  for (var index = 0; index < parameters.length; index++) {
    final name = parameters[index].name.lexeme;
    resolved[name] = TypeParameterTypeRef(
      TypeParameterDef(callOwner, index, name),
      file: declarationLibrary,
    );
  }
  for (var index = 0; index < parameters.length; index++) {
    final parameter = parameters[index];
    final name = parameter.name.lexeme;
    final boundAnnotation = parameter.bound;
    final bound = boundAnnotation == null
        ? CoreTypes.dynamic.ref(ctx)
        : TypeRef.fromAnnotation(
            ctx,
            declarationLibrary,
            boundAnnotation,
            typeParameters: resolved,
          );
    if (explicitArguments == null) {
      resolved[name] = bound;
      continue;
    }
    final argument = TypeRef.fromAnnotation(
      ctx,
      ctx.library,
      explicitArguments[index],
    );
    // The bound may self-reference (`T extends Generator<T>`); substitute
    // the actual argument before checking assignability.
    final substitutedBound = bound.substituteTypeParameters(
      Substitution.of({(resolved[name]! as TypeParameterTypeRef).parameter: argument}),
    );
    if (!argument.isSpec(CoreTypes.dynamic) &&
        !substitutedBound.isSpec(CoreTypes.dynamic) &&
        !argument.isAssignableTo(
          ctx,
          substitutedBound,
          forceAllowDynamic: false,
        )) {
      throw CompileError(
        'Type argument $argument does not satisfy the bound $bound of $name',
        source,
      );
    }
    resolved[name] = argument;
  }
}


bool _annotationUsesTypeParameters(
  TypeAnnotation annotation,
  Map<String, TypeRef> parameters,
) {
  if (annotation is NamedType) {
    if (parameters.containsKey(annotation.name.lexeme)) return true;
    return annotation.typeArguments?.arguments.any(
          (argument) => _annotationUsesTypeParameters(argument, parameters),
        ) ??
        false;
  }
  return annotation.childEntities.whereType<TypeAnnotation>().any(
    (child) => _annotationUsesTypeParameters(child, parameters),
  );
}

/// Positional argument count of a method invocation, for disambiguating
/// extension members that differ only by arity (`operator -`).
/// The callable signature of a function/method/constructor declaration:
/// (formal parameters, declared type parameters, declared return type).
(List<FormalParameter>, List<TypeParameter>?, TypeAnnotation?)
_invocationSignature(Declaration dec) => switch (dec) {
  FunctionDeclaration() => (
    dec.functionExpression.parameters?.parameters ?? <FormalParameter>[],
    dec.functionExpression.typeParameters?.typeParameters,
    dec.returnType,
  ),
  MethodDeclaration() => (
    dec.parameters?.parameters ?? <FormalParameter>[],
    dec.typeParameters?.typeParameters,
    dec.returnType,
  ),
  ConstructorDeclaration() => (dec.parameters.parameters, null, null),
  _ => throw CompileError('Invalid declaration type ${dec.runtimeType}'),
};


TypeParameterOwner _callSiteOwner(int library, Declaration dec) {
  final host = switch (dec) {
    MethodDeclaration() => dec.parent?.parent,
    ConstructorDeclaration() => dec.parent?.parent,
    _ => null,
  };
  final prefix = host is Declaration ? '${declarationName(host)}.' : '';
  final name = switch (dec) {
    FunctionDeclaration() => dec.name.lexeme,
    MethodDeclaration() => dec.name.lexeme,
    ConstructorDeclaration() => dec.name?.lexeme ?? '',
    _ => '',
  };
  final position = switch (dec) {
    FunctionDeclaration() => dec.functionExpression.offset,
    _ => dec.offset,
  };
  return TypeParameterOwner(
    TypeParameterOwnerKind.callSite,
    library,
    '$prefix$name',
    position,
  );
}

/// Compiles the argument list for a call to a non-bridge declaration [dec],
/// resolving generic type parameters at the call site. [seedGenerics] provides
/// receiver-class type arguments (for instance calls); [typeArguments] are the
/// call's explicit type arguments, whose presence disables inference.
BoundCall bindDeclaration(
  int sourceLib,
  Declaration dec,
  ArgumentList argumentList, {
  List<Variable> before = const [],
  TypeArgumentList? typeArguments,
  AstNode? source,
  Map<String, TypeRef> seedGenerics = const {},
  // Skips this many leading positional arguments (explicit extension
  // application `E.m(receiver, ...)` carries the receiver in the list).
  int argIndexOffset = 0,

  /// The expression's context type. Method type parameters left unconstrained
  /// by argument inference are bound from the declared return type matched
  /// against it (`x.cast()` under `C<bool>` binds `U` to `bool`).
  TypeRef? returnContext,
  /// See [bindParameterList.fillOmitted].
  bool fillOmitted = true,
}) {
  final (fpl, typeParams, returnAnnotation) = _invocationSignature(dec);
  final isCallableDecl = dec is FunctionDeclaration || dec is MethodDeclaration;
  final resolveGenerics = <String, TypeRef>{...seedGenerics};
  List<TypeParameter>? classParams;
  if (dec is ConstructorDeclaration) {
    // Constructor signatures reference the declaring class's type parameters;
    // seed them from the call's explicit type arguments (or bounds).
    final owner = dec.thisOrAncestorMatching(
      (node) =>
          node is ClassDeclaration ||
          node is MixinDeclaration ||
          node is ClassTypeAlias,
    );
    classParams = switch (owner) {
      ClassDeclaration() || MixinDeclaration() || ClassTypeAlias() =>
        classLikeClauses(owner as Declaration).$4?.typeParameters,
      _ => null,
    };
    if (classParams != null) {
      final explicitArgs = typeArguments?.arguments;
      for (var i = 0; i < classParams.length; i++) {
        final bound = classParams[i].bound;
        resolveGenerics[classParams[i].name.lexeme] =
            explicitArgs != null && i < explicitArgs.length
            ? TypeRef.fromAnnotation(ctx, sourceLib, explicitArgs[i])
            : bound == null
            ? CoreTypes.dynamic.ref(ctx)
            : TypeRef.fromAnnotation(
                ctx,
                sourceLib,
                bound,
                typeParameters: resolveGenerics,
              );
      }
    }
  }
  if (isCallableDecl) {
    _resolveInvocationGenerics(
      sourceLib,
      typeParams,
      typeArguments?.arguments.toList(),
      resolveGenerics,
      source!,
      dec: dec,
    );
  }

  bool? boxedBySubstitution;
  if (returnAnnotation != null &&
      _annotationUsesTypeParameters(returnAnnotation, resolveGenerics)) {
    // Substitution narrows the language type, not the compiled callee's ABI.
    boxedBySubstitution = true;
  }

  // Snapshot the pre-inference bindings: entries still identical after the
  // argument list compiles were never constrained by the arguments.
  final unboundGenerics = Map<String, TypeRef>.of(resolveGenerics);
  final argsPair = bindParameterList(
    argumentList,
    sourceLib,
    fpl,
    dec,
    before: before,
    source: source,
    argIndexOffset: argIndexOffset,
    resolveGenerics: resolveGenerics,
    // Only function/method declarations take explicit type arguments at the
    // call site; constructor calls infer regardless (e.g. List<int>() still
    // infers the constructor's own generics).
    inferGenerics: !isCallableDecl || typeArguments == null,
    fillOmitted: fillOmitted,
  );

  // Downward inference: parameters untouched by argument inference bind
  // from the declared return type matched against the context type.
  if (returnContext != null &&
      typeArguments == null &&
      typeParams != null &&
      returnAnnotation != null) {
    final callOwner = _callSiteOwner(sourceLib, dec);
    final placeholders = <String, TypeRef>{
      for (var i = 0; i < typeParams.length; i++)
        typeParams[i].name.lexeme: TypeParameterTypeRef(
          TypeParameterDef(callOwner, i, typeParams[i].name.lexeme),
          file: sourceLib,
        ),
    };
    final pattern = TypeRef.fromAnnotation(
      ctx,
      sourceLib,
      returnAnnotation,
      typeParameters: placeholders,
    );
    final bindings = <TypeParameterDef, TypeRef>{};
    ctx.typeSystem.unify(pattern, returnContext, bindings);
    for (var i = 0; i < typeParams.length; i++) {
      final name = typeParams[i].name.lexeme;
      if (!identical(resolveGenerics[name], unboundGenerics[name])) continue;
      final bound = bindings[(placeholders[name]! as TypeParameterTypeRef).parameter];
      if (bound != null) resolveGenerics[name] = bound;
    }
  }

  TypeRef? returnType;
  if (returnAnnotation != null && resolveGenerics.isNotEmpty) {
    returnType = TypeRef.fromAnnotation(
      ctx,
      sourceLib,
      returnAnnotation,
      typeParameters: resolveGenerics,
    );
  }
  // Inferred type arguments materialize into the emitted call's runtime
  // type-argument list, in the callee's declaration order. A parameter
  // nothing constrained stays a call-site placeholder and degrades to
  // `dynamic`, as before.
  final inferredRuntimeTypeArguments = isCallableDecl &&
          typeArguments == null &&
          typeParams != null
      ? [
          for (final p in typeParams)
            () {
              final t = resolveGenerics[p.name.lexeme];
              return t == null || t.isTypeParameter
                  ? ctx.runtimeTypes.idOf(CoreTypes.dynamic.ref(ctx))
                  : ctx.runtimeTypes.idOf(t);
            }(),
        ]
      : const <int>[];
  return BoundCall(
    positional: argsPair.positional,
    named: argsPair.named,
    vectorOverride: argsPair.vector(),
    returnType: returnType ?? CoreTypes.dynamic.ref(ctx),
    declaredReturn: returnType,
    typeArguments: resolveGenerics,
    runtimeTypeArguments: inferredRuntimeTypeArguments,
    genericReturnBoxed: boxedBySubstitution,
    classTypeParameters: classParams,
  );
}
}

/// Resolves the result type of calling a function-typed value with the
/// given argument types, or null when it can't be determined.
///
/// A statically dispatched [dispatch] signature wins over the [callee]'s
/// own callable metadata (tear-off `methodSignature`), and both win over
/// the callee's declared function type. A resolved `void` result is
/// unusable as a value, so null is returned and callers fall back to
/// dynamic — preserving the permissive semantics of consuming the runtime
/// result anyway.
TypeRef? callResultType(
  CompilerContext ctx, {
  required Variable? callee,
  required DirectCall? dispatch,
  required List<TypeRef> argTypes,
  required Map<String, TypeRef> namedArgTypes,
}) {
  final voidType = CoreTypes.voidType.ref(ctx);
  final signature = dispatch?.signature ?? callee?.methodSignature;
  if (signature != null) {
    final resolved = resolveCallResultType(
      ctx,
      signature: signature,
      targetType: dispatch == null ? callee?.type : null,
      argTypes: argTypes,
      namedArgTypes: namedArgTypes,
    );
    if (resolved != null) return resolved;
  }
  final calleeType = callee?.type;
  final declared =
      calleeType is FunctionTypeRef ? calleeType.signature.returnType : null;
  return declared == voidType ? null : declared;
}

/// Resolves a call's result type from [signature]: applies
/// [CallSignature.returnOverride] when the dependency's watched argument
/// type matches a case, otherwise substitutes [targetType]'s applied
/// arguments into the declared return type and lowers any remaining
/// (never-bound) callee type parameters to their bounds. A `void` result
/// is unusable as a value — null is returned so callers fall back.
TypeRef? resolveCallResultType(
  CompilerContext ctx, {
  required CallSignature signature,
  required TypeRef? targetType,
  required List<TypeRef> argTypes,
  required Map<String, TypeRef> namedArgTypes,
}) {
  final voidType = CoreTypes.voidType.ref(ctx);
  final overridden = signature.returnOverride?.call(argTypes, namedArgTypes);
  if (overridden != null) {
    return overridden == voidType ? null : overridden;
  }
  var resolved = signature.returnType;
  final targetSubs = targetType == null
      ? null
      : ctx.typeSystem.appliedArguments(targetType);
  if (targetSubs != null && targetSubs.isNotEmpty) {
    resolved = resolved.substituteTypeParameters(targetSubs);
  }
  resolved = resolved.lowerTypeParameters(ctx);
  return resolved == voidType ? null : resolved;
}

/// Whether the runtime can skip per-argument checks for a closure
/// invocation: every supplied argument provably assignable to the closure's
/// static signature without a runtime check.
bool _closureArgumentsProven(
  CompilerContext ctx,
  TypeRef? closureType,
  List<Variable> positionalArgs,
  Map<String, Variable> namedArgs,
) {
  if (closureType is! FunctionTypeRef) return false;
  final signature = closureType.signature;
  final positional = signature.positional;
  for (var i = 0; i < positionalArgs.length; i++) {
    if (i >= positional.length) return false;
    final paramType = positional[i];
    if (paramType.isSpec(CoreTypes.dynamic) ||
        positionalArgs[i].type.assignmentConversionTo(ctx, paramType) !=
            AssignmentConversion.none) {
      return false;
    }
  }
  for (final entry in namedArgs.entries) {
    final parameter = signature.named[entry.key];
    if (parameter == null ||
        parameter.type.isSpec(CoreTypes.dynamic) ||
        entry.value.type.assignmentConversionTo(ctx, parameter.type) !=
            AssignmentConversion.none) {
      return false;
    }
  }
  return true;
}

/// The result type of calling [method] on a receiver typed [type] — the
/// resolved member's signature with the receiver's type arguments applied —
/// or null when the member is a field or bridge without a function shape.
/// Callers fall back to `dynamic` on null, matching the permissive legacy
/// semantics for unresolvable returns.
TypeRef? memberCallResultType(
  CompilerContext ctx,
  TypeRef type,
  String method,
  List<TypeRef> argTypes,
  Map<String, TypeRef> namedArgTypes, {
  bool $static = false,
  AstNode? source,
}) {
  final lookupType = ctx.typeSystem.throughTypeParameters(type);
  if (lookupType.isSpec(CoreTypes.dynamic)) {
    return CoreTypes.dynamic.ref(ctx);
  }
  if ($static) {
    final member =
        ctx.memberLookup.staticMember(lookupType, method, MemberKind.method) ??
        (throw CompileError('Cannot find static method $lookupType.$method'));
    if (member is BridgeMember) {
      final fd = switch (member.def) {
        BridgeMethodDef(:final functionDescriptor) => functionDescriptor,
        BridgeConstructorDef(:final functionDescriptor) => functionDescriptor,
        _ => null,
      };
      if (fd == null) return CoreTypes.dynamic.ref(ctx);
      return resolveCallResultType(
        ctx,
        signature: CallSignature.bridge(
          ctx,
          fd,
          returnFallback: CoreTypes.dynamic.ref(ctx),
          owner: lookupType,
        ),
        targetType: lookupType,
        argTypes: argTypes,
        namedArgTypes: namedArgTypes,
      );
    }
    final node = (member as SourceMember).node;
    if (node is ConstructorDeclaration) return lookupType;
    return member.signature.returnType;
  }
  if (method == 'noSuchMethod') {
    // `Object.noSuchMethod` is implicit — absent from declaration metadata.
    return CoreTypes.dynamic.ref(ctx);
  }
  final resolved = ctx.memberLookup.interfaceMember(
    lookupType,
    ctx.memberNameOf(method, MemberKind.method),
    source: source,
    superclassFirst: true,
  );
  if (resolved.member is BridgeMember) {
    final fd = switch ((resolved.member as BridgeMember).def) {
      BridgeMethodDef(:final functionDescriptor) => functionDescriptor,
      BridgeConstructorDef(:final functionDescriptor) => functionDescriptor,
      _ => null,
    };
    if (fd == null) return CoreTypes.dynamic.ref(ctx);
    return resolveCallResultType(
      ctx,
      signature: CallSignature.bridge(
        ctx,
        fd,
        returnFallback: CoreTypes.dynamic.ref(ctx),
        owner: lookupType,
      ),
      targetType: lookupType,
      argTypes: argTypes,
      namedArgTypes: namedArgTypes,
    );
  }
  final node = (resolved.member as SourceMember).node;
  if (node is! MethodDeclaration) {
    // A field holding a callable — its call signature isn't modelled here.
    return CoreTypes.dynamic.ref(ctx);
  }
  return resolved.signature.returnType;
}
