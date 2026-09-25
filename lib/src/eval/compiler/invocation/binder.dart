import 'package:control_flow_graph/control_flow_graph.dart' show Assign;
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import '../builtins.dart';
import '../errors.dart';
import '../member/call_signature.dart';
import '../member/member.dart';
import '../member/resolved_member.dart';
import '../member/member_name.dart';
import '../helpers/argument_list.dart';
import '../../ir/bridge.dart' show PrepareBridgeArgument;
import 'bound_call.dart';
import 'call.dart';
import 'targets.dart';

typedef _MatchedArgument = ({int? positional, String? named, ArgSource source});
typedef _ArgumentValues = ({
  List<Variable?> positional,
  List<(String, Variable)> named,
});

/// Maps a [CallSite]'s argument shape onto a [CallTarget]'s signature:
/// match, seed the substitution, compile and coerce, solve inference, fill
/// omitted arguments per the target's policy.
final class ArgumentBinder {
  const ArgumentBinder(this.ctx);

  final CompilerContext ctx;

  /// Validate the shape before compiling any expression, then retain source
  /// order for evaluation. The source and bridge ABIs use the same matching
  /// rules; only their conversion and omitted-value rules differ.
  List<_MatchedArgument> _matchArguments(
    CallShape shape,
    int positionalCount,
    Set<String> namedParameters, {
    int positionalOffset = 0,
    int sourceOffset = 0,
    Set<String> forwardedNamed = const {},
    AstNode? errorSource,
  }) {
    final matched = <_MatchedArgument>[];
    var positionalCursor = positionalOffset;
    for (final index in shape.sourceOrder.skip(sourceOffset)) {
      if (index < 0) {
        final (name, source) = shape.named[-1 - index];
        final argumentNode =
            source is ExpressionArg && source.expression.parent is NamedArgument
            ? source.expression.parent
            : errorSource;
        if (forwardedNamed.contains(name)) {
          throw CompileError(
            'Named super argument $name is already forwarded',
            argumentNode,
          );
        }
        if (!namedParameters.contains(name)) {
          throw CompileError('Unknown named argument $name', argumentNode);
        }
        matched.add((positional: null, named: name, source: source));
      } else {
        if (positionalCursor >= positionalCount) {
          throw CompileError(
            'Too many positional arguments: $positionalCount expected, '
            'but ${positionalCursor + 1} found.',
            errorSource,
          );
        }
        matched.add((
          positional: positionalCursor++,
          named: null,
          source: shape.positional[index],
        ));
      }
    }
    return matched;
  }

  _ArgumentValues _evaluateArguments(
    List<_MatchedArgument> matched,
    int positionalCount,
    Variable Function(_MatchedArgument) compile,
  ) {
    final positional = List<Variable?>.filled(positionalCount, null);
    final named = <(String, Variable)>[];
    for (final argument in matched) {
      final value = compile(argument);
      if (argument.positional case final index?) {
        positional[index] = value;
      } else {
        named.add((argument.named!, value));
      }
    }
    return (positional: positional, named: named);
  }

  /// Assemble declaration order only after all supplied expressions ran.
  /// Bridge padding enters the vector but is not a supplied argument.
  BoundCall _finishArguments(
    CallSignature signature,
    _ArgumentValues values, {
    required List<Variable> before,
    required SuperParams superParams,
    required Variable Function(ParameterSpec, String) forward,
    required Variable? Function(ParameterSpec) omitted,
    bool includeOmitted = true,
  }) {
    final positional = <Variable>[];
    final named = <(String, Variable)>[];
    final vector = [for (final value in before) value.ssa];
    void add(ParameterSpec spec, Variable? supplied, {bool isNamed = false}) {
      if (supplied == null && spec.isRequired) {
        throw CompileError(
          isNamed
              ? 'Missing required named argument ${spec.name}'
              : 'Not enough positional arguments',
        );
      }
      final value = supplied ?? omitted(spec);
      if (value == null) return;
      vector.add(value.ssa);
      if (supplied != null || includeOmitted) {
        if (isNamed) {
          named.add((spec.name, value));
        } else {
          positional.add(value);
        }
      }
    }

    for (var i = 0; i < signature.positional.length; i++) {
      final spec = signature.positional[i];
      add(
        spec,
        i < superParams.positional.length
            ? forward(spec, superParams.positional[i])
            : values.positional[i],
      );
    }
    final namedValues = {for (final (name, value) in values.named) name: value};
    for (final spec in signature.named) {
      add(
        spec,
        superParams.named.contains(spec.name)
            ? forward(spec, spec.name)
            : namedValues[spec.name],
        isNamed: true,
      );
    }
    return BoundCall(
      positional: positional,
      named: named,
      vectorOverride: vector,
      returnType: CoreTypes.dynamic.ref(ctx),
    );
  }

  /// `calleeBinds` — supplied arguments only. Each argument is captured as
  /// it is evaluated, before a later argument can assign to its local slot.
  BoundCall bindSuppliedOnly(
    CallTarget target,
    CallSite site, {
    required Variable? callee,
  }) {
    // The callee is materialized before any argument compiles — an
    // argument may redefine the SSA slot the callee expression read
    // (`f(f = g())` invokes the old `f`).
    Variable? materializedCallee;
    if (callee != null && !(target is ClosureCall && target.known != null)) {
      final boxed = callee.boxed ? callee : callee.boxIntoFreshSlot(ctx);
      materializedCallee = Variable.ssa(
        ctx,
        Assign(ctx.svar('closure_target'), boxed.ssa),
        boxed.type,
        rep: boxed.rep,
      );
    }

    final declaredSignature = callee?.type is FunctionTypeRef
        ? (callee!.type as FunctionTypeRef).signature
        : null;
    final suppliedTypeArguments = [
      for (final annotation
          in site.shape.typeArguments ?? const <TypeAnnotation>[])
        TypeRef.fromAnnotation(ctx, ctx.library, annotation),
    ];
    if (declaredSignature != null &&
        site.shape.typeArguments != null &&
        suppliedTypeArguments.length !=
            declaredSignature.typeParameters.length) {
      throw CompileError(
        'Expected ${declaredSignature.typeParameters.length} type arguments, '
        'but found ${suppliedTypeArguments.length}',
        site.source,
      );
    }
    final substitutions =
        declaredSignature == null || site.shape.typeArguments == null
        ? Substitution.empty
        : Substitution.of({
            for (var i = 0; i < declaredSignature.typeParameters.length; i++)
              declaredSignature.typeParameters[i]: suppliedTypeArguments[i],
          });
    final ownParameters =
        declaredSignature?.typeParameters.toSet() ?? const <TypeParameterDef>{};
    final inferredArguments = <TypeParameterDef, Set<TypeRef>>{};
    TypeRef formalType(TypeRef type) {
      final instantiated = type.substituteTypeParameters(substitutions);
      return declaredSignature != null &&
              site.shape.typeArguments == null &&
              _usesParameter(instantiated, ownParameters)
          ? instantiated.lowerTypeParameters(ctx, only: ownParameters)
          : instantiated;
    }

    if (declaredSignature != null) {
      if (site.shape.positional.length > declaredSignature.positional.length) {
        throw CompileError('Too many positional arguments', site.source);
      }
      if (site.shape.positional.length < declaredSignature.requiredPositional) {
        throw CompileError('Not enough positional arguments', site.source);
      }
      final suppliedNames = <String>{};
      for (final (name, _) in site.shape.named) {
        if (!declaredSignature.named.containsKey(name)) {
          throw CompileError('Unknown named argument $name', site.source);
        }
        suppliedNames.add(name);
      }
      for (final entry in declaredSignature.named.entries) {
        if (entry.value.required && !suppliedNames.contains(entry.key)) {
          throw CompileError(
            'Missing required argument ${entry.key}',
            site.source,
          );
        }
      }
    }

    Variable bindArgument(ArgSource source, TypeRef? declaredType) {
      final parameterType = declaredType == null
          ? null
          : formalType(declaredType);
      var argument = _compileArg(ctx, source, parameterType);
      if (declaredType != null &&
          site.shape.typeArguments == null &&
          ownParameters.isNotEmpty) {
        _inferArgument(
          declaredType,
          argument.type,
          ownParameters,
          inferredArguments,
        );
      }
      if (parameterType != null) {
        argument = convertForAssignment(
          ctx,
          argument,
          parameterType,
          representation: MachineRepresentation.object,
          source: site.source,
        );
      }
      return argument
          .copyIntoFreshSlot(ctx, 'closure_argument')
          .boxIfNeeded(ctx);
    }

    final matched = _matchArguments(site.shape, site.shape.positional.length, {
      for (final (name, _) in site.shape.named) name,
    }, errorSource: site.source);
    final values = _evaluateArguments(
      matched,
      site.shape.positional.length,
      (argument) => bindArgument(
        argument.source,
        argument.positional == null
            ? declaredSignature?.named[argument.named]?.type
            : declaredSignature?.positional[argument.positional!],
      ),
    );
    final positionalArgs = values.positional.cast<Variable>();
    final namedArgs = values.named;

    final inferredSubstitutions = <TypeParameterDef, TypeRef>{};
    if (declaredSignature != null && site.shape.typeArguments == null) {
      inferredSubstitutions.addAll(_solveArguments(inferredArguments));
      if (site.context != null &&
          inferredSubstitutions.length < ownParameters.length) {
        final bindings = <TypeParameterDef, TypeRef>{};
        ctx.typeSystem.unify(
          declaredSignature.returnType.substituteTypeParameters(
            Substitution.of(inferredSubstitutions),
          ),
          site.context!,
          bindings,
        );
        for (final parameter in declaredSignature.typeParameters) {
          if (!inferredSubstitutions.containsKey(parameter) &&
              bindings[parameter] != null) {
            inferredSubstitutions[parameter] = bindings[parameter]!;
          }
        }
      }
      for (final parameter in declaredSignature.typeParameters) {
        inferredSubstitutions.putIfAbsent(
          parameter,
          () => (parameter.bound ?? CoreTypes.dynamic.ref(ctx))
              .substituteTypeParameters(Substitution.of(inferredSubstitutions))
              .lowerTypeParameters(ctx),
        );
      }
    }
    final resolvedSubstitutions = site.shape.typeArguments == null
        ? Substitution.of(inferredSubstitutions)
        : substitutions;
    final runtimeTypeArguments = [
      for (final type
          in site.shape.typeArguments == null && declaredSignature != null
              ? [
                  for (final parameter in declaredSignature.typeParameters)
                    inferredSubstitutions[parameter]!,
                ]
              : suppliedTypeArguments)
        ctx.runtimeTypes.idOf(type),
    ];

    final dispatch = target is ClosureCall ? target.known : null;
    final argTypes = [for (final a in positionalArgs) a.type];
    final namedArgTypes = {for (final e in namedArgs) e.$1: e.$2.type};
    final inferredReturn =
        declaredSignature != null &&
            _usesParameter(declaredSignature.returnType, ownParameters)
        ? declaredSignature.returnType.substituteTypeParameters(
            resolvedSubstitutions,
          )
        : null;
    final inferredResult =
        inferredReturn?.lowerTypeParameters(ctx, only: ownParameters);
    final resultType =
        (inferredResult != null && !inferredResult.isSpec(CoreTypes.voidType)
            ? inferredResult
            : null) ??
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
      trusted: _closureArgumentsProven(ctx, callee?.type, positionalArgs, {
        for (final e in namedArgs) e.$1: e.$2,
      }),
    );
  }

  Variable _compileArg(
    CompilerContext ctx,
    ArgSource source, [
    TypeRef? bound,
  ]) {
    return switch (source) {
      ExpressionArg(:final expression) => compileExpression(
        expression,
        ctx,
        bound,
      ),
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

  /// Binds an argument list against a [CallSignature]: the signature owns
  /// the callee's shape and resolved types. A null [argumentList] is an
  /// implicit super call with only forwarded locals and omitted defaults.
  BoundCall bindParameterList(
    ArgumentList? argumentList,
    int decLibrary,
    CallSignature signature,
    Declaration parameterHost, {
    CallShape? suppliedShape,
    List<Variable> before = const [],
    Map<TypeParameterDef, TypeRef> resolveGenerics = const {},
    Set<TypeParameterDef>? constrainedParameters,
    bool inferGenerics = true,
    Set<String>? inferParameterNames,
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
        final redirected = CallSignature.forDeclaration(
          ctx,
          decLibrary,
          targetDecl,
        );
        signature = redirected.substitute(
          redirected.substitutionFor(signature.typeParameterRefs),
        );
        parameterHost = targetDecl;
      }
    }

    final positional = signature.positional;
    final named = {for (final spec in signature.named) spec.name: spec};

    // The signature resolved formal annotations in the declaring scope. Bind
    // those exact parameter identities to the call's receiver and type args;
    // resolving AST annotations again here can pick a different scope.
    final parameterDefs = {
      for (final entry in signature.typeParameterRefs.entries)
        if (entry.value case TypeParameterTypeRef(:final parameter)
            when inferParameterNames == null ||
                inferParameterNames.contains(entry.key))
          parameter,
    };
    final argumentSubstitution = Substitution.of(resolveGenerics);
    final candidates = <TypeParameterDef, Set<TypeRef>>{};

    // Compiles or reads the supplied argument for [spec]: context typing,
    // coercion to the formal, and generic-inference recording.
    Variable compileMatched(ParameterSpec spec, ArgSource argument) {
      final param = spec.node!;
      final paramType = spec.type.substituteTypeParameters(
        argumentSubstitution,
      );

      // The placeholder-rich parameter shape used for deep generic
      // inference: built before argument compilation so context-sensitive
      // arguments (closures, generic tear-offs) see the generic form
      // rather than the erased formal type.
      TypeRef? unifyPattern;
      if (inferGenerics && parameterDefs.isNotEmpty) {
        unifyPattern = spec.type;
      }

      // A formal that still holds an unbound type parameter erases to its
      // bound (or `dynamic`): the erased boundary accepts whatever the
      // inferred type argument becomes — e.g. `typedef T<X> = C<X>` invoked
      // as `T(1)` leaves `C`'s parameters bound to `T.X` until inference.
      final coercionType = paramType.requiresTypeEnvironment
          ? paramType.lowerTypeParameters(ctx)
          : paramType;
      // The placeholder-rich shape only serves as context for function-typed
      // parameters — collection literals need the erased formal so their
      // element types stay unconstrained until unification.
      final argBound = unifyPattern is FunctionTypeRef
          ? unifyPattern
          : coercionType;
      var arg0 = _compileArg(ctx, argument, argBound);
      if (unifyPattern != null) {
        // Inference reads the argument's own type — coercion below may
        // erase still-unbound parameters to `dynamic`, which would record
        // `T -> dynamic` instead of the actual constraint.
        _inferArgument(unifyPattern, arg0.type, parameterDefs, candidates);
      }
      arg0 = coerceArgumentForParameter(
        ctx,
        arg0,
        coercionType,
        param,
        parameterHost,
        genericParameter: spec.erased,
        source: source,
      );
      // A following source expression can assign to the local slot that
      // produced this value. Already-compiled operands were captured by the
      // caller before target resolution.
      return argument is ExpressionArg
          ? arg0.copyIntoFreshSlot(ctx, 'source_argument')
          : arg0;
    }

    final shape =
        suppliedShape ??
        (argumentList == null
            ? CallShape.values(const [])
            : CallShape.fromArgumentList(argumentList));
    if (superParams.positional.isNotEmpty && shape.positional.isNotEmpty) {
      throw CompileError(
        'Positional super parameters cannot be combined with positional super arguments',
        source ?? argumentList,
      );
    }
    final matched = _matchArguments(
      shape,
      positional.length,
      named.keys.toSet(),
      positionalOffset: superParams.positional.length,
      sourceOffset: argIndexOffset,
      forwardedNamed: superParams.named,
      errorSource: source,
    );
    final suppliedNames = {
      for (final argument in matched)
        if (argument.named case final String name) name,
    };
    for (final spec in signature.named) {
      if (spec.isRequired &&
          !suppliedNames.contains(spec.name) &&
          !superParams.named.contains(spec.name)) {
        throw CompileError('Missing required argument ${spec.name}', spec.node);
      }
    }

    final values = _evaluateArguments(matched, positional.length, (argument) {
      final index = argument.positional;
      final spec = index == null ? named[argument.named]! : positional[index];
      return compileMatched(spec, argument.source);
    });
    final result = _finishArguments(
      signature,
      values,
      before: before,
      superParams: superParams,
      forward: (spec, name) => _forwardedSuperParam(
        spec,
        parameterHost,
        name,
        substitution: argumentSubstitution,
        source: source,
      ),
      omitted: (spec) => fillOmitted
          ? compileOmittedArgument(
              ctx,
              spec,
              parameterHost,
              spec.type.substituteTypeParameters(argumentSubstitution),
            )
          : null,
    );

    if (inferGenerics && candidates.isNotEmpty) {
      resolveGenerics.addAll(_solveArguments(candidates));
      constrainedParameters?.addAll(candidates.keys);
    }

    return result;
  }

  /// The value a `super` parameter forwards to the callee: the caller's local
  /// [localName] coerced to the callee [param]'s boundary representation.
  /// Locals may have been boxed for field storage while the callee takes them
  /// unboxed, or vice versa — without the coercion the SSA keeps the wrong
  /// representation.
  Variable _forwardedSuperParam(
    ParameterSpec spec,
    Declaration parameterHost,
    String localName, {
    Substitution substitution = Substitution.empty,
    AstNode? source,
  }) {
    final paramType = spec.type.substituteTypeParameters(substitution);
    return coerceArgumentForParameter(
      ctx,
      ctx.lookupLocal(localName)!,
      paramType,
      spec.node!,
      parameterHost,
      genericParameter: spec.erased,
      source: source,
    );
  }

  BoundCall bindBridgeVector(
    ArgumentList? argumentList,
    BridgeFunctionDef function, {
    List<Variable> before = const [],
    SuperParams superParams = const (positional: [], named: {}),
    Map<String, TypeRef> typeParameters = const {},
    CallSignature? targetSignature,
  }) {
    final signature =
        targetSignature ??
        CallSignature.bridge(
          ctx,
          function,
          returnFallback: CoreTypes.dynamic.ref(ctx),
          typeParameters: typeParameters,
        );
    final positional = signature.positional;
    final namedParamByName = {
      for (final spec in signature.named) spec.name: spec,
    };
    final shape = argumentList == null
        ? CallShape.values(const [])
        : CallShape.fromArgumentList(argumentList);
    if (superParams.positional.isNotEmpty && shape.positional.isNotEmpty) {
      throw CompileError(
        'Positional super parameters cannot be combined with positional super arguments',
        argumentList,
      );
    }
    final matched = _matchArguments(
      shape,
      positional.length,
      namedParamByName.keys.toSet(),
      forwardedNamed: superParams.named,
      errorSource: argumentList,
    );

    // Resolve the receiver's type arguments for every parameter annotation.
    // Bridge positional arguments defer assignment checks to the runtime;
    // named arguments retain the existing static conversion rule.
    Variable compileMatchedBridge(
      ParameterSpec param,
      ArgSource argument, {
      required bool named,
    }) {
      final paramType = param.type;
      var arg0 = _compileArg(ctx, argument, paramType).boxIfNeeded(ctx);
      if (named) {
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
      }
      return _providedBridgeArgument(
        ctx,
        arg0,
      ).copyIntoFreshSlot(ctx, 'bridge_argument');
    }

    final values = _evaluateArguments(matched, positional.length, (argument) {
      final index = argument.positional;
      return compileMatchedBridge(
        index == null ? namedParamByName[argument.named]! : positional[index],
        argument.source,
        named: index == null,
      );
    });
    Variable? padding;
    return _finishArguments(
      signature,
      values,
      before: before,
      superParams: superParams,
      forward: (spec, name) =>
          _providedBridgeArgument(ctx, ctx.lookupLocal(name)!),
      omitted: (_) => padding ??= BuiltinValue().push(ctx),
      includeOmitted: false,
    );
  }

  BoundCall bindBridgeTarget(
    CallTarget target,
    ArgumentList? argumentList, {
    SuperParams superParams = const (positional: [], named: {}),
  }) {
    final function = switch (target) {
      StaticCall(:final bridgeFunction) ||
      ConstructorCall(:final bridgeFunction) => bridgeFunction,
      BridgeCall(member: BridgeMember(:final def)) => switch (def) {
        BridgeMethodDef(:final functionDescriptor) ||
        BridgeConstructorDef(:final functionDescriptor) => functionDescriptor,
        _ => null,
      },
      _ => null,
    };
    if (target.policy != BindingPolicy.bridgeVector ||
        function == null ||
        target.signature == null) {
      throw StateError('Bridge call target requires a bridge signature');
    }
    return bindBridgeVector(
      argumentList,
      function,
      superParams: superParams,
      targetSignature: target.signature,
    );
  }

  void _inferArgument(
    TypeRef formal,
    TypeRef actual,
    Set<TypeParameterDef> parameters,
    Map<TypeParameterDef, Set<TypeRef>> candidates,
  ) {
    final bindings = <TypeParameterDef, TypeRef>{};
    ctx.typeSystem.unify(formal, actual, bindings);
    for (final entry in bindings.entries) {
      // A self-referential binding (T -> T) carries no information — the
      // actual type only mentioned the parameter's own placeholder. Skipping
      // it leaves the parameter unconstrained so downward inference from
      // the context type can still bind it.
      if (entry.value case TypeParameterTypeRef(:final parameter)
          when parameter == entry.key) {
        continue;
      }
      if (parameters.contains(entry.key)) {
        candidates.putIfAbsent(entry.key, () => {}).add(entry.value);
      }
    }
  }

  Map<TypeParameterDef, TypeRef> _solveArguments(
    Map<TypeParameterDef, Set<TypeRef>> candidates,
  ) => {
    for (final entry in candidates.entries)
      entry.key: TypeRef.commonBaseType(ctx, entry.value),
  };

  void _resolveInvocationGenerics(
    CallSignature signature,
    List<TypeAnnotation>? explicitArguments,
    Map<TypeParameterDef, TypeRef> resolved,
    AstNode source,
  ) {
    final parameters = signature.typeParameters;
    if (parameters.isEmpty) {
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
    // The declaration seeded these definitions before resolving their bounds,
    // including recursive bounds. Use the same identities for inference.
    for (final parameter in parameters) {
      resolved[parameter] = TypeParameterTypeRef(parameter);
    }
    for (var index = 0; index < parameters.length; index++) {
      final parameter = parameters[index];
      final name = parameter.name;
      final bound = (parameter.bound ?? CoreTypes.dynamic.ref(ctx))
          .substituteTypeParameters(
            Substitution.of({
              for (final entry in resolved.entries)
                if (!parameters.contains(entry.key)) entry.key: entry.value,
            }),
          );
      if (explicitArguments == null) {
        // Inference starts from the placeholder seeded above, not the
        // bound: substituting the bound here would erase the parameter in
        // parameter types (e.g. `List<T>` -> `List<dynamic>`), so context
        // and argument constraints would never reach it. A parameter
        // nothing constrains is finalized to its bound after inference.
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
        Substitution.of({...resolved, parameter: argument}),
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
      resolved[parameter] = argument;
    }
  }

  bool _usesParameter(TypeRef type, Set<TypeParameterDef> parameters) =>
      switch (type) {
        TypeParameterTypeRef(:final parameter) => parameters.contains(
          parameter,
        ),
        InterfaceTypeRef(:final arguments) => arguments.any(
          (argument) => _usesParameter(argument, parameters),
        ),
        RecordTypeRef(:final positional, :final named) =>
          positional.any((field) => _usesParameter(field, parameters)) ||
              named.values.any((field) => _usesParameter(field, parameters)),
        FunctionTypeRef(:final signature) =>
          signature.positional.any(
                (parameter) => _usesParameter(parameter, parameters),
              ) ||
              signature.named.values.any(
                (parameter) => _usesParameter(parameter.type, parameters),
              ) ||
              _usesParameter(signature.returnType, parameters),
      };

  /// Bind a source target using its selected declaration, signature, and
  /// default policy. A virtual target leaves defaults to the runtime.
  BoundCall bindSourceTarget(
    CallTarget target,
    ArgumentList argumentList, {
    List<Variable> before = const [],
    TypeArgumentList? typeArguments,
    AstNode? source,
    Map<String, TypeRef> seedGenerics = const {},
    TypeRef? returnContext,
    int argIndexOffset = 0,
  }) {
    final selected = _sourceDeclaration(target);
    if (selected == null || target.signature == null) {
      throw StateError('Source call target requires a source signature');
    }
    final library = selected.library;
    final declaration = selected.declaration;
    final seeds = <String, TypeRef>{...seedGenerics};
    if (target is ConstructorCall) {
      final arguments = interfaceArgumentsOf(target.staticType);
      final classParameters = [
        for (final entry in target.signature!.typeParameterRefs.entries)
          if (entry.value is TypeParameterTypeRef &&
              (entry.value as TypeParameterTypeRef).parameter.owner.kind ==
                  TypeParameterOwnerKind.classLike)
            entry.key,
      ];
      for (var i = 0; i < arguments.length && i < classParameters.length; i++) {
        seeds.putIfAbsent(classParameters[i], () => arguments[i]);
      }
    }
    return bindDeclaration(
      library,
      declaration,
      argumentList,
      before: before,
      typeArguments: typeArguments,
      source: source,
      seedGenerics: seeds,
      returnContext: returnContext,
      argIndexOffset: argIndexOffset,
      fillOmitted: target.policy == BindingPolicy.callerFillsDefaults,
      targetSignature: target.signature,
    );
  }

  ({int library, Declaration declaration})? _sourceDeclaration(
    CallTarget target,
  ) => switch (target) {
    StaticCall(member: SourceMember member) ||
    VirtualCall(
      member: SourceMember member,
    ) => (library: member.library, declaration: member.sourceDeclaration),
    StaticCall(:final sourceDeclaration?, offset: final offset?) => (
      library: offset.file!,
      declaration: sourceDeclaration,
    ),
    ConstructorCall(:final constructor?, offset: final offset?) => (
      library: offset.file!,
      declaration: constructor,
    ),
    _ => null,
  };

  /// Bind operands that were evaluated before target resolution (operators,
  /// indexes, and implicit `.call`). The selected signature supplies formal
  /// types in its declaring scope; receiver arguments instantiate them.
  BoundCall bindSourceValues(
    CallTarget target,
    List<Variable> positionalValues,
    Map<String, Variable> namedValues, {
    Map<String, TypeRef> seedGenerics = const {},
    AstNode? source,
  }) {
    final selected = _sourceDeclaration(target);
    if (selected == null ||
        selected.declaration is! MethodDeclaration ||
        target.signature == null) {
      throw StateError('Source value call requires a method signature');
    }
    final signature = target.signature!;
    final args = bindDeclaration(
      selected.library,
      selected.declaration,
      null,
      suppliedShape: CallShape.values(positionalValues, namedValues),
      seedGenerics: seedGenerics,
      inferParameterNames: {
        for (final parameter in signature.typeParameters) parameter.name,
      },
      fillOmitted: target.policy == BindingPolicy.callerFillsDefaults,
      source: source,
      targetSignature: signature,
    );
    final resolvedGenerics = args.typeArguments;
    final returnType = signature.returnType
        .substituteTypeParameters(signature.substitutionFor(resolvedGenerics))
        .lowerTypeParameters(ctx);
    return BoundCall(
      positional: args.positional,
      named: args.named,
      vectorOverride: args.vectorOverride,
      typeArguments: resolvedGenerics,
      returnType: returnType.isSpec(CoreTypes.voidType)
          ? CoreTypes.dynamic.ref(ctx)
          : returnType,
      runtimeTypeArguments: [
        for (final def in signature.typeParameters)
          ctx.runtimeTypes.idOf(resolvedGenerics[def.name]!),
      ],
    );
  }

  /// Compiles the argument list for a call to a non-bridge declaration [dec],
  /// resolving generic type parameters at the call site. [seedGenerics] provides
  /// receiver-class type arguments (for instance calls); [typeArguments] are the
  /// call's explicit type arguments, whose presence disables inference.
  BoundCall bindDeclaration(
    int sourceLib,
    Declaration dec,
    ArgumentList? argumentList, {
    CallShape? suppliedShape,
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
    Set<String>? inferParameterNames,

    /// See [bindParameterList.fillOmitted].
    bool fillOmitted = true,
    CallSignature? targetSignature,
  }) {
    final signature =
        targetSignature ?? CallSignature.forDeclaration(ctx, sourceLib, dec);
    final typeParams = signature.typeParameters;
    final isCallableDecl =
        dec is FunctionDeclaration || dec is MethodDeclaration;
    final resolveGenerics = {
      ...signature.substitutionFor(seedGenerics).bindings,
    };
    if (dec is ConstructorDeclaration) {
      // Constructor signatures reference the declaring class's type parameters;
      // seed them from the call's explicit type arguments (or bounds).
      final classParams = [
        for (final entry in signature.typeParameterRefs.entries)
          if (entry.value is TypeParameterTypeRef &&
              (entry.value as TypeParameterTypeRef).parameter.owner.kind ==
                  TypeParameterOwnerKind.classLike)
            (entry.value as TypeParameterTypeRef).parameter,
      ];
      final explicitArgs = typeArguments?.arguments;
      for (var i = 0; i < classParams.length; i++) {
        final parameter = classParams[i];
        if (explicitArgs != null && i < explicitArgs.length) {
          resolveGenerics[parameter] = TypeRef.fromAnnotation(
            ctx,
            sourceLib,
            explicitArgs[i],
          );
        } else {
          resolveGenerics.putIfAbsent(
            parameter,
            () => (parameter.bound ?? CoreTypes.dynamic.ref(ctx))
                .substituteTypeParameters(Substitution.of(resolveGenerics)),
          );
        }
      }
    }
    if (isCallableDecl) {
      _resolveInvocationGenerics(
        signature,
        typeArguments?.arguments.toList(),
        resolveGenerics,
        source ?? dec,
      );
    }

    final constrainedParameters = <TypeParameterDef>{};
    final argsPair = bindParameterList(
      argumentList,
      sourceLib,
      signature,
      dec,
      suppliedShape: suppliedShape,
      before: before,
      source: source,
      argIndexOffset: argIndexOffset,
      resolveGenerics: resolveGenerics,
      constrainedParameters: constrainedParameters,
      inferParameterNames: inferParameterNames,
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
        typeParams.isNotEmpty &&
        signature.returnAnnotated) {
      final pattern = signature.returnType.substituteTypeParameters(
        signature.substitutionFor(seedGenerics, includeOwn: false),
      );
      final bindings = <TypeParameterDef, TypeRef>{};
      ctx.typeSystem.unify(pattern, returnContext, bindings);
      for (final parameter in typeParams) {
        if (constrainedParameters.contains(parameter)) continue;
        final bound = bindings[parameter];
        if (bound != null) resolveGenerics[parameter] = bound;
      }
    }

    // Parameters nothing constrained still hold their own placeholder —
    // finalize them to their declared bound (or `dynamic`). A binding to
    // another parameter (the caller's own) is real and kept.
    for (final parameter in typeParams) {
      final resolved = resolveGenerics[parameter];
      final ownPlaceholder = resolved is TypeParameterTypeRef &&
          resolved.parameter == parameter;
      if (resolved == null || ownPlaceholder) {
        resolveGenerics[parameter] =
            (parameter.bound ?? CoreTypes.dynamic.ref(ctx))
                .substituteTypeParameters(Substitution.of(resolveGenerics));
      }
    }

    TypeRef? returnType;
    if (signature.returnAnnotated && resolveGenerics.isNotEmpty) {
      returnType = signature.returnType.substituteTypeParameters(
        Substitution.of(resolveGenerics),
      );
    }
    // Inferred type arguments materialize into the emitted call's runtime
    // type-argument list, in the callee's declaration order. A parameter
    // nothing constrained stays a call-site placeholder and degrades to
    // `dynamic`, as before.
    final inferredRuntimeTypeArguments =
        isCallableDecl && typeArguments == null && typeParams.isNotEmpty
        ? [
            for (final p in typeParams)
              () {
                final t = resolveGenerics[p];
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
      typeArguments: {
        for (final entry in signature.typeParameterRefs.entries)
          if (entry.value case TypeParameterTypeRef(:final parameter))
            entry.key: ?resolveGenerics[parameter],
      },
      runtimeTypeArguments: inferredRuntimeTypeArguments,
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
  required CallTarget? dispatch,
  required List<TypeRef> argTypes,
  required Map<String, TypeRef> namedArgTypes,
  TypeDecl? signatureOwner,
}) {
  final voidType = CoreTypes.voidType.ref(ctx);
  final signature = dispatch?.signature ?? callee?.methodSignature;
  if (signature != null) {
    final resolved = resolveCallResultType(
      ctx,
      signature: signature,
      targetType: callee?.type,
      argTypes: argTypes,
      namedArgTypes: namedArgTypes,
      signatureOwner: signatureOwner,
    );
    if (resolved != null) return resolved;
  }
  final calleeType = callee?.type;
  final declared = calleeType is FunctionTypeRef
      ? calleeType.signature.returnType
      : null;
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
  // The declaration the signature's type parameters are keyed on. When it
  // differs from [targetType]'s own declaration (an inherited member), the
  // receiver is viewed as an instance of that declaration so its type
  // parameters still substitute — `appliedArguments(targetType)` alone
  // would leave them at their bounds.
  TypeDecl? signatureOwner,
}) {
  final voidType = CoreTypes.voidType.ref(ctx);
  final overridden = signature.returnOverride?.call(argTypes, namedArgTypes);
  if (overridden != null) {
    return overridden == voidType ? null : overridden;
  }
  var resolved = signature.returnType;
  var receiver = targetType;
  if (receiver != null && signatureOwner != null) {
    receiver =
        ctx.typeSystem.asInstanceOf(receiver, signatureOwner) ?? receiver;
  }
  final targetSubs = receiver == null
      ? null
      : ctx.typeSystem.appliedArguments(receiver);
  if (targetSubs != null && targetSubs.isNotEmpty) {
    resolved = resolved.substituteTypeParameters(targetSubs);
  }
  resolved = resolved.lowerTypeParameters(
    ctx,
    only: signature.typeParameters.toSet(),
  );
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
/// Callers fall back to `dynamic` on null — an unresolvable return
/// annotation stays permissive rather than failing to compile.
TypeRef? memberCallResultType(
  CompilerContext ctx,
  TypeRef type,
  String method,
  List<TypeRef> argTypes,
  Map<String, TypeRef> namedArgTypes, {
  bool $static = false,
  AstNode? source,
  ResolvedMember? resolved,
}) {
  final lookupType = ctx.typeSystem.throughTypeParameters(type);
  if (lookupType.isSpec(CoreTypes.dynamic)) {
    return CoreTypes.dynamic.ref(ctx);
  }
  if ($static) {
    final member =
        resolved?.member ??
        ctx.memberLookup.staticMember(lookupType, method, MemberKind.method) ??
        (throw CompileError('Cannot find static method $lookupType.$method'));
    if (member is BridgeMember && member.isField) {
      return CoreTypes.dynamic.ref(ctx);
    }
    if (member case SourceMember(node: ConstructorDeclaration())) {
      return lookupType;
    }
    return resolveCallResultType(
      ctx,
      signature: member.signature,
      targetType: lookupType,
      signatureOwner: member.ownerDecl,
      argTypes: argTypes,
      namedArgTypes: namedArgTypes,
    );
  }
  if (method == 'noSuchMethod') {
    // `Object.noSuchMethod` is implicit — absent from declaration metadata.
    return CoreTypes.dynamic.ref(ctx);
  }
  resolved ??= ctx.memberLookup.interfaceMember(
    lookupType,
    ctx.memberNameOf(method, MemberKind.method),
    source: source,
  );
  if (resolved.member.isField) {
    // A field holding a callable — its call signature isn't modelled here.
    return CoreTypes.dynamic.ref(ctx);
  }
  // resolved.signature is already instantiated at the receiver's view of
  // the declaring class (asInstanceOf inside interfaceMember), so no
  // targetType substitution is needed — remaining unbound type parameters
  // are the member's own and lower to their bounds.
  return resolveCallResultType(
    ctx,
    signature: resolved.signature,
    targetType: null,
    argTypes: argTypes,
    namedArgTypes: namedArgTypes,
  );
}
