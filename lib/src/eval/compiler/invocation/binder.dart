import 'package:dart_eval/src/eval/compiler/context.dart';
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

typedef _MatchedArgument = ({
  int? positional,
  String? named,
  Expression expression,
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
    ArgumentList argumentList,
    int positionalCount,
    Set<String> namedParameters, {
    int offset = 0,
    int leadingPositional = 0,
  }) {
    final matched = <_MatchedArgument>[];
    var positionalCursor = leadingPositional;
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

    Variable snapshot(Variable argument) =>
        argument.copyIntoFreshSlot(ctx, 'closure_argument').boxIfNeeded(ctx);

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
        named[-1 - i] = (
          name,
          BoundArgument(snapshot(_compileArg(ctx, source))),
        );
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
    final namedArgTypes = {for (final e in namedArgs) e.$1: e.$2.value.type};
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

  /// Binds an argument list against a [CallSignature]: the signature owns
  /// the callee's shape (arity, requiredness, names); each
  /// [ParameterSpec]'s `node` supplies the AST bits defaults and field /
  /// super formals still resolve from.
  BoundCall bindParameterList(
    ArgumentList argumentList,
    int decLibrary,
    CallSignature signature,
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

    // Constructor class parameters are already resolved in the signature's
    // declaration scope. Reuse them for field/super formals and omitted values.
    final ctorClassParamRefs = <String, TypeRef>{
      if (parameterHost is ConstructorDeclaration)
        for (final entry in signature.typeParameterRefs.entries)
          if (entry.value is TypeParameterTypeRef &&
              (entry.value as TypeParameterTypeRef).parameter.owner.kind ==
                  TypeParameterOwnerKind.classLike)
            entry.key: entry.value,
    };
    final ctorClassParamNames = ctorClassParamRefs.keys.toSet();
    final ctorClassParamSubs = Substitution.of(<TypeParameterDef, TypeRef>{
      for (final entry in ctorClassParamRefs.entries)
        (entry.value as TypeParameterTypeRef).parameter:
            ?resolveGenerics[entry.key],
    });
    final paramTypeParameters = {...ctorClassParamRefs, ...resolveGenerics};

    // The signature resolved formal annotations in the declaring scope. Bind
    // those exact parameter identities to the call's receiver and type args;
    // resolving AST annotations again here can pick a different scope.
    final parameterDefs = <String, TypeParameterDef>{
      for (final entry in signature.typeParameterRefs.entries)
        if (entry.value is TypeParameterTypeRef)
          entry.key: (entry.value as TypeParameterTypeRef).parameter,
    };
    final argumentSubstitution = Substitution.of({
      for (final entry in parameterDefs.entries)
        if (resolveGenerics[entry.key] case final TypeRef type)
          entry.value: type,
    });

    final resolveGenericsMap = <String, Set<TypeRef>>{};

    // Compiles the supplied argument [expr] for [spec]: context-typed
    // compilation, coercion to the formal, and generic-inference recording.
    Variable compileMatched(ParameterSpec spec, Expression expr) {
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
      var arg0 = compileExpression(expr, ctx, argBound);
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
      // A following argument can assign to the local slot that produced this
      // value. Keep the evaluated value independent of that slot.
      return arg0.copyIntoFreshSlot(ctx, 'source_argument');
    }

    final matched = _matchArguments(
      argumentList,
      positional.length,
      named.keys.toSet(),
      offset: argIndexOffset,
      leadingPositional: superParams.positional.length,
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

    // **Compile** supplied arguments in source order — a named argument
    // interleaves with positionals.
    final compiledPositional = List<Variable?>.filled(positional.length, null);
    final compiledNamed = <String, Variable>{};
    for (final argument in matched) {
      final pi = argument.positional;
      if (pi != null) {
        compiledPositional[pi] = compileMatched(
          positional[pi],
          argument.expression,
        );
      } else {
        final name = argument.named;
        if (name != null) {
          compiledNamed[name] = compileMatched(
            named[name]!,
            argument.expression,
          );
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
          spec.node!,
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
        if (spec.isRequired) {
          throw CompileError('Not enough positional arguments');
        } else if (fillOmitted) {
          final value = compileOmittedArgument(
            ctx,
            decLibrary,
            spec.node!,
            parameterHost,
            typeParameters: paramTypeParameters,
            defaultSource: spec.defaultValue is SourceDefault
                ? spec.defaultValue as SourceDefault
                : null,
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
          spec0.node!,
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
          spec0.node!,
          parameterHost,
          typeParameters: paramTypeParameters,
          defaultSource: spec0.defaultValue is SourceDefault
              ? spec0.defaultValue as SourceDefault
              : null,
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
  }) => _finishBridgeVector(
    function,
    before: before,
    superParams: superParams,
    positionalValues: List<Variable?>.filled(function.params.length, null),
    namedValues: const {},
  );

  BoundCall _finishBridgeVector(
    BridgeFunctionDef function, {
    required List<Variable> before,
    required SuperParams superParams,
    required List<Variable?> positionalValues,
    required Map<String, Variable> namedValues,
  }) {
    final args = <Variable>[];
    final push = <Variable>[...before];
    final namedArgs = <String, Variable>{};
    Variable? $null;

    for (var i = 0; i < function.params.length; i++) {
      final param = function.params[i];
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
      final supplied = namedValues[param.name];
      if (supplied != null) {
        push.add(supplied);
        namedArgs[param.name] = supplied;
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
      vectorOverride: [for (final argument in push) argument.ssa],
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
      if (arg0.type.isFunctionLike && arg0.unmaterializedCallable != null) {
        arg0 = arg0.tearOff(ctx);
      }
      // Dynamic calls use canonical object values for every argument. Their
      // signature cannot justify unboxing a scalar or a collection here.
      arg0 = arg0.boxIfNeeded(ctx);
      arg0 = arg0.copyIntoFreshSlot(ctx, 'dynamic_argument');

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
    final positional = function.params;
    final namedParamByName = {for (final p in function.namedParams) p.name: p};
    final matched = _matchArguments(argumentList, positional.length, {
      ...namedParamByName.keys,
      ...superParams.named,
    });

    // Resolve the receiver's type arguments for every parameter annotation.
    // Bridge positional arguments defer assignment checks to the runtime;
    // named arguments retain the existing static conversion rule.
    Variable compileMatchedBridge(
      BridgeParameter param,
      Expression expr, {
      required bool named,
    }) {
      final paramType = TypeRef.fromBridgeAnnotation(
        ctx,
        param.type,
        typeParameters: typeParameters,
      );
      var arg0 = compileExpression(expr, ctx, paramType).boxIfNeeded(ctx);
      if (arg0.type.isFunctionLike && arg0.unmaterializedCallable != null) {
        arg0 = arg0.tearOff(ctx, boundContext: paramType);
      }
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
      function,
      before: before,
      superParams: superParams,
      positionalValues: compiledPositional,
      namedValues: compiledNamed,
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
        Substitution.of({
          (resolved[name]! as TypeParameterTypeRef).parameter: argument,
        }),
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
    final (_, typeParams, returnAnnotation) = _invocationSignature(dec);
    final isCallableDecl =
        dec is FunctionDeclaration || dec is MethodDeclaration;
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
      CallSignature.forDeclaration(ctx, sourceLib, dec),
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
        final bound =
            bindings[(placeholders[name]! as TypeParameterTypeRef).parameter];
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
    final inferredRuntimeTypeArguments =
        isCallableDecl && typeArguments == null && typeParams != null
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
