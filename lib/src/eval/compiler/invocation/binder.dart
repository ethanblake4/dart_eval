import 'package:control_flow_graph/control_flow_graph.dart' show Assign;
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/context_type.dart';
import '../helpers/constructor_type.dart';
import '../helpers/argument_preview.dart';
import '../reference.dart';
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

final class _InferenceConstraints {
  final lower = <TypeRef>{};
  final upper = <TypeRef>{};
}

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

    final callableType =
        callee?.type ?? (target is MemberValueCall ? target.valueType : null);
    final declaredSignature = callableType is FunctionTypeRef
        ? callableType.signature
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
    var substitutions =
        declaredSignature == null || site.shape.typeArguments == null
        ? Substitution.empty
        : Substitution.of({
            for (var i = 0; i < declaredSignature.typeParameters.length; i++)
              declaredSignature.typeParameters[i]: suppliedTypeArguments[i],
          });
    final ownParameters =
        declaredSignature?.typeParameters.toSet() ?? const <TypeParameterDef>{};
    final contextHoles = Substitution.of({
      for (final parameter in ownParameters) parameter: UnknownTypeRef.instance,
    });
    final inferredArguments = <TypeParameterDef, _InferenceConstraints>{};
    TypeRef contextualType(TypeRef type) => type
        .substituteTypeParameters(substitutions)
        .substituteTypeParameters(contextHoles);
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
      // Unbound parameters are context holes, including inside collections:
      // `f<T>(Set<T> x)` must let `{1}` infer Set<int>. Coercion still uses
      // the erased boundary type.
      final context = declaredType == null
          ? null
          : contextualType(declaredType);
      var argument = _compileArg(ctx, source, context);
      if (declaredType != null &&
          site.shape.typeArguments == null &&
          ownParameters.isNotEmpty) {
        _inferArgument(
          declaredType,
          argument.type,
          ownParameters,
          inferredArguments,
          source: site.source,
        );
        // Constraints this argument solves feed the context of later
        // arguments — `fold(base, (next, mw) => ...)` types the lambda's
        // `next` with `T`'s binding from `base`.
        final solved = _solveArguments(inferredArguments);
        if (solved.isNotEmpty) {
          substitutions = Substitution.of(solved);
        }
      }
      if (parameterType != null) {
        final originalType = argument.type;
        final coercionContext = contextualType(declaredType!);
        argument = convertForAssignment(
          ctx,
          argument,
          parameterType,
          representation: MachineRepresentation.object,
          boundContext: coercionContext,
          source: site.source,
        );
        final convertedType = argument.type;
        if (site.shape.typeArguments == null &&
            ownParameters.isNotEmpty &&
            originalType is! FunctionTypeRef &&
            convertedType is FunctionTypeRef &&
            convertedType.signature.typeParameters.isEmpty) {
          _inferArgument(
            declaredType,
            argument.type,
            ownParameters,
            inferredArguments,
            source: site.source,
          );
          substitutions = Substitution.of(_solveArguments(inferredArguments));
        }
      }
      return argument
          .copyIntoFreshSlot(ctx, 'closure_argument')
          .boxIfNeeded(ctx);
    }

    final matched = _matchArguments(site.shape, site.shape.positional.length, {
      for (final (name, _) in site.shape.named) name,
    }, errorSource: site.source);
    final values = ctx.withDeferredWriteCaptures(
      () => _evaluateArguments(
        matched,
        site.shape.positional.length,
        (argument) => bindArgument(
          argument.source,
          argument.positional == null
              ? declaredSignature?.named[argument.named]?.type
              : declaredSignature?.positional[argument.positional!],
        ),
      ),
    );
    final positionalArgs = values.positional.cast<Variable>();
    final namedArgs = values.named;

    final inferredSubstitutions = <TypeParameterDef, TypeRef>{};
    var allTypeArgumentsDefaulted = false;
    if (declaredSignature != null && site.shape.typeArguments == null) {
      inferredSubstitutions.addAll(_solveArguments(inferredArguments));
      // An uninformative context must leave unconstrained parameters at
      // their bounds, rather than infer `dynamic` over a narrower bound.
      if (site.context != null &&
          !site.context!.isSpec(CoreTypes.dynamic) &&
          !site.context!.isSpec(CoreTypes.voidType) &&
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
      // Track whether any parameter was solved by inference before the
      // bound-defaulting pass fills the rest.
      final allDefaulted = inferredSubstitutions.isEmpty;
      for (final parameter in declaredSignature.typeParameters) {
        inferredSubstitutions.putIfAbsent(
          parameter,
          () => (parameter.bound ?? CoreTypes.dynamic.ref(ctx))
              .substituteTypeParameters(Substitution.of(inferredSubstitutions))
              .lowerTypeParameters(ctx),
        );
      }
      // A type argument that only defaulted to the static signature's bound
      // may violate the callee's own bound (`const void Function<T extends
      // num>() f = t1` where `t1<T extends int>`): with no inference
      // evidence, omitting the args lets the callee instantiate to its own
      // bounds, as the VM does.
      allTypeArgumentsDefaulted =
          allDefaulted && declaredSignature.typeParameters.isNotEmpty;
    }
    final resolvedSubstitutions = site.shape.typeArguments == null
        ? Substitution.of(inferredSubstitutions)
        : substitutions;
    final runtimeTypeArguments = allTypeArgumentsDefaulted
        ? const <int>[]
        : [
            for (final type
                in site.shape.typeArguments == null && declaredSignature != null
                    ? [
                        for (final parameter
                            in declaredSignature.typeParameters)
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
    final inferredResult = inferredReturn?.lowerTypeParameters(
      ctx,
      only: ownParameters,
    );
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
        (target is MemberValueCall &&
                declaredSignature != null &&
                !declaredSignature.returnType.isSpec(CoreTypes.voidType)
            ? declaredSignature.returnType
            : null) ??
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

  bool _isNoArgumentConstructor(ArgSource source) {
    if (source is! ExpressionArg) return false;
    var expression = source.expression;
    while (expression is ParenthesizedExpression) {
      expression = expression.expression;
    }
    if (expression is InstanceCreationExpression) {
      return expression.argumentList.arguments.isEmpty &&
          expression.constructorName.type.typeArguments == null;
    }
    if (expression is! MethodInvocation ||
        expression.argumentList.arguments.isNotEmpty ||
        expression.typeArguments != null ||
        expression.isCascaded) {
      return false;
    }
    final target = expression.target;
    if (target == null) {
      return IdentifierReference(
            null,
            expression.methodName.name,
          ).denotation(ctx)
          is TypeLiteralDenotation;
    }
    final receiver = _constructorNamespace(target);
    if (receiver is PrefixDenotation) {
      return receiver.resolveMember(
            ctx,
            expression.methodName.name,
            forSet: false,
          )
          is TypeLiteralDenotation;
    }
    if (receiver is TypeLiteralDenotation) {
      final member = ctx.memberLookup.staticMember(
        receiver.type,
        expression.methodName.name,
        MemberKind.method,
      );
      return switch (member) {
        SourceMember(node: ConstructorDeclaration()) => true,
        BridgeMember(def: BridgeConstructorDef()) => true,
        _ => false,
      };
    }
    return false;
  }

  Denotation? _constructorNamespace(Expression target) {
    if (target is SimpleIdentifier) {
      return IdentifierReference(null, target.name).denotation(ctx);
    }
    final (prefix, name) = switch (target) {
      PrefixedIdentifier(:final prefix, :final identifier) => (
        prefix.name,
        identifier.name,
      ),
      PropertyAccess(target: SimpleIdentifier prefix, :final propertyName) => (
        prefix.name,
        propertyName.name,
      ),
      _ => (null, null),
    };
    if (prefix == null) return null;
    final receiver = IdentifierReference(null, prefix).denotation(ctx);
    return receiver is PrefixDenotation
        ? receiver.resolveMember(ctx, name!, forSet: false)
        : null;
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
    Set<TypeParameterDef> fixedParameters = const {},
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

    /// See [bindDeclaration.defaultsSignature].
    CallSignature? defaultsSignature,
  }) {
    final positional = signature.positional;
    final named = {for (final spec in signature.named) spec.name: spec};

    // Infer a method's own parameters, not class parameters fixed by its
    // receiver. Constructors still infer their class parameters from arguments.
    final parameterDefs = {
      for (final entry in signature.typeParameterRefs.entries)
        if (entry.value case TypeParameterTypeRef(:final parameter)
            when (parameterHost is ConstructorDeclaration ||
                    signature.typeParameters.contains(parameter)) &&
                (inferParameterNames == null ||
                    inferParameterNames.contains(entry.key)) &&
                !fixedParameters.contains(parameter))
          parameter,
    };
    var argumentSubstitution = Substitution.of({
      for (final entry in resolveGenerics.entries)
        if (parameterHost is! ConstructorDeclaration ||
            !parameterDefs.contains(entry.key) ||
            !entry.key.hasExplicitVariance)
          entry.key: entry.value,
    });
    final candidates = <TypeParameterDef, _InferenceConstraints>{};
    final fixedBoundArguments = {
      for (final entry in resolveGenerics.entries)
        if (!parameterDefs.contains(entry.key)) entry.key: entry.value,
    };
    final previewParameters = <ArgSource, FunctionSignature>{};

    // The parameter in the dispatch implementation's own signature —
    // omitted defaults come from the callee that will actually run, while
    // coercion stays on the bound (interface) signature.
    ParameterSpec defaultsSpecFor(ParameterSpec spec) {
      final position = signature.positional.indexOf(spec);
      if (position >= 0) {
        final impl = defaultsSignature!.positional;
        return position < impl.length ? impl[position] : spec;
      }
      return defaultsSignature!.named.firstWhere(
        (candidate) => candidate.name == spec.name,
        orElse: () => spec,
      );
    }

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
      // Only the callee's own parameters lower: class and enclosing-scope
      // parameters stay meaningful through the frame's type environment,
      // where the runtime check resolves them against the actual owner.
      var coercionType = paramType.requiresTypeEnvironment
          ? paramType
                .lowerTypeParameters(
                  ctx,
                  only: parameterHost is ConstructorDeclaration
                      ? {
                          ...signature.typeParameters,
                          for (final ref in signature.typeParameterRefs.values)
                            if (ref case TypeParameterTypeRef(:final parameter))
                              parameter,
                        }
                      : {...signature.typeParameters},
                  kinds: const {TypeParameterOwnerKind.typeAlias},
                )
                // A lowered bound can re-introduce a parameter the call
                // resolved (`S extends T` under `A<num>` lowers S to T, still
                // bound to num) — substitute it again.
                .substituteTypeParameters(argumentSubstitution)
          : paramType;
      // The placeholder-rich shape is the better context type everywhere:
      // its remaining type parameters act as inference variables (`[1]`
      // under `Iterable<T>` still produces `List<int>` and binds T to int),
      // while the erased formal would clamp the argument to `dynamic`.
      var argBound =
          unifyPattern?.substituteTypeParameters(argumentSubstitution) ??
          coercionType;
      final parameters = previewParameters[argument];
      if (argBound is FunctionTypeRef && parameters != null) {
        argBound = argBound.copyWith(
          signature: FunctionSignature(
            typeParameters: argBound.signature.typeParameters,
            positional: parameters.positional,
            requiredPositional: parameters.requiredPositional,
            named: parameters.named,
            returnType: argBound.signature.returnType,
          ),
        );
      }
      final noUpwardArguments =
          parameterDefs.isNotEmpty &&
          argBound is InterfaceTypeRef &&
          argBound.decl.typeParameters.any((p) => p.hasExplicitVariance) &&
          _isNoArgumentConstructor(argument);
      if (noUpwardArguments) {
        argBound = ctx.typeSystem.unconstrainedInferenceContext(
          argBound,
          parameterDefs,
        );
      }
      if (argBound is InterfaceTypeRef) {
        // A nested call sees a schema, not the outer invocation's unresolved
        // parameter as a fixed lexical type. Its arguments can then infer the
        // hole (`choose(items)` under `Box<S>`, where S is still unknown).
        argBound = argBound.substituteTypeParameters(
          Substitution.of({
            for (final parameter in parameterDefs)
              if (argumentSubstitution.bindings[parameter]
                  case TypeParameterTypeRef(parameter: final unresolved)
                  when unresolved == parameter)
                parameter: UnknownTypeRef.instance,
          }),
        );
      }
      var arg0 = _compileArg(ctx, argument, argBound);
      if (unifyPattern != null) {
        // Inference reads the argument's own type — coercion below may
        // erase still-unbound parameters to `dynamic`, which would record
        // `T -> dynamic` instead of the actual constraint.
        _inferArgument(
          unifyPattern,
          arg0.type,
          parameterDefs,
          candidates,
          source: source ?? argumentList ?? parameterHost,
          fixedArguments: fixedBoundArguments,
        );
        if (candidates.isNotEmpty) {
          // Upper constraints from function parameters need all arguments
          // before they can be intersected. Until then, Never is a safe
          // parameter type for checking each source function.
          final solved = {
            ...resolveGenerics,
            ..._solveArguments(candidates, includeUpper: false),
          };
          final provisional = {
            ...solved,
            for (final entry in candidates.entries)
              if ((solved[entry.key] == null ||
                      solved[entry.key] is TypeParameterTypeRef &&
                          (solved[entry.key] as TypeParameterTypeRef)
                                  .parameter ==
                              entry.key) &&
                  entry.value.lower.isEmpty &&
                  entry.value.upper.isNotEmpty)
                entry.key: CoreTypes.never.ref(ctx),
          };
          coercionType = spec.type.substituteTypeParameters(
            Substitution.of(provisional),
          );
          // Solutions from this argument propagate into the context of
          // later ones — a lambda parameter typed `R` sees `R`'s binding
          // from an earlier argument (`fold(base, (next, mw) => ...)`).
          argumentSubstitution = Substitution.of(solved);
        }
      }
      final originalType = arg0.type;
      final coercionContext = spec.type
          .substituteTypeParameters(argumentSubstitution)
          .substituteTypeParameters(
            Substitution.of({
              for (final parameter in parameterDefs)
                parameter: UnknownTypeRef.instance,
            }),
          );
      arg0 = coerceArgumentForParameter(
        ctx,
        arg0,
        coercionType,
        param,
        parameterHost,
        genericParameter: spec.erased,
        boundContext: coercionContext,
        source: source,
      );
      // Only implicit callable coercion adds evidence after boundary conversion.
      final convertedType = arg0.type;
      if (unifyPattern != null &&
          originalType is! FunctionTypeRef &&
          convertedType is FunctionTypeRef &&
          convertedType.signature.typeParameters.isEmpty) {
        _inferArgument(
          unifyPattern,
          arg0.type,
          parameterDefs,
          candidates,
          source: source ?? argumentList ?? parameterHost,
          fixedArguments: fixedBoundArguments,
        );
        argumentSubstitution = Substitution.of({
          ...resolveGenerics,
          ..._solveArguments(candidates, includeUpper: false),
        });
      }
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

    FunctionExpression? closureOf(ArgSource source) {
      if (source is! ExpressionArg) return null;
      var expression = source.expression;
      while (expression is ParenthesizedExpression) {
        expression = expression.expression;
      }
      return expression is FunctionExpression ? expression : null;
    }

    ParameterSpec specOf(_MatchedArgument argument) =>
        argument.positional == null
        ? named[argument.named]!
        : positional[argument.positional!];
    // Infer independent arguments before typing closures that depend on them.
    // This preview emits no SSA: actual argument evaluation stays in source
    // order below, and each closure retains its parameter inference context.
    if (inferGenerics &&
        parameterDefs.isNotEmpty &&
        matched.any((argument) {
          final closure = closureOf(argument.source);
          return closure != null &&
              (closure.parameters?.parameters.any(
                    (parameter) =>
                        parameter.type == null &&
                        parameter.functionTypedSuffix == null,
                  ) ??
                  false) &&
              _usesParameter(specOf(argument).type, parameterDefs);
        })) {
      final pending = [...matched];
      var grounded = false;
      final cyclicContexts = <ArgSource, TypeRef>{};
      Substitution previewSubstitution({bool ground = false}) {
        final solved = {...resolveGenerics, ..._solveArguments(candidates)};
        return Substitution.of({
          ...solved,
          for (final parameter in parameterDefs)
            parameter:
                solved[parameter] is TypeParameterTypeRef &&
                    (solved[parameter] as TypeParameterTypeRef).parameter ==
                        parameter
                ? ground
                      ? ctx.typeSystem.greatestInferenceBound(
                          parameter.bound ??
                              CoreTypes.object.ref(ctx).withNullable(true),
                          parameterDefs,
                        )
                      : UnknownTypeRef.instance
                : solved[parameter] ?? UnknownTypeRef.instance,
        });
      }

      while (pending.isNotEmpty) {
        var progress = false;
        for (final argument in [...pending]) {
          final source = argument.source;
          if (source is! ExpressionArg) {
            pending.remove(argument);
            continue;
          }
          final spec = specOf(argument);
          final context =
              cyclicContexts[source] ??
              spec.type.substituteTypeParameters(previewSubstitution());
          final preview = previewArgumentType(
            ctx,
            source.expression,
            context: context,
          );
          if (preview == null) continue;
          if (closureOf(source) != null && preview is FunctionTypeRef) {
            previewParameters[source] = preview.signature;
          }
          _inferArgument(
            spec.type,
            preview,
            parameterDefs,
            candidates,
            source: argumentList ?? parameterHost,
            fixedArguments: fixedBoundArguments,
          );
          pending.remove(argument);
          progress = true;
        }
        if (!progress) {
          if (grounded ||
              pending.any((argument) => closureOf(argument.source) == null)) {
            break;
          }
          // Cyclic closure dependencies start with greatest-closure parameter
          // contexts; their return constraints can still refine the call.
          final dependencies = <_MatchedArgument, Set<_MatchedArgument>>{};
          for (final argument in pending) {
            final closure = closureOf(argument.source)!;
            final type = specOf(argument).type;
            if (type is! FunctionTypeRef) continue;
            final inputs = <TypeRef>[];
            var position = 0;
            for (final parameter
                in closure.parameters?.parameters ?? <FormalParameter>[]) {
              final input = parameter.isNamed
                  ? type.signature.named[parameter.name?.lexeme]?.type
                  : position < type.signature.positional.length
                  ? type.signature.positional[position++]
                  : null;
              if (input != null &&
                  parameter.type == null &&
                  parameter.functionTypedSuffix == null) {
                inputs.add(input);
              }
            }
            dependencies[argument] = {
              for (final producer in pending)
                if (specOf(producer).type case FunctionTypeRef(:final signature)
                    when parameterDefs.any(
                      (parameter) =>
                          inputs.any(
                            (input) => _usesParameter(input, {parameter}),
                          ) &&
                          _usesParameter(signature.returnType, {parameter}),
                    ))
                  producer,
            };
          }
          bool reaches(
            _MatchedArgument current,
            _MatchedArgument target,
            Set<_MatchedArgument> seen,
          ) {
            if (!seen.add(current)) return false;
            return (dependencies[current] ?? const <_MatchedArgument>{}).any(
              (next) => next == target || reaches(next, target, seen),
            );
          }

          final greatestContext = previewSubstitution(ground: true);
          for (final argument in pending) {
            if (reaches(argument, argument, {})) {
              cyclicContexts[argument.source] = specOf(
                argument,
              ).type.substituteTypeParameters(greatestContext);
            }
          }
          if (cyclicContexts.isEmpty) break;
          grounded = true;
        }
      }
      argumentSubstitution = Substitution.of({
        ...resolveGenerics,
        ..._solveArguments(candidates),
      });
    }

    // Closures in the argument list are analyzed like their bodies run
    // when the callee does: their captured writes take effect once the
    // invocation completes, not while later arguments compile.
    final values = ctx.withDeferredWriteCaptures(
      () => _evaluateArguments(matched, positional.length, (argument) {
        final index = argument.positional;
        final spec = index == null ? named[argument.named]! : positional[index];
        return compileMatched(spec, argument.source);
      }),
    );
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
      omitted: (spec) {
        if (!fillOmitted) return null;
        // Inherited factory defaults belong to the redirect target. Only
        // supplied arguments are checked against the factory's own types.
        final redirect = parameterHost is ConstructorDeclaration
            ? redirectFactoryParameter(ctx, spec.node!, parameterHost)
            : null;
        return compileOmittedArgument(
          ctx,
          defaultsSignature == null ? spec : defaultsSpecFor(spec),
          parameterHost,
          (redirect?.type ?? spec.type).substituteTypeParameters(
            argumentSubstitution,
          ),
        );
      },
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
    List<TypeRef?> positionalContexts = const [],
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
    // Unresolved inference placeholders (`callSite` type parameters) in the
    // bridge signature act like a generic call's own parameters: each
    // argument can constrain them, and solved bindings flow into later
    // argument contexts.
    final bridgePlaceholders = {
      for (final spec in [...signature.positional, ...signature.named])
        ..._callSiteParameters(spec.type),
    };
    var bridgeSubstitution = Substitution.empty;
    final bridgeCandidates = <TypeParameterDef, _InferenceConstraints>{};
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
      int? position,
    }) {
      final paramType = param.type.substituteTypeParameters(bridgeSubstitution);
      final context = position != null && position < positionalContexts.length
          ? positionalContexts[position] ?? paramType
          : paramType;
      final callbackContext = context is FunctionTypeRef
          ? context.substituteTypeParameters(
              Substitution.of({
                for (final parameter in bridgePlaceholders)
                  parameter: UnknownTypeRef.instance,
              }),
            )
          : context;
      var arg0 = _compileArg(ctx, argument, callbackContext).boxIfNeeded(ctx);
      // Callable objects contribute their `.call` signature to inference,
      // just as an explicitly supplied tear-off does.
      if (context is FunctionTypeRef &&
          arg0.type is! FunctionTypeRef &&
          !arg0.type.isSpec(CoreTypes.dynamic) &&
          !arg0.type.isSpec(CoreTypes.nullType)) {
        arg0 = convertForAssignment(
          ctx,
          arg0,
          context,
          representation: MachineRepresentation.object,
          boundContext: callbackContext,
          source: argumentList,
        );
      }
      if (bridgePlaceholders.isNotEmpty) {
        _inferArgument(
          param.type,
          arg0.type,
          bridgePlaceholders,
          bridgeCandidates,
          source: argumentList,
        );
        final solved = _solveArguments(bridgeCandidates);
        if (solved.isNotEmpty) {
          bridgeSubstitution = Substitution.of(solved);
        }
      }
      if (named) {
        final nominalFunction =
            paramType.isSpec(CoreTypes.function) && arg0.type.isFunctionLike;
        if (!nominalFunction &&
            arg0.type.assignmentConversionTo(ctx, paramType) ==
                AssignmentConversion.invalid) {
          throw CompileError(
            'Cannot assign argument of type ${arg0.type} to parameter of type $paramType',
            argumentList,
          );
        }
        if (!nominalFunction) {
          arg0 = convertForAssignment(
            ctx,
            arg0,
            paramType,
            representation: MachineRepresentation.object,
            source: argumentList,
          );
        }
      }
      return _providedBridgeArgument(
        ctx,
        arg0,
      ).copyIntoFreshSlot(ctx, 'bridge_argument');
    }

    final values = ctx.withDeferredWriteCaptures(
      () => _evaluateArguments(matched, positional.length, (argument) {
        final index = argument.positional;
        return compileMatchedBridge(
          index == null ? namedParamByName[argument.named]! : positional[index],
          argument.source,
          named: index == null,
          position: index,
        );
      }),
    );
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
    List<TypeRef?> positionalContexts = const [],
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
    var contexts = positionalContexts;
    if (target case BridgeCall(
      name: 'putIfAbsent',
      receiver: final receiver?,
    ) when contexts.isEmpty) {
      final map = ctx.typeSystem.asInstanceOf(
        receiver.type,
        ctx.types.bySpec(CoreTypes.map),
      );
      final arguments = map == null
          ? const <TypeRef>[]
          : interfaceArgumentsOf(map);
      if (arguments.length == 2) {
        // The hand-maintained bridge exposes Function, but the SDK contract
        // is V Function(). Recover its context from the applied Map<K, V>.
        contexts = [
          null,
          FunctionTypeRef(
            FunctionSignature(
              positional: const [],
              requiredPositional: 0,
              named: const {},
              returnType: arguments[1],
            ),
            decl: ctx.types.bySpec(CoreTypes.function),
          ),
        ];
      }
    }
    return bindBridgeVector(
      argumentList,
      function,
      superParams: superParams,
      targetSignature: target.signature,
      positionalContexts: contexts,
    );
  }

  /// Every `callSite` type parameter occurring inside [type] — bridge
  /// signatures embed them directly in parameter types rather than a
  /// `typeParameterRefs` map.
  Set<TypeParameterDef> _callSiteParameters(TypeRef type) => switch (type) {
    UnknownTypeRef() => const {},
    TypeParameterTypeRef(:final parameter) =>
      parameter.owner.kind == TypeParameterOwnerKind.callSite
          ? {parameter}
          : const {},
    InterfaceTypeRef(:final arguments) => {
      for (final argument in arguments) ..._callSiteParameters(argument),
    },
    RecordTypeRef(:final positional, :final named) => {
      for (final field in positional) ..._callSiteParameters(field),
      for (final field in named.values) ..._callSiteParameters(field),
    },
    FunctionTypeRef(:final signature) => {
      for (final parameter in signature.positional)
        ..._callSiteParameters(parameter),
      for (final parameter in signature.named.values)
        ..._callSiteParameters(parameter.type),
      ..._callSiteParameters(signature.returnType),
    },
  };

  void _inferArgument(
    TypeRef formal,
    TypeRef actual,
    Set<TypeParameterDef> parameters,
    Map<TypeParameterDef, _InferenceConstraints> candidates, {
    AstNode? source,
    Map<TypeParameterDef, TypeRef> fixedArguments = const {},
  }) {
    final expandingBounds = <(TypeParameterDef, TypeRef)>{};
    final useBounds =
        source == null || ctx.languageVersionAtLeast(source, 3, 7);
    int? afterBoundIndex;
    void collect(TypeRef pattern, TypeRef evidence, bool covariant) {
      if (pattern is UnknownTypeRef || evidence is UnknownTypeRef) return;
      if (pattern is TypeParameterTypeRef) {
        final parameter = pattern.parameter;
        if (!parameters.contains(parameter)) return;
        // Bounds infer dependencies left to right; earlier parameters have
        // already made their inference choice.
        if (afterBoundIndex != null && parameter.index <= afterBoundIndex!) {
          return;
        }
        var value = ctx.typeSystem.typeParameterEvidence(pattern, evidence);
        if (pattern.nullable && value.nullable) {
          value = value.withNullable(false);
        }
        final bound = parameter.bound?.substituteTypeParameters(
          Substitution.of(fixedArguments),
        );
        if (useBounds && covariant && bound != null) {
          final greatestBound = ctx.typeSystem.greatestInferenceBound(
            bound,
            parameters,
          );
          if (!value.isAssignableTo(
            ctx,
            greatestBound,
            forceAllowDynamic: false,
          )) {
            // A nullable formal may accept an input without constraining T.
            // Retain its bound as the choice when no non-null branch supplies
            // lower evidence, rather than inferring Null outside that bound.
            candidates
                .putIfAbsent(parameter, _InferenceConstraints.new)
                .upper
                .add(greatestBound);
            if (value is TypeParameterTypeRef &&
                expandingBounds.add((parameter, value))) {
              final effectiveBound = value.effectiveBound;
              if (effectiveBound != null) {
                collect(pattern, effectiveBound, covariant);
              }
              expandingBounds.remove((parameter, value));
            } else if (value is InterfaceTypeRef &&
                value.isSpec(AsyncTypes.futureOr)) {
              final arguments = interfaceArgumentsOf(value);
              if (arguments.isNotEmpty) {
                final member = arguments.first;
                collect(
                  pattern,
                  ctx.types.bySpec(CoreTypes.future).instantiate([member]),
                  covariant,
                );
                collect(pattern, member, covariant);
              }
            }
            return;
          }
        }
        // T against T adds no evidence and must leave downward inference open.
        if (value is TypeParameterTypeRef && value.parameter == parameter) {
          return;
        }
        final constraint = candidates.putIfAbsent(
          parameter,
          _InferenceConstraints.new,
        );
        (covariant ? constraint.lower : constraint.upper).add(value);
        if (useBounds &&
            covariant &&
            bound != null &&
            expandingBounds.add((parameter, value))) {
          // The accepted candidate also constrains parameters mentioned by
          // its bound: B<U> matched against T extends B<S> supplies S := U.
          final previousBoundIndex = afterBoundIndex;
          afterBoundIndex = parameter.index;
          collect(bound, value, covariant);
          afterBoundIndex = previousBoundIndex;
          expandingBounds.remove((parameter, value));
        }
        return;
      }
      if (pattern is FunctionTypeRef && evidence is FunctionTypeRef) {
        final source = pattern.signature;
        final target = evidence.signature;
        for (
          var i = 0;
          i < source.positional.length && i < target.positional.length;
          i++
        ) {
          collect(source.positional[i], target.positional[i], !covariant);
        }
        for (final entry in source.named.entries) {
          final targetParameter = target.named[entry.key];
          if (targetParameter != null) {
            collect(entry.value.type, targetParameter.type, !covariant);
          }
        }
        collect(source.returnType, target.returnType, covariant);
        return;
      }
      if (pattern is RecordTypeRef && evidence is RecordTypeRef) {
        if (pattern.positional.length != evidence.positional.length ||
            pattern.named.length != evidence.named.length ||
            !pattern.named.keys.every(evidence.named.containsKey)) {
          return;
        }
        for (var i = 0; i < pattern.positional.length; i++) {
          collect(pattern.positional[i], evidence.positional[i], covariant);
        }
        for (final entry in pattern.named.entries) {
          collect(entry.value, evidence.named[entry.key]!, covariant);
        }
        return;
      }
      if (pattern is! InterfaceTypeRef) return;
      if (pattern.isSpec(AsyncTypes.futureOr)) {
        final members = interfaceArgumentsOf(pattern);
        if (members.isEmpty) return;
        final member = members.first;
        // Matching unions constrain their value arguments directly. Treating
        // FutureOr<R> as a plain value would incorrectly infer FutureOr<R>
        // for the constructor parameter itself.
        if (evidence is InterfaceTypeRef &&
            evidence.isSpec(AsyncTypes.futureOr)) {
          final arguments = interfaceArgumentsOf(evidence);
          if (arguments.isNotEmpty) collect(member, arguments.first, covariant);
          return;
        }
        final future = ctx.typeSystem.asInstanceOf(
          evidence,
          ctx.types.bySpec(CoreTypes.future),
        );
        if (future != null) {
          final arguments = interfaceArgumentsOf(future);
          collect(
            member,
            arguments.isEmpty ? CoreTypes.dynamic.ref(ctx) : arguments.first,
            covariant,
          );
        } else {
          collect(member, evidence, covariant);
        }
        return;
      }
      final viewed = ctx.typeSystem.asInstanceOf(evidence, pattern.decl);
      if (viewed != null) {
        final arguments = interfaceArgumentsOf(viewed);
        for (
          var i = 0;
          i < pattern.arguments.length && i < arguments.length;
          i++
        ) {
          final variance = i < pattern.decl.typeParameters.length
              ? pattern.decl.typeParameters[i].variance
              : TypeParameterVariance.covariant;
          if (variance != TypeParameterVariance.contravariant) {
            collect(pattern.arguments[i], arguments[i], covariant);
          }
          if (variance != TypeParameterVariance.covariant) {
            collect(pattern.arguments[i], arguments[i], !covariant);
          }
        }
      } else if (evidence is InterfaceTypeRef) {
        final parent = ctx.typeSystem.asInstanceOf(pattern, evidence.decl);
        if (parent != null) collect(parent, evidence, covariant);
      }
    }

    collect(formal, actual, true);
  }

  Map<TypeParameterDef, TypeRef> _solveArguments(
    Map<TypeParameterDef, _InferenceConstraints> candidates, {
    bool includeUpper = true,
  }) => {
    for (final entry in candidates.entries)
      if (includeUpper &&
          entry.key.variance == TypeParameterVariance.contravariant &&
          entry.value.upper.isNotEmpty)
        entry.key: entry.value.upper.reduce(ctx.typeSystem.greatestLowerBound)
      else if (entry.value.lower.isNotEmpty)
        entry.key: TypeRef.commonBaseType(ctx, entry.value.lower)
      else if (includeUpper && entry.value.upper.isNotEmpty)
        entry.key: entry.value.upper.reduce(ctx.typeSystem.greatestLowerBound),
  };

  Set<TypeParameterDef> _fixDownwardArguments(
    List<TypeParameterDef> parameters,
    Map<TypeParameterDef, TypeRef> inferred,
    Map<TypeParameterDef, TypeRef> resolved,
  ) {
    final holes = Substitution.of({
      for (final parameter in parameters) parameter: UnknownTypeRef.instance,
    });
    bool known(TypeRef type) =>
        !type.hasInferenceVariables &&
        !type.substituteTypeParameters(holes).hasSchemaHoles;
    final fixed = <TypeParameterDef>{};
    for (final parameter in parameters) {
      var candidate = inferred[parameter];
      if (candidate == null || !known(candidate)) continue;
      final declaredBound = parameter.bound;
      if (declaredBound != null) {
        final bound = declaredBound.substituteTypeParameters(
          Substitution.of(resolved),
        );
        if (!known(bound)) continue;
        // Intersect outer nullability: int? under `extends num` fixes int.
        // Null is a type of its own, rather than a nullable suffix.
        candidate =
            candidate.isSpec(CoreTypes.nullType) ||
                bound.isSpec(CoreTypes.nullType)
            ? ctx.typeSystem.greatestLowerBound(candidate, bound)
            : ctx.typeSystem
                  .greatestLowerBound(
                    candidate.withNullable(false),
                    bound.withNullable(false),
                  )
                  .withNullable(candidate.nullable && bound.nullable);
        final finalBound = declaredBound.substituteTypeParameters(
          Substitution.of({...resolved, parameter: candidate}),
        );
        // Recursive or incomplete bound solutions remain open to arguments.
        if (!known(candidate) ||
            !known(finalBound) ||
            !candidate.isAssignableTo(
              ctx,
              finalBound,
              forceAllowDynamic: false,
            )) {
          continue;
        }
      }
      resolved[parameter] = candidate;
      fixed.add(parameter);
    }
    return fixed;
  }

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
    if (explicitArguments == null) {
      // Inference starts from the placeholder seeded above, not the
      // bound: substituting the bound here would erase the parameter in
      // parameter types (e.g. `List<T>` -> `List<dynamic>`), so context
      // and argument constraints would never reach it. A parameter
      // nothing constrains is finalized to its bound after inference.
      return;
    }
    final arguments = [
      for (final annotation in explicitArguments)
        TypeRef.fromAnnotation(ctx, ctx.library, annotation),
    ];
    // Bind every argument before checking bounds: a bound may mention a
    // later parameter (`X extends A1<X, Y>`), and its check needs Y's
    // explicit argument, not Y's placeholder.
    for (var index = 0; index < parameters.length; index++) {
      resolved[parameters[index]] = arguments[index];
    }
    for (var index = 0; index < parameters.length; index++) {
      final parameter = parameters[index];
      final argument = arguments[index];
      // The bound may self-reference (`T extends Generator<T>`); substitute
      // the actual arguments before checking assignability.
      final bound = (parameter.bound ?? CoreTypes.dynamic.ref(ctx))
          .substituteTypeParameters(
            Substitution.of({
              for (final entry in resolved.entries)
                if (!parameters.contains(entry.key)) entry.key: entry.value,
            }),
          );
      final substitutedBound = bound.substituteTypeParameters(
        Substitution.of(resolved),
      );

      // Bounds are checked with assignability: a `dynamic` bound parameter
      // accepts any argument type, but `dynamic` is still rejected on the
      // covariant side (the `Exactly<dynamic>` <: `Exactly<int>` case).
      if (!argument.isSpec(CoreTypes.dynamic) &&
          !substitutedBound.isSpec(CoreTypes.dynamic) &&
          !ctx.typeSystem.isAssignable(
            argument,
            substitutedBound,
            forceAllowDynamic: false,
            allowDynamicParameterDowncast: true,
          )) {
        throw CompileError(
          'Type argument $argument does not satisfy the bound $bound of ${parameter.name}',
          source,
        );
      }
    }
  }

  bool _usesParameter(TypeRef type, Set<TypeParameterDef> parameters) =>
      switch (type) {
        UnknownTypeRef() => false,
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

  /// Infers a call's result without evaluating arguments or emitting bytecode.
  /// Global storage inference uses the same argument constraints as binding.
  TypeRef inferStaticCallResult(
    CallSignature signature,
    List<TypeRef> positional,
    Map<String, TypeRef> named, {
    List<TypeRef>? explicitArguments,
    AstNode? source,
  }) {
    final parameters = signature.typeParameters;
    final bindings = <TypeParameterDef, TypeRef>{};
    if (explicitArguments != null) {
      if (explicitArguments.length != parameters.length) {
        throw CompileError(
          'Expected ${parameters.length} type arguments, '
          'but found ${explicitArguments.length}',
          source,
        );
      }
      for (var i = 0; i < parameters.length; i++) {
        bindings[parameters[i]] = explicitArguments[i];
      }
    } else if (parameters.isNotEmpty) {
      final candidates = <TypeParameterDef, _InferenceConstraints>{};
      final parameterSet = parameters.toSet();
      for (
        var i = 0;
        i < positional.length && i < signature.positional.length;
        i++
      ) {
        _inferArgument(
          signature.positional[i].type,
          positional[i],
          parameterSet,
          candidates,
          source: source,
        );
      }
      for (final parameter in signature.named) {
        if (named[parameter.name] case final actual?) {
          _inferArgument(
            parameter.type,
            actual,
            parameterSet,
            candidates,
            source: source,
          );
        }
      }
      bindings.addAll(_solveArguments(candidates));
    }
    final defaults = ctx.typeSystem.instantiateToBounds(
      parameters,
      knownTypes: bindings,
    );
    return signature.returnType.substituteTypeParameters(
      Substitution.of(defaults),
    );
  }

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
    var signature = target.signature!;
    Set<String>? inferParameterNames;
    if (target is ConstructorCall) {
      // A constructor can be called from its own generic class. Its inference
      // variables must differ from the caller's lexical class parameters.
      final originalParameters = [
        for (final ref in signature.typeParameterRefs.values)
          if (ref case TypeParameterTypeRef(
            :final parameter,
          ) when parameter.owner.kind == TypeParameterOwnerKind.classLike)
            parameter,
      ];
      final freshOwners = <TypeParameterOwner, TypeParameterOwner>{};
      final freshParameters = {
        for (final parameter in originalParameters)
          parameter: TypeParameterDef(
            freshOwners.putIfAbsent(
              parameter.owner,
              () => TypeParameterOwner.fresh(parameter.owner),
            ),
            parameter.index,
            parameter.name,
            variance: parameter.variance,
            hasExplicitVariance: parameter.hasExplicitVariance,
          ),
      };
      final freshSubstitution = Substitution.of({
        for (final entry in freshParameters.entries)
          entry.key: TypeParameterTypeRef(entry.value),
      });
      for (final entry in freshParameters.entries) {
        entry.value.bound = entry.key.bound?.substituteTypeParameters(
          freshSubstitution,
        );
      }
      signature = signature.substitute(freshSubstitution);
      final arguments = interfaceArgumentsOf(
        target.instantiatedType ?? target.staticType,
      );
      final classParameters = [
        for (final entry in signature.typeParameterRefs.entries)
          if (entry.value is TypeParameterTypeRef &&
              (entry.value as TypeParameterTypeRef).parameter.owner.kind ==
                  TypeParameterOwnerKind.classLike)
            entry.key,
      ];
      for (var i = 0; i < arguments.length && i < classParameters.length; i++) {
        seeds.putIfAbsent(classParameters[i], () => arguments[i]);
      }
      final contextual = constructorContextArguments(
        ctx,
        target.staticType,
        returnContext,
      );
      if (typeArguments == null) {
        for (final parameter in originalParameters) {
          if (!contextual.containsKey(parameter) &&
              seeds[parameter.name] == TypeParameterTypeRef(parameter)) {
            seeds[parameter.name] = TypeParameterTypeRef(
              freshParameters[parameter]!,
            );
          }
        }
      }
      if (typeArguments == null) {
        for (final entry in contextual.entries) {
          final previous = seeds[entry.key.name];
          if (previous == null ||
              previous is TypeParameterTypeRef &&
                  previous.parameter == freshParameters[entry.key]) {
            seeds[entry.key.name] = entry.value;
          }
        }
      }
      // A caller's type parameter is a resolved argument, even though it is
      // symbolic. Only the constructor's own placeholder needs inference.
      inferParameterNames = {
        for (final name in classParameters)
          if (typeArguments == null &&
                  (signature.typeParameterRefs[name] as TypeParameterTypeRef)
                      .parameter
                      .hasExplicitVariance ||
              seeds[name] == null ||
              seeds[name] is TypeParameterTypeRef &&
                  (seeds[name] as TypeParameterTypeRef).parameter ==
                      (signature.typeParameterRefs[name]
                              as TypeParameterTypeRef)
                          .parameter ||
              seeds[name]!.hasSchemaHoles ||
              seeds[name]!.hasInferenceVariables)
            name,
      };
    }
    final result = bindDeclaration(
      library,
      declaration,
      argumentList,
      before: before,
      typeArguments: typeArguments,
      source: source,
      seedGenerics: seeds,
      inferParameterNames: inferParameterNames,
      returnContext: returnContext,
      argIndexOffset: argIndexOffset,
      fillOmitted: target.policy == BindingPolicy.callerFillsDefaults,
      targetSignature: signature,
      // A devirtualized call binds against the interface signature but
      // fills omitted defaults from the implementation it dispatches to.
      defaultsSignature: target is StaticCall ? target.member?.signature : null,
    );
    if (target is! ConstructorCall) return result;
    final parameters =
        nominalDeclOf(
          target.instantiatedType ?? target.staticType,
        )?.typeParameters ??
        [
          for (final ref in target.signature!.typeParameterRefs.values)
            if (ref case TypeParameterTypeRef(
              :final parameter,
            ) when parameter.owner.kind == TypeParameterOwnerKind.classLike)
              parameter,
        ];
    return BoundCall(
      positional: result.positional,
      named: result.named,
      vectorOverride: result.vector(),
      typeArguments: result.typeArguments,
      returnType: inferredConstructorType(
        ctx,
        target.instantiatedType ?? target.staticType,
        parameters,
        result.typeArguments,
      ),
      declaredReturn: result.declaredReturn,
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
      defaultsSignature: target is StaticCall ? target.member?.signature : null,
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

    /// The dispatch implementation's signature — supplied when binding
    /// happens against a different (interface) signature. Only its default
    /// values are read: coercion still follows [targetSignature].
    CallSignature? defaultsSignature,
  }) {
    final signature =
        targetSignature ?? CallSignature.forDeclaration(ctx, sourceLib, dec);
    final typeParams = signature.typeParameters;
    final isCallableDecl =
        dec is FunctionDeclaration || dec is MethodDeclaration;
    final resolveGenerics = {
      ...signature.substitutionFor(seedGenerics).bindings,
    };
    final classParams = <TypeParameterDef>[];
    if (dec is ConstructorDeclaration) {
      // Constructor signatures reference the declaring class's type parameters;
      // Keep unresolved parameters until argument inference has completed.
      classParams.addAll([
        for (final entry in signature.typeParameterRefs.entries)
          if (entry.value is TypeParameterTypeRef &&
              (entry.value as TypeParameterTypeRef).parameter.owner.kind ==
                  TypeParameterOwnerKind.classLike)
            (entry.value as TypeParameterTypeRef).parameter,
      ]);
      final explicitArgs = typeArguments?.arguments;
      for (var i = 0; i < classParams.length; i++) {
        final parameter = classParams[i];
        if (explicitArgs != null && i < explicitArgs.length) {
          // Forwarding constructors already seed the declaring superclass's
          // transformed arguments, e.g. Alias<T> = Base<List<T>> with M.
          resolveGenerics.putIfAbsent(
            parameter,
            () => TypeRef.fromAnnotation(ctx, ctx.library, explicitArgs[i]),
          );
        } else {
          resolveGenerics.putIfAbsent(
            parameter,
            () => TypeParameterTypeRef(parameter),
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

    final fixedParameters = <TypeParameterDef>{};
    // Give context-sensitive arguments (notably closures) the return
    // context's type arguments before compiling their bodies.
    if (returnContext != null &&
        typeArguments == null &&
        typeParams.isNotEmpty &&
        signature.returnAnnotated) {
      final pattern = signature.returnType.substituteTypeParameters(
        signature.substitutionFor(seedGenerics, includeOwn: false),
      );
      final bindings = <TypeParameterDef, TypeRef>{};
      ctx.typeSystem.unify(
        pattern,
        inferContextType(ctx, pattern, returnContext),
        bindings,
      );
      for (final parameter in typeParams) {
        if (bindings[parameter] case final inferred?) {
          resolveGenerics[parameter] = inferred;
        }
      }
      if (isCallableDecl &&
          !returnContext.isSpec(CoreTypes.dynamic) &&
          !returnContext.isSpec(CoreTypes.voidType)) {
        fixedParameters.addAll(
          _fixDownwardArguments(typeParams, bindings, resolveGenerics),
        );
      }
    }

    final constrainedParameters = <TypeParameterDef>{...fixedParameters};
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
      fixedParameters: fixedParameters,
      constrainedParameters: constrainedParameters,
      inferParameterNames: inferParameterNames,
      // Explicit arguments also fix a constructor's class parameters. Do not
      // infer them again from a dynamic argument and discard its type check.
      inferGenerics: typeArguments == null,
      fillOmitted: fillOmitted,
      defaultsSignature: defaultsSignature,
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
      ctx.typeSystem.unify(
        pattern,
        inferContextType(ctx, pattern, returnContext),
        bindings,
      );
      for (final parameter in typeParams) {
        if (constrainedParameters.contains(parameter)) continue;
        final bound = bindings[parameter];
        if (bound != null) resolveGenerics[parameter] = bound;
      }
    }

    // Parameters nothing constrained still hold their own placeholder —
    // finalize them to their declared bound (or `dynamic`). A binding to
    // another parameter (the caller's own) is real and kept.
    if (classParams.isNotEmpty) {
      final knownTypes = {
        for (final parameter in classParams)
          if (resolveGenerics[parameter] case final resolved?
              when resolved is! TypeParameterTypeRef ||
                  resolved.parameter != parameter)
            parameter: ctx.typeSystem.closeSchemaHoles(resolved),
      };
      resolveGenerics.addAll(
        ctx.typeSystem.instantiateToBounds(classParams, knownTypes: knownTypes),
      );
    }
    for (final parameter in typeParams) {
      final resolved = resolveGenerics[parameter];
      final ownPlaceholder =
          resolved is TypeParameterTypeRef && resolved.parameter == parameter;
      if (resolved == null || ownPlaceholder) {
        resolveGenerics[parameter] =
            (parameter.bound ?? CoreTypes.dynamic.ref(ctx))
                .substituteTypeParameters(Substitution.of(resolveGenerics));
      }
      resolveGenerics[parameter] = ctx.typeSystem.closeSchemaHoles(
        resolveGenerics[parameter]!,
      );
    }

    // F-bounded inference (`X extends A<X>`): a direct binding like `X := C`
    // needn't satisfy `C <: A<C>` — the solution lives one view away, at the
    // candidate's instantiation of the bound's class (`C <: A<B>` gives
    // `X := B`). Mutually recursive bounds (`X extends A1<X, Y>`,
    // `Y extends A2<X, Y>`) solve together: tentative solutions are
    // collected first, then each is verified with all of them applied.
    final fBounded = <TypeParameterDef, TypeRef>{};
    for (final parameter in typeParams) {
      final declaredBound = parameter.bound;
      if (declaredBound == null ||
          !_usesParameter(declaredBound, {parameter})) {
        continue;
      }
      final candidate = resolveGenerics[parameter];
      if (candidate == null || candidate is TypeParameterTypeRef) continue;
      final boundSubst = declaredBound.substituteTypeParameters(
        Substitution.of(resolveGenerics),
      );
      if (candidate.isAssignableTo(ctx, boundSubst)) continue;
      final boundPattern = declaredBound.substituteTypeParameters(
        Substitution.of({...resolveGenerics}..remove(parameter)),
      );
      final bindings = <TypeParameterDef, TypeRef>{};
      ctx.typeSystem.unify(boundPattern, candidate, bindings);
      final throughView = bindings[parameter];
      if (throughView != null && throughView is! TypeParameterTypeRef) {
        fBounded[parameter] = throughView;
      }
    }
    for (final entry in fBounded.entries) {
      final recheck = entry.key.bound!.substituteTypeParameters(
        Substitution.of({...resolveGenerics, ...fBounded}),
      );
      if (ctx.typeSystem.isAssignable(
        entry.value,
        recheck,
        forceAllowDynamic: false,
        allowDynamicParameterDowncast: true,
      )) {
        resolveGenerics[entry.key] = entry.value;
      }
    }

    TypeRef? returnType;
    if (signature.returnAnnotated && resolveGenerics.isNotEmpty) {
      returnType = signature.returnType.substituteTypeParameters(
        Substitution.of(resolveGenerics),
      );
    }
    // Inferred type arguments materialize into the emitted call's runtime
    // type-argument list, in the callee's declaration order. A caller's
    // parameter keeps its descriptor so the active type environment resolves
    // it; unconstrained callee parameters were defaulted above.
    final inferredRuntimeTypeArguments =
        isCallableDecl && typeArguments == null && typeParams.isNotEmpty
        ? [
            for (final p in typeParams)
              () {
                final t = resolveGenerics[p];
                return t == null
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
