import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart' hide Assign;
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

typedef _MatchedArgument = ({
  int? positional,
  String? named,
  Expression expression,
});

typedef _MatchedSource = ({int? positional, String? named, ArgSource source});

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
    ArgumentList argumentList,
    int positionalCount,
    Set<String> namedParameters, {
    int offset = 0,
  }) {
    final matched = <_MatchedArgument>[];
    var positionalCursor = 0;
    for (var i = offset; i < argumentList.arguments.length; i++) {
      final argument = argumentList.arguments[i];
      if (argument is NamedArgument) {
        final name = argument.name.lexeme;
        if (!namedParameters.contains(name)) {
          throw CompileError('Unknown named argument $name', argument);
        }
        matched.add((
          positional: null,
          named: name,
          expression: argument.argumentExpression,
        ));
      } else {
        if (positionalCursor >= positionalCount) {
          throw CompileError(
            'Too many positional arguments: $positionalCount expected, '
            'but ${positionalCursor + 1} found.',
          );
        }
        matched.add((
          positional: positionalCursor++,
          named: null,
          expression: argument.argumentExpression,
        ));
      }
    }
    return matched;
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
          ? instantiated.lowerTypeParameters(ctx)
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
        final bindings = <TypeParameterDef, TypeRef>{};
        ctx.typeSystem.unify(declaredType, argument.type, bindings);
        for (final entry in bindings.entries) {
          if (ownParameters.contains(entry.key)) {
            inferredArguments
                .putIfAbsent(entry.key, () => <TypeRef>{})
                .add(entry.value);
          }
        }
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
          bindArgument(
            site.shape.positional[i],
            declaredSignature?.positional[i],
          ),
        );
      } else {
        final (name, source) = site.shape.named[-1 - i];
        named[-1 - i] = (
          name,
          BoundArgument(
            bindArgument(source, declaredSignature?.named[name]?.type),
          ),
        );
      }
    }
    final positionalArgs = positional.cast<BoundArgument>();
    final namedArgs = named.cast<(String, BoundArgument)>();

    final inferredSubstitutions = <TypeParameterDef, TypeRef>{};
    if (declaredSignature != null && site.shape.typeArguments == null) {
      for (final parameter in declaredSignature.typeParameters) {
        final candidates = inferredArguments[parameter];
        if (candidates != null && candidates.isNotEmpty) {
          inferredSubstitutions[parameter] = TypeRef.commonBaseType(
            ctx,
            candidates,
          );
        }
      }
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
    final argTypes = [for (final a in positionalArgs) a.value.type];
    final namedArgTypes = {for (final e in namedArgs) e.$1: e.$2.value.type};
    final inferredReturn =
        declaredSignature != null &&
            _usesParameter(declaredSignature.returnType, ownParameters)
        ? declaredSignature.returnType.substituteTypeParameters(
            resolvedSubstitutions,
          )
        : null;
    final inferredResult = inferredReturn?.lowerTypeParameters(ctx);
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
      trusted: _closureArgumentsProven(
        ctx,
        callee?.type,
        [for (final a in positionalArgs) a.value],
        {for (final e in namedArgs) e.$1: e.$2.value},
      ),
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
    Map<String, TypeRef> resolveGenerics = const {},
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
        signature = CallSignature.forDeclaration(ctx, decLibrary, targetDecl);
        parameterHost = targetDecl;
      }
    }

    final ssa = <SSA>[];
    final args = <Variable>[];
    final push = <Variable>[...before];
    final namedArgs = <String, Variable>{};

    final positional = signature.positional;
    final named = {for (final spec in signature.named) spec.name: spec};

    var i = 0;

    // The signature resolved formal annotations in the declaring scope. Bind
    // those exact parameter identities to the call's receiver and type args;
    // resolving AST annotations again here can pick a different scope.
    final parameterDefs = <String, TypeParameterDef>{
      for (final entry in signature.typeParameterRefs.entries)
        if (entry.value is TypeParameterTypeRef &&
            (inferParameterNames == null ||
                inferParameterNames.contains(entry.key)))
          entry.key: (entry.value as TypeParameterTypeRef).parameter,
    };
    final argumentSubstitution = signature.substitutionFor(resolveGenerics);

    final resolveGenericsMap = <String, Set<TypeRef>>{};

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

      // The placeholder-rich shape only serves as context for function-typed
      // parameters — collection literals need the erased formal so their
      // element types stay unconstrained until unification.
      final argBound = unifyPattern is FunctionTypeRef
          ? unifyPattern
          : paramType;
      var arg0 = _compileArg(ctx, argument, argBound);
      arg0 = coerceArgumentForParameter(
        ctx,
        arg0,
        paramType,
        param,
        parameterHost,
        genericParameter: spec.erased,
        source: source,
      );

      if (unifyPattern != null) {
        // Deep inference: unify the parameter's declared shape against the
        // supplied type — `List<X>` against `List<int>` binds X to int —
        // recording each bound generic name for the common-base solve.
        {
          final bindings = <TypeParameterDef, TypeRef>{};
          ctx.typeSystem.unify(unifyPattern, arg0.type, bindings);
          for (final e in parameterDefs.entries) {
            final bound = bindings[e.value];
            if (bound != null) {
              resolveGenericsMap[e.key] ??= {};
              resolveGenericsMap[e.key]!.add(bound);
            }
          }
        }
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
    final matched = <_MatchedSource>[];
    var positionalCursor = superParams.positional.length;
    for (final index in shape.sourceOrder.skip(argIndexOffset)) {
      if (index >= 0) {
        if (positionalCursor >= positional.length) {
          throw CompileError(
            'Too many positional arguments: ${positional.length} expected, '
            'but ${positionalCursor + 1} found.',
            source,
          );
        }
        matched.add((
          positional: positionalCursor++,
          named: null,
          source: shape.positional[index],
        ));
      } else {
        final (name, argument) = shape.named[-1 - index];
        if (superParams.named.contains(name)) {
          throw CompileError(
            'Named super argument $name is already forwarded',
            source,
          );
        }
        if (!named.containsKey(name)) {
          throw CompileError('Unknown named argument $name', source);
        }
        matched.add((positional: null, named: name, source: argument));
      }
    }
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

    // **Compile** supplied arguments in source order — a named argument
    // interleaves with positionals.
    final compiledPositional = List<Variable?>.filled(positional.length, null);
    final compiledNamed = <String, Variable>{};
    for (final argument in matched) {
      final pi = argument.positional;
      if (pi != null) {
        compiledPositional[pi] = compileMatched(
          positional[pi],
          argument.source,
        );
      } else {
        final name = argument.named;
        if (name != null) {
          compiledNamed[name] = compileMatched(named[name]!, argument.source);
        }
      }
    }

    // **Emit** the vector in declaration order.
    for (var pi = 0; pi < positional.length; pi++) {
      final spec = positional[pi];
      // First check super params. Super params do not contain an expression;
      // positional ones bind to the callee's positional parameters in order.
      if (i < superParams.positional.length) {
        final V = _forwardedSuperParam(
          spec,
          parameterHost,
          superParams.positional[i],
          substitution: argumentSubstitution,
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
        if (spec.isRequired) {
          throw CompileError('Not enough positional arguments');
        } else if (fillOmitted) {
          final value = compileOmittedArgument(
            ctx,
            decLibrary,
            spec.node!,
            parameterHost,
            defaultSource: spec.defaultValue is SourceDefault
                ? spec.defaultValue as SourceDefault
                : null,
            declaredType: spec.type.substituteTypeParameters(
              argumentSubstitution,
            ),
          );
          push.add(value);
          args.add(value);
        }
      }
      i++;
    }

    for (final n in named.entries) {
      final name = n.key;
      final spec0 = n.value;
      if (superParams.named.contains(name)) {
        final V = _forwardedSuperParam(
          spec0,
          parameterHost,
          name,
          substitution: argumentSubstitution,
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
          spec0.node!,
          parameterHost,
          defaultSource: spec0.defaultValue is SourceDefault
              ? spec0.defaultValue as SourceDefault
              : null,
          declaredType: spec0.type.substituteTypeParameters(
            argumentSubstitution,
          ),
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

  BoundCall _finishBridgeVector(
    CallSignature signature, {
    required List<Variable> before,
    required SuperParams superParams,
    required List<Variable?> positionalValues,
    required Map<String, Variable> namedValues,
  }) {
    final args = <Variable>[];
    final push = <Variable>[...before];
    final namedArgs = <String, Variable>{};
    Variable? $null;

    for (var i = 0; i < signature.positional.length; i++) {
      final param = signature.positional[i];
      if (i < superParams.positional.length) {
        final V = _providedBridgeArgument(
          ctx,
          ctx.lookupLocal(superParams.positional[i])!,
        );
        push.add(V);
        args.add(V);
        continue;
      }
      final supplied = positionalValues[i];
      if (supplied != null) {
        push.add(supplied);
        args.add(supplied);
        continue;
      }
      if (param.isRequired) {
        throw CompileError('Not enough positional arguments');
      }
      $null ??= BuiltinValue().push(ctx);
      push.add($null);
    }

    for (final param in signature.named) {
      if (superParams.named.contains(param.name)) {
        final V = _providedBridgeArgument(ctx, ctx.lookupLocal(param.name)!);
        push.add(V);
        namedArgs[param.name] = V;
        continue;
      }
      final supplied = namedValues[param.name];
      if (supplied != null) {
        push.add(supplied);
        namedArgs[param.name] = supplied;
        continue;
      }
      if (param.isRequired) {
        throw CompileError('Missing required named argument ${param.name}');
      }
      $null ??= BuiltinValue().push(ctx);
      push.add($null);
    }

    return BoundCall(
      positional: [for (final a in args) BoundArgument(a)],
      named: [
        for (final e in namedArgs.entries) (e.key, BoundArgument(e.value)),
      ],
      vectorOverride: [for (final argument in push) argument.ssa],
      returnType: CoreTypes.dynamic.ref(ctx),
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
    if (superParams.positional.isNotEmpty &&
        argumentList != null &&
        argumentList.arguments.any((argument) => argument is! NamedArgument)) {
      throw CompileError(
        'Positional super parameters cannot be combined with positional super arguments',
        argumentList,
      );
    }
    if (argumentList != null) {
      for (final argument in argumentList.arguments) {
        if (argument is NamedArgument &&
            superParams.named.contains(argument.name.lexeme)) {
          throw CompileError(
            'Named super argument ${argument.name.lexeme} is already forwarded',
            argument,
          );
        }
      }
    }
    final matched = argumentList == null
        ? <_MatchedArgument>[]
        : _matchArguments(argumentList, positional.length, {
            ...namedParamByName.keys,
            ...superParams.named,
          });

    // Resolve the receiver's type arguments for every parameter annotation.
    // Bridge positional arguments defer assignment checks to the runtime;
    // named arguments retain the existing static conversion rule.
    Variable compileMatchedBridge(
      ParameterSpec param,
      Expression expr, {
      required bool named,
    }) {
      final paramType = param.type;
      var arg0 = compileExpression(expr, ctx, paramType).boxIfNeeded(ctx);
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

    // **Compile** supplied arguments in source order.
    final compiledPositional = List<Variable?>.filled(positional.length, null);
    final compiledNamed = <String, Variable>{};
    for (final argument in matched) {
      final pi = argument.positional;
      if (pi != null) {
        compiledPositional[pi] = compileMatchedBridge(
          positional[pi],
          argument.expression,
          named: false,
        );
        continue;
      }
      final name = argument.named;
      // Named arguments that reach a forwarded super parameter are dropped:
      // the parameter binds the constructor's local instead.
      if (name != null &&
          namedParamByName.containsKey(name) &&
          !superParams.named.contains(name)) {
        compiledNamed[name] = compileMatchedBridge(
          namedParamByName[name]!,
          argument.expression,
          named: true,
        );
      }
    }

    return _finishBridgeVector(
      signature,
      before: before,
      superParams: superParams,
      positionalValues: compiledPositional,
      namedValues: compiledNamed,
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

  void _resolveInvocationGenerics(
    CallSignature signature,
    List<TypeAnnotation>? explicitArguments,
    Map<String, TypeRef> resolved,
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
      resolved[parameter.name] = TypeParameterTypeRef(parameter);
    }
    for (var index = 0; index < parameters.length; index++) {
      final parameter = parameters[index];
      final name = parameter.name;
      final bound = (parameter.bound ?? CoreTypes.dynamic.ref(ctx))
          .substituteTypeParameters(
            signature.substitutionFor(resolved, includeOwn: false),
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
        signature.substitutionFor({...resolved, name: argument}),
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
    final (library, declaration) = switch (target) {
      StaticCall(member: SourceMember member) ||
      VirtualCall(
        member: SourceMember member,
      ) => (member.library, member.sourceDeclaration),
      StaticCall(:final sourceDeclaration?, offset: final offset?) => (
        offset.file!,
        sourceDeclaration,
      ),
      ConstructorCall(:final constructor?, offset: final offset?) => (
        offset.file!,
        constructor,
      ),
      _ => (null, null),
    };
    if (library == null || declaration == null || target.signature == null) {
      throw StateError('Source call target requires a source signature');
    }
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
    final (library, declaration) = switch (target) {
      StaticCall(member: SourceMember member) ||
      VirtualCall(
        member: SourceMember member,
      ) => (member.library, member.sourceDeclaration),
      StaticCall(
        sourceDeclaration: MethodDeclaration method,
        offset: final offset?,
      ) =>
        (offset.file, method),
      _ => (null, null),
    };
    if (library == null ||
        declaration is! MethodDeclaration ||
        target.signature == null) {
      throw StateError('Source value call requires a method signature');
    }
    final signature = target.signature!;
    final resolvedGenerics = <String, TypeRef>{...seedGenerics};
    _resolveInvocationGenerics(
      signature,
      null,
      resolvedGenerics,
      source ?? declaration,
    );
    final args = bindParameterList(
      null,
      library,
      signature,
      declaration,
      suppliedShape: CallShape.values(positionalValues, namedValues),
      resolveGenerics: resolvedGenerics,
      inferParameterNames: {
        for (final parameter in signature.typeParameters) parameter.name,
      },
      fillOmitted: target.policy == BindingPolicy.callerFillsDefaults,
      source: source,
    );
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
    CallSignature? targetSignature,
  }) {
    final signature =
        targetSignature ?? CallSignature.forDeclaration(ctx, sourceLib, dec);
    final typeParams = signature.typeParameters;
    final isCallableDecl =
        dec is FunctionDeclaration || dec is MethodDeclaration;
    final resolveGenerics = <String, TypeRef>{...seedGenerics};
    if (dec is ConstructorDeclaration) {
      // Constructor signatures reference the declaring class's type parameters;
      // seed them from the call's explicit type arguments (or bounds).
      final classParams = [
        for (final entry in signature.typeParameterRefs.entries)
          if (entry.value is TypeParameterTypeRef &&
              (entry.value as TypeParameterTypeRef).parameter.owner.kind ==
                  TypeParameterOwnerKind.classLike)
            (entry.key, (entry.value as TypeParameterTypeRef).parameter),
      ];
      final explicitArgs = typeArguments?.arguments;
      for (var i = 0; i < classParams.length; i++) {
        final (name, parameter) = classParams[i];
        if (explicitArgs != null && i < explicitArgs.length) {
          resolveGenerics[name] = TypeRef.fromAnnotation(
            ctx,
            sourceLib,
            explicitArgs[i],
          );
        } else {
          resolveGenerics.putIfAbsent(
            name,
            () => (parameter.bound ?? CoreTypes.dynamic.ref(ctx))
                .substituteTypeParameters(
                  signature.substitutionFor(resolveGenerics),
                ),
          );
        }
      }
    }
    if (isCallableDecl) {
      _resolveInvocationGenerics(
        signature,
        typeArguments?.arguments.toList(),
        resolveGenerics,
        source!,
      );
    }

    // Snapshot the pre-inference bindings: entries still identical after the
    // argument list compiles were never constrained by the arguments.
    final unboundGenerics = Map<String, TypeRef>.of(resolveGenerics);
    final argsPair = bindParameterList(
      argumentList,
      sourceLib,
      signature,
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
        typeParams.isNotEmpty &&
        signature.returnAnnotated) {
      final pattern = signature.returnType.substituteTypeParameters(
        signature.substitutionFor(seedGenerics, includeOwn: false),
      );
      final bindings = <TypeParameterDef, TypeRef>{};
      ctx.typeSystem.unify(pattern, returnContext, bindings);
      for (final parameter in typeParams) {
        final name = parameter.name;
        if (!identical(resolveGenerics[name], unboundGenerics[name])) continue;
        final bound = bindings[parameter];
        if (bound != null) resolveGenerics[name] = bound;
      }
    }

    TypeRef? returnType;
    if (signature.returnAnnotated && resolveGenerics.isNotEmpty) {
      returnType = signature.returnType.substituteTypeParameters(
        signature.substitutionFor(resolveGenerics),
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
                final t = resolveGenerics[p.name];
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
      if (member.isField) return CoreTypes.dynamic.ref(ctx);
      // member.signature is in the declaring class's parameter space —
      // signatureOwner lets resolveCallResultType view the receiver as an
      // instance of that declaration so inherited parameters still bind.
      return resolveCallResultType(
        ctx,
        signature: member.signature,
        targetType: lookupType,
        signatureOwner: member.ownerDecl,
        argTypes: argTypes,
        namedArgTypes: namedArgTypes,
      );
    }
    final node = (member as SourceMember).node;
    if (node is ConstructorDeclaration) return lookupType;
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
  final resolved = ctx.memberLookup.interfaceMember(
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
