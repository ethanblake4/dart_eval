import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/closure.dart';
import 'package:dart_eval/src/eval/compiler/helpers/equality.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';

import '../reference.dart';
import 'expression.dart';
import 'identifier.dart';

Variable compileMethodInvocation(
  CompilerContext ctx,
  MethodInvocation e, {
  Variable? cascadeTarget,
  TypeRef? bound,
}) {
  Variable? L = cascadeTarget;
  var isPrefix = false;
  if (e.target != null && cascadeTarget == null) {
    try {
      L = compileExpression(e.target!, ctx);
      if (e.target is SuperExpression) {
        final (receiver, dispatched) = _resolveSuperReceiver(ctx, e, L);
        if (dispatched != null) return dispatched;
        L = receiver;
      }
    } on PrefixError {
      isPrefix = true;
    }
  }

  AlwaysReturnType? mReturnType;
  bool? genericReturnBoxed;

  if (L != null) {
    if (e.operator?.type == TokenType.QUESTION_PERIOD) {
      var out = BuiltinValue().push(ctx).boxIfNeeded(ctx);
      if (L.concreteTypes.length == 1 &&
          L.concreteTypes[0] == CoreTypes.nullType.ref(ctx)) {
        return out;
      }
      macroBranch(
        ctx,
        null,
        condition: (ctx) {
          return checkNotEqual(ctx, L!, out);
        },
        thenBranch: (ctx, rt) {
          final V = _invokeWithTarget(ctx, L!, e);
          out = out.copyWith(type: V.type.copyWith(nullable: true));
          ctx.pushOp(Assign(out.ssa, V.boxIfNeeded(ctx).ssa));
          return StatementInfo();
        },
      );
      return out;
    }
    return _invokeWithTarget(ctx, L, e);
  }
  final method = isPrefix
      ? compilePrefixedIdentifier(
          (e.target as Identifier).name,
          e.methodName.name,
          ctx,
        )
      : compileIdentifier(e.methodName, ctx);

  // `E(receiver)` — explicit extension application: the callee is the
  // extension's namespace type literal, so pin member resolution to `E`.
  if (method.type == CoreTypes.type.ref(ctx) &&
      method.concreteTypes.length == 1) {
    final ext = extensionForType(ctx, method.concreteTypes[0]);
    if (ext != null) {
      return _applyExtension(ctx, e, ext);
    }
  }

  if (method.type == CoreTypes.dynamic.ref(ctx) ||
      method.callingConvention == CallingConvention.dynamic ||
      (method.type == CoreTypes.function.ref(ctx) &&
          method.methodOffset == null)) {
    return _invokeValue(ctx, method, e);
  }

  if (method.methodOffset == null) {
    // The receiver isn't a known function — it may still be a callable object
    // (an implicit `.call` invocation, e.g. `c1(1)` on `C1 c1`). An extension
    // `call` member applies statically; otherwise dispatch dynamically so
    // objects without `call` raise NoSuchMethodError at runtime.
    if (!hasInstanceMethod(ctx, method.type, 'call') &&
        resolveExtensionMember(
          ctx,
          method.type,
          'call',
          arity: _positionalArity(e),
        ) !=
            null) {
      final (positional, named) = _compileCallArgs(ctx, e);
      return method.invoke(ctx, 'call', positional, namedArgs: named).result;
    }
    return _invokeValue(ctx, method, e);
  }

  var offset = method.methodOffset!;
  if (method.implicitReceiver != null) {
    // A bound extension-method tear-off invoked directly: `x.m(args)` lowers
    // to `E.m(x, args)`. Resolve the member from the tear-off's own offset —
    // this also covers `m(args)` inside the extension body where the receiver
    // is `this`.
    EvalExtension? ext;
    MethodDeclaration? member;
    for (final candidate in ctx.extensions) {
      if (candidate.library != offset.file) continue;
      for (final m in candidate.members.whereType<MethodDeclaration>()) {
        if (!m.isStatic &&
            !m.isGetter &&
            !m.isSetter &&
            candidate.memberKey(m) == offset.name) {
          ext = candidate;
          member = m;
          break;
        }
      }
      if (ext != null) break;
    }
    if (ext != null && member != null) {
      final receiver = method.implicitReceiver!;
      return _invokeExtensionMethod(
        ctx,
        receiver,
        e,
        ext,
        member,
        matchExtensionOn(ctx, receiver.type, ext) ?? const [],
      );
    }
  }
  if (offset.file == ctx.library &&
      offset.className != null &&
      offset.className == ctx.currentClassName) {
    final $this = ctx.lookupLocal('#this')!;
    return _invokeWithTarget(ctx, $this, e);
  }

  // `name` can resolve to a class rather than a callable (e.g. `List()`) —
  // then the callable declaration lives under the offset's `name.ctor` key.
  var dec0 = ctx.topLevelDeclarationsMap[offset.file]?[e.methodName.name];
  if (dec0 == null ||
      (!dec0.isBridge &&
          (dec0.declaration! is ClassDeclaration ||
              dec0.declaration! is ClassTypeAlias))) {
    dec0 =
        ctx.topLevelDeclarationsMap[offset.file]?[offset.name ??
            '${e.methodName.name}.'];
    if (dec0 == null) {
      // Call to default constructor
      final result = ctx.svar('constructor');
      mReturnType =
          method.methodReturnType?.toAlwaysReturnType(
            ctx,
            TypeRef.$this(ctx),
            [],
            {},
          ) ??
          AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
      final returnType = (mReturnType.type ?? CoreTypes.dynamic.ref(ctx))
          .copyWith(
            boxed:
                L != null ||
                !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ?? false),
          );
      final instantiatedType = _instantiateConstructorType(ctx, e, returnType);
      ctx.pushOp(
        Call(offset, [
          pushRuntimeTypeId(ctx, instantiatedType),
        ], result: result),
      );
      final v = Variable.of(
        ctx,
        result,
        instantiatedType,
        concreteTypes: [instantiatedType],
        exactType: instantiatedType,
      );

      return v;
    }
  }

  // An invocation `T(args)` where `T` is a type alias to a class is a
  // constructor call on the aliased type.
  TypeRef? aliasType;
  if (!dec0.isBridge && dec0.declaration is TypeAlias) {
    var resolved = resolveTypeAlias(
      ctx,
      ctx.library,
      dec0.declaration! as TypeAlias,
      typeArgs: e.typeArguments?.arguments.toList(),
      rawParams: true,
    );
    // Downward inference: `C<num> x = T(num)` instantiates `T` as `C<num>`,
    // matching alias parameters structurally (`T<X> = C<List<X>>` against
    // `C<List<num>>` binds `X → num`).
    final boundChain = bound?.resolveTypeChain(ctx);

    if (e.typeArguments == null &&
        boundChain != null &&
        boundChain.file == resolved.file &&
        boundChain.name == resolved.name &&
        boundChain.specifiedTypeArgs.isNotEmpty) {
      final substitutions = <(String, int), TypeRef>{};
      for (var i = 0;
          i < resolved.specifiedTypeArgs.length &&
              i < boundChain.specifiedTypeArgs.length;
          i++) {
        collectTypeParameterSubstitutions(
          ctx,
          resolved.specifiedTypeArgs[i],
          boundChain.specifiedTypeArgs[i],
          substitutions,
        );
      }
      if (substitutions.isNotEmpty) {
        resolved = resolved.substituteTypeParameters(substitutions);
      }
    }
    aliasType = resolved;
    dec0 = ctx.topLevelDeclarationsMap[resolved.file]!['${resolved.name}.'];
    offset = DeferredOrOffset(file: resolved.file, name: '${resolved.name}.');
    if (dec0 == null) {
      // The aliased class has an implicit default constructor — call the
      // synthesized `resolved.` body with just the runtime-type argument.
      final callResult = ctx.svar('constructor');
      final boxed = resolved.copyWith(boxed: true);
      ctx.pushOp(
        Call(
          offset,
          [pushRuntimeTypeId(ctx, resolved)],
          result: callResult,
        ),
      );
      return Variable.of(
        ctx,
        callResult,
        boxed,
        concreteTypes: [boxed],
        exactType: boxed,
      );
    }
  }

  final List<Variable> args;
  final Map<String, Variable> namedArgs;
  final List<SSA> callArgs;

  var isConstructor = false;
  List<TypeRef>? inferredCtorArgs;

  if (dec0.isBridge) {
    final bridge = dec0.bridge;

    /// If we're invoking a class identifier directly (like ClassName()), call
    /// its default constructor
    final fnDescriptor = bridge is BridgeClassDef
        ? (bridge.constructors['']?.functionDescriptor ??
              (throw CompileError(
                'Class "${e.methodName.name}" does not have a default constructor',
                e,
              )))
        : (bridge as BridgeFunctionDeclaration).function;

    final argsPair = compileArgumentListWithBridge(
      ctx,
      e.argumentList,
      fnDescriptor,
      before: L != null ? [L] : [],
    );

    args = argsPair.args;
    namedArgs = argsPair.namedArgs;
    callArgs = argsPair.ssa;
    isConstructor = bridge is BridgeClassDef;
  } else {
    final dec = dec0.declaration!;
    isConstructor = dec is ConstructorDeclaration;

    final result = _compileNonBridgeArgs(
      ctx,
      offset.file!,
      dec,
      e.argumentList,
      before: L != null ? [L] : [],
      typeArguments: e.typeArguments,
      source: e,
    );
    mReturnType = result.returnType;
    genericReturnBoxed = result.boxedBySubstitution;
    args = result.args.args;
    namedArgs = result.args.namedArgs;
    callArgs = result.args.ssa;

    // Upward inference for constructors: the class type arguments inferred
    // from the argument list (or the parameters' bounds), in declaration order.
    if (isConstructor && result.classTypeParameters != null) {
      inferredCtorArgs = [
        for (final param in result.classTypeParameters!)
          result.resolveGenerics[param.name.lexeme] ??
              CoreTypes.dynamic.ref(ctx),
      ];
      if (aliasType != null && e.typeArguments == null) {
        // The alias's instantiated arguments were left as parameter references
        // for inference; bind them from what the constructor's arguments gave.
        final substitutions = <(String, int), TypeRef>{};
        final aliasArgs = aliasType.specifiedTypeArgs;
        for (var i = 0; i < aliasArgs.length && i < inferredCtorArgs.length; i++) {
          collectTypeParameterSubstitutions(
            ctx,
            aliasArgs[i],
            inferredCtorArgs[i],
            substitutions,
          );
        }
        if (substitutions.isNotEmpty) {
          aliasType = aliasType.substituteTypeParameters(substitutions);
        }
      }
    }
  }

  final argTypes = args.map((e) => e.type).toList();
  final namedArgTypes = namedArgs.map(
    (key, value) => MapEntry(key, value.type),
  );

  TypeRef? thisType;
  if (ctx.currentClass != null) {
    thisType =
        ctx.visibleTypes[ctx.enclosingLibrary ?? ctx.library]![ctx
            .currentClassName!]!;
  }

  mReturnType ??=
      method.methodReturnType?.toAlwaysReturnType(
        ctx,
        thisType,
        argTypes,
        namedArgTypes,
      ) ??
      AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
  final returnType = mReturnType.type?.copyWith(
    boxed:
        dec0.isBridge ||
        (genericReturnBoxed ??
            !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ?? false)),
  );
  final instantiatedReturnType = isConstructor && returnType != null
      ? (aliasType ??
          _instantiateConstructorType(ctx, e, returnType, inferredCtorArgs))
      : returnType;
  final declaration = dec0.isBridge ? null : dec0.declaration;
  final effectiveCallArgs = [...callArgs];
  if (isConstructor &&
      declaration is ConstructorDeclaration &&
      declaration.factoryKeyword == null) {
    effectiveCallArgs.add(pushRuntimeTypeId(ctx, instantiatedReturnType!));
  }

  final result = ctx.svar('call');
  if (dec0.isBridge) {
    final bridge = dec0.bridge!;
    if (bridge is BridgeClassDef && !bridge.wrap) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);
      final subclass = BuiltinValue().push(ctx);
      ctx.pushOp(
        BridgeInstantiate(
          result,
          ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.']!,
          subclass.ssa,
          effectiveCallArgs,
          runtimeTypeId: type.runtimeTypeId(ctx),
        ),
      );
    } else {
      ctx.pushOp(
        InvokeExternal(
          result,
          ctx.bridgeStaticFunctionIndices[offset.file]![offset.name]!,
          effectiveCallArgs,
        ),
      );
    }
  } else {
    ctx.pushOp(
      Call(
        offset,
        effectiveCallArgs,
        result: result,
        // Factories have no receiver, so the class's instantiated type
        // arguments are delivered through the callable-type-argument channel.
        typeArguments:
            declaration is ConstructorDeclaration &&
                declaration.factoryKeyword != null
            ? [
                for (final arg
                    in instantiatedReturnType?.specifiedTypeArgs ??
                        const <TypeRef>[])
                  arg.runtimeTypeId(ctx),
              ]
            : isConstructor
            ? const []
            : _runtimeTypeArguments(ctx, e),
      ),
    );
  }

  final generativeCtor =
      declaration is ConstructorDeclaration &&
      declaration.factoryKeyword == null;
  final v = Variable.of(
    ctx,
    result,
    instantiatedReturnType ?? CoreTypes.dynamic.ref(ctx),
    concreteTypes: [
      if (isConstructor && instantiatedReturnType != null)
        instantiatedReturnType,
    ],
    // A factory may return any subtype — the result is not exactly the
    // declared class.
    exactType: generativeCtor ? instantiatedReturnType : null,
  );

  return v;
}

TypeRef _instantiateConstructorType(
  CompilerContext ctx,
  MethodInvocation invocation,
  TypeRef base, [
  List<TypeRef>? inferredArgs,
]) {
  final arguments = invocation.typeArguments?.arguments;
  if (arguments == null || arguments.isEmpty) {
    if (inferredArgs == null) return base;
    final baseArgs = base.specifiedTypeArgs;
    if (baseArgs.isEmpty || baseArgs.every((a) => a.isTypeParameter)) {
      return base.copyWith(specifiedTypeArgs: inferredArgs);
    }
    return base.substituteTypeParameters({
      for (var i = 0; i < inferredArgs.length; i++)
        ('class:${base.resolveTypeChain(ctx).file}:${base.name}', i):
            inferredArgs[i],
    });
  }
  return base.copyWith(
    specifiedTypeArgs: [
      for (final argument in arguments)
        TypeRef.fromAnnotation(ctx, ctx.library, argument),
    ],
  );
}

void _resolveInvocationGenerics(
  CompilerContext ctx,
  int declarationLibrary,
  List<TypeParameter>? parameters,
  List<TypeAnnotation>? explicitArguments,
  Map<String, TypeRef> resolved,
  AstNode source,
) {
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
  // self-reference (`f<T extends Foo<T>>(...)`).
  for (var index = 0; index < parameters.length; index++) {
    final name = parameters[index].name.lexeme;
    resolved[name] = TypeRef(
      declarationLibrary,
      name,
      resolved: true,
      typeParameterOwner: 'call:$declarationLibrary',
      typeParameterIndex: index,
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
    final substitutedBound = bound.substituteTypeParameters({
      ('call:$declarationLibrary', index): argument,
    });
    if (argument != CoreTypes.dynamic.ref(ctx) &&
        substitutedBound != CoreTypes.dynamic.ref(ctx) &&
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
int _positionalArity(MethodInvocation e) =>
    e.argumentList.arguments.where((a) => a is! NamedArgument).length;

/// Compiles `E(receiver)` — explicit extension application. The receiver
/// keeps its own type but carries a [BoundExtension] so member lookups on
/// the result resolve only within [ext].
Variable _applyExtension(
  CompilerContext ctx,
  MethodInvocation e,
  EvalExtension ext,
) {
  final args = e.argumentList.arguments;
  if (args.length != 1 || args.first is NamedArgument) {
    throw CompileError(
      'Extension application ${ext.name}(...) requires exactly one '
      'positional argument',
      e,
    );
  }
  final receiver = compileExpression(
    args.first.argumentExpression,
    ctx,
  ).boxIfNeeded(ctx);
  final extParams =
      ext.declaration.typeParameters?.typeParameters ?? const <TypeParameter>[];
  final List<TypeRef> bindings;
  if (e.typeArguments != null) {
    final tas = e.typeArguments!.arguments;
    if (tas.length != extParams.length) {
      throw CompileError(
        'Extension ${ext.name} takes ${extParams.length} type arguments',
        e,
      );
    }
    bindings = [
      for (final ta in tas) TypeRef.fromAnnotation(ctx, ext.library, ta),
    ];
  } else {
    // `E(c)?.m` applies `on C` to a nullable `C?` receiver; the `?.` guard
    // (or a later runtime null check) makes that legal.
    final receiverType = receiver.type.copyWith(nullable: false);
    bindings =
        matchExtensionOn(ctx, receiverType, ext) ??
        (throw CompileError(
          'Extension ${ext.name} does not apply to ${receiver.type}',
          e,
        ));
  }
  // The application result shares the receiver's SSA but is a distinct
  // value — dropping `localName` keeps `updated()` from re-resolving the
  // bound wrapper back to the unbound local.
  return receiver.copyWith()
    ..localName = null
    ..boundExtension = BoundExtension(ext, bindings);
}

Variable _invokeWithTarget(
  CompilerContext ctx,
  Variable L,
  MethodInvocation e,
) {
  // `E(x).m(...)` — explicit application pins member resolution to E.
  if (L.boundExtension case final bound?) {
    final member = extensionMember(bound.ext, e.methodName.name);
    if (member == null) {
      // `E(x).g(...)`: the getter's result is the call target.
      final getter = extensionMember(
        bound.ext,
        e.methodName.name,
        getter: true,
      );
      if (getter != null) {
        return _invokeValue(
          ctx,
          invokeExtensionGetter(
            ctx,
            L,
            bound.ext,
            getter,
            bound.onBindings,
          ),
          e,
        );
      }
      throw CompileError(
        'Extension ${bound.ext.name} has no member ${e.methodName.name}',
        e,
      );
    }
    return _invokeExtensionMethod(
      ctx,
      L,
      e,
      bound.ext,
      member,
      bound.onBindings,
    );
  }
  AlwaysReturnType? mReturnType;
  final bridgeTypeParameters = <String, TypeRef>{};

  DeclarationOrBridge<ClassMember, BridgeDeclaration>? dec0;
  final bool isStatic;
  TypeRef? staticType;

  ArgumentListResult argsPair;

  // `C.new(...)` invokes the unnamed constructor.
  final staticMemberName = ctorNameOf(e.methodName.name);

  if (L.type == CoreTypes.type.ref(ctx) && L.concreteTypes.length == 1) {
    // Static method
    staticType = L.concreteTypes[0];
    if (ctx.topLevelDeclarationsMap[staticType.file]?['${staticType.name}.$staticMemberName'] ==
            null &&
        ctx.topLevelDeclarationsMap[staticType
                .file]?['${staticType.name}.$staticMemberName*g'] ==
            null) {
      // A member invoked on a `Type` literal may still be an extension
      // member on `Type` — `C.expectStaticType<Exactly<Type>>()`.
      final found = resolveExtensionMember(
        ctx,
        L.type,
        e.methodName.name,
        arity: _positionalArity(e),
      );
      if (found != null) {
        return _invokeExtensionMethod(ctx, L, e, found.$1, found.$2, found.$3);
      }
      // Not a static member of the class — it's an instance method of the
      // `Type` object itself (`Foo.toString()`, `Foo.hashCode`, ...).
      final args = [
        for (final arg in e.argumentList.arguments)
          if (arg is! NamedArgument)
            compileExpression(arg.argumentExpression, ctx),
      ];
      return L.invoke(ctx, e.methodName.name, args).result;
    }
    dec0 = resolveStaticMethod(ctx, staticType, staticMemberName);
    // `C.field(args)` where `field` holds a closure, or `C.x(args)` where
    // `x` is a static getter, reads the member value and invokes its result
    // rather than calling a function named `C.field`/`C.x`.
    final memberDecl0 = dec0.declaration;
    if (memberDecl0 is FieldDeclaration ||
        (memberDecl0 is MethodDeclaration && memberDecl0.isGetter)) {
      // `C.getter(args)` is a function-expression invocation: the member
      // value is read first, then the arguments evaluate.
      final fieldValue = IdentifierReference(
        L,
        staticMemberName,
      ).getValue(ctx, e);
      return _invokeValue(ctx, fieldValue, e);
    }
    isStatic = true;
    // `E.m(receiver, ...)` — explicit application of an instance extension
    // member through the namespace. The receiver is the first argument and
    // binds the extension's `on` type parameters.
    final memberDecl = dec0.declaration;
    if (memberDecl is MethodDeclaration &&
        !memberDecl.isStatic &&
        !memberDecl.isGetter &&
        !memberDecl.isSetter) {
      final memberExt = extensionOfMember(ctx, memberDecl);
      if (memberExt != null) {
        final positional = e.argumentList.arguments;
        if (positional.isEmpty || positional.first is NamedArgument) {
          throw CompileError(
            'Extension ${memberExt.name} requires a receiver argument',
            e,
          );
        }
        final receiver = compileExpression(
          positional.first.argumentExpression,
          ctx,
        );
        final bindings = matchExtensionOn(ctx, receiver.type, memberExt);
        if (bindings == null) {
          throw CompileError(
            '${receiver.type} is not assignable to the `on` clause of '
            'extension ${memberExt.name}',
            e,
          );
        }
        final extParams =
            memberExt.declaration.typeParameters?.typeParameters ??
            const <TypeParameter>[];
        final result = _compileNonBridgeArgs(
          ctx,
          memberExt.library,
          memberDecl,
          e.argumentList,
          before: [receiver.boxIfNeeded(ctx)],
          typeArguments: e.typeArguments,
          seedGenerics: {
            for (var i = 0; i < bindings.length && i < extParams.length; i++)
              extParams[i].name.lexeme: bindings[i],
          },
          argIndexOffset: 1,
          source: e,
        );
        final s = ctx.svar('method_result');
        ctx.pushOp(
          Call(
            DeferredOrOffset(
              file: memberExt.library,
              name: memberExt.memberKey(memberDecl),
            ),
            result.args.ssa,
            result: s,
            typeArguments:
                extensionCallTypeArguments(
                  ctx,
                  memberExt,
                  memberDecl,
                  bindings,
                  result.resolveGenerics,
                ) ??
                _runtimeTypeArguments(ctx, e),
          ),
        );
        return Variable.of(
          ctx,
          s,
          result.returnType?.type?.copyWith(boxed: true) ??
              CoreTypes.dynamic.ref(ctx),
        );
      }
    }
  } else if (L.type == CoreTypes.function.ref(ctx) &&
      e.methodName.name == 'call') {
    // `fn.call(...)`: Function has no declared `call` member; the call is the
    // invocation itself, typed by the callee's own signature.
    return _invokeValue(ctx, L, e);
  } else if (L.type != CoreTypes.dynamic.ref(ctx)) {
    try {
      dec0 = resolveInstanceMethod(ctx, L.type, e.methodName.name, e);
    } on CompileError {
      // No such instance member: an extension member may apply.
      final found = resolveExtensionMember(
        ctx,
        L.type,
        e.methodName.name,
        arity: _positionalArity(e),
      );
      if (found != null) {
        return _invokeExtensionMethod(
          ctx,
          L,
          e,
          found.$1,
          found.$2,
          found.$3,
        );
      }
      final foundGetter = resolveExtensionMember(
        ctx,
        L.type,
        e.methodName.name,
        getter: true,
      );
      if (foundGetter == null &&
          e.methodName.name == 'noSuchMethod') {
        // `Object.noSuchMethod` is implicit — absent from all declaration
        // metadata. Dispatch dynamically.
        final (positional, named) = _compileCallArgs(ctx, e);
        return L.invoke(
          ctx,
          'noSuchMethod',
          positional,
          namedArgs: named,
        ).result;
      }
      if (foundGetter == null) rethrow;
      // `recv.m(args)` where extension member m is a getter — a
      // function-expression invocation: the getter's value is read first,
      // then the arguments evaluate.
      final getterValue = invokeExtensionGetter(
        ctx,
        L,
        foundGetter.$1,
        foundGetter.$2,
        foundGetter.$3,
      );
      return _invokeValue(ctx, getterValue, e);
    }
    final member = dec0.declaration;
    final isFieldOrGetter =
        member is FieldDeclaration ||
        (member is MethodDeclaration && member.isGetter);
    if (isFieldOrGetter) {
      if (e.target is SuperExpression) {
        // `super.m(args)` is a function-expression invocation: the member
        // value is read before the arguments evaluate.
        final property = L.getProperty(ctx, e.methodName.name);
        return _invokeValue(ctx, property, e);
      }
      // `receiver.field(...)` / `receiver.getter(...)`: the member's *value* is
      // invoked, not a method — property read then implicit `.call`. The
      // arguments evaluate before the member read (method-invocation order).
      final (prePositional, preNamed) = _compileCallArgs(ctx, e);
      final property = L.getProperty(ctx, e.methodName.name);
      return invokeClosure(
        ctx,
        null,
        property,
        null,
        positional: prePositional,
        named: preNamed,
        typeArguments: e.typeArguments?.arguments.toList(),
      ).result;
    }
    isStatic = false;
  } else {
    isStatic = false;
  }

  if (dec0?.isBridge == true) {
    final br = dec0!.bridge!;
    final fd = br is BridgeMethodDef
        ? br.functionDescriptor
        : (br as BridgeConstructorDef).functionDescriptor;
    final receiverTypeParameters = isStatic
        ? const <String, TypeRef>{}
        : _bridgeClassTypeArguments(ctx, L.type, dec0.sourceLib);
    argsPair = compileArgumentListWithBridge(
      ctx,
      e.argumentList,
      fd,
      before: [],
      typeParameters: receiverTypeParameters,
    );
    // Static calls on generic bridge classes (e.g. `Stream.fromIterable`)
    // infer the class's own type parameters — `T` in `Iterable<T>` — from
    // the argument types, which then resolve `returns:` annotations.
    final classGenericNames =
        isStatic
            ? switch (ctx.topLevelDeclarationsMap[staticType!
                .file]?[staticType.name]?.bridge) {
                BridgeClassDef b => b.type.generics.keys.toSet(),
                _ => const <String>{},
              }
            : const <String>{};
    _inferBridgeTypeParameters(
      fd,
      argsPair.args,
      bridgeTypeParameters,
      inferableNames: classGenericNames,
    );
    mReturnType =
        bridgeFunctionReturnType(
          ctx,
          fd,
          specifiedType: isStatic ? staticType : L.type,
          typeParameters: bridgeTypeParameters,
        ).toAlwaysReturnType(
          ctx,
          isStatic ? staticType : L.type,
          argsPair.args.map((a) => a.type).toList(),
          argsPair.namedArgs.map((k, v) => MapEntry(k, v.type)),
          typeArgs:
              e.typeArguments?.arguments
                  .map((t) => TypeRef.fromAnnotation(ctx, ctx.library, t))
                  .toList() ??
              const [],
        );
    // Instance calls that carry no named or explicit type arguments route
    // through the modern invocation path, which preserves intrinsic
    // optimizations for core types. The argument vector stays padded with
    // null placeholders so generated wrappers keep the legacy flattened ABI.
    // The declared return type (including inferred generics and
    // parameter-type dependencies) still applies to the result.
    if (!isStatic && e.typeArguments == null && argsPair.namedArgs.isEmpty) {
      final invokeResult = L
          .invoke(ctx, e.methodName.name, argsPair.args)
          .result;
      final preciseType = mReturnType?.type;
      if (preciseType != null) {
        return invokeResult.copyWith(
          type: preciseType.copyWith(boxed: invokeResult.type.boxed),
        );
      }
      return invokeResult;
    }
  } else if (L.type == CoreTypes.dynamic.ref(ctx)) {
    argsPair = compileArgumentListWithDynamic(ctx, e.argumentList, before: [L]);
  } else {
    final dec = dec0!.declaration!;
    final result = _compileNonBridgeArgs(
      ctx,
      dec0.sourceLib,
      dec,
      e.argumentList,
      before: [if (!isStatic) L],
      typeArguments: e.typeArguments,
      source: e,
      seedGenerics: !isStatic && dec is MethodDeclaration
          ? _classTypeArguments(ctx, L.type, dec0.sourceLib, dec)
          : const {},
    );
    argsPair = result.args;
    mReturnType = result.returnType;
  }

  final args = argsPair.args;
  final namedArgs = argsPair.namedArgs;

  final argTypes = args.map((e) => e.type).toList();
  final namedArgTypes = namedArgs.map(
    (key, value) => MapEntry(key, value.type),
  );

  final result = ctx.svar('method_result');
  if (isStatic) {
    if (dec0!.isBridge) {
      ctx.pushOp(
        InvokeExternal(
          result,
          ctx.bridgeStaticFunctionIndices[staticType!
              .file]!['${staticType.name}.$staticMemberName']!,
          argsPair.ssa,
        ),
      );
    } else {
      final offset = DeferredOrOffset.lookupStatic(
        ctx,
        staticType!.file,
        staticType.name,
        staticMemberName,
      );
      final callArguments = [...argsPair.ssa];
      final declaration = dec0.declaration;
      if (declaration is ConstructorDeclaration &&
          declaration.factoryKeyword == null) {
        callArguments.add(pushRuntimeTypeId(ctx, staticType));
      }
      ctx.pushOp(
        Call(
          offset,
          callArguments,
          result: result,
          typeArguments: _runtimeTypeArguments(ctx, e),
        ),
      );
    }
  } else {
    // The fixed target for a direct call: the nearest class at-or-above
    // the receiver's known type declaring the method. Only an allocation-
    // exact receiver (or `super`, whose link is already positioned) can
    // direct-dispatch: the callee takes its declaring class's link as
    // `this`, which requires a statically-known hop distance.
    final linkType = switch ((e.target is SuperExpression, L.exactType)) {
      (true, _) => L.concreteTypes.first,
      (false, final exactType?) => exactType,
      _ => null,
    };
    final name = e.methodName.name;
    var directOwner =
        dec0?.isBridge == false && linkType != null
            ? memberOwner(ctx, linkType, name)
            : null;
    if (directOwner == null &&
        dec0?.isBridge == false &&
        e.target is! SuperExpression &&
        L.exactType == null &&
        L.concreteTypes.length == 1) {
      // The receiver may hold a subclass: the fixed target must not be
      // overridden by any descendant of its static type.
      directOwner = directMemberOwner(ctx, L.concreteTypes.first, name);
    }
    // A callee needs `this` bound to its declaring link only when its body
    // uses `super`; otherwise any link — including the dispatch root —
    // works, which also allows devirtualizing non-exact receivers.
    final needsLink =
        directOwner != null &&
        memberNeedsOwnerLink(ctx, directOwner, name);
    if (directOwner != null && (linkType != null || !needsLink)) {
      final offset = DeferredOrOffset(
        file: directOwner.file,
        className: directOwner.name,
        methodType: 2,
        name: name,
      );
      ctx.pushOp(
        Call(
          offset,
          [
            if (linkType != null && needsLink)
              ownerLinkSsa(ctx, argsPair.ssa.first, linkType, directOwner)
            else
              argsPair.ssa.first,
            ...argsPair.ssa.skip(1),
          ],
          result: result,
          typeEnvironmentReceiver: L.boxIfNeeded(ctx).ssa,
          typeArguments: _runtimeTypeArguments(ctx, e),
        ),
      );
    } else {
      ctx.pushOp(
        InvokeDynamic(
          result,
          L.boxIfNeeded(ctx).ssa,
          e.methodName.name,
          dec0?.isBridge == true
              ? argsPair.ssa
              : argsPair.ssa.skip(1).toList(),
          // Bridge methods use their legacy padded positional ABI. Evaluated
          // methods keep source-level positional and named call metadata.
          positionalCount: dec0?.isBridge == true
              ? argsPair.ssa.length
              : argsPair.args.length,
          namedNames: dec0?.isBridge == true
              ? const []
              : argsPair.namedArgs.keys.toList(),
          callerLibrary: ctx.library,
          typeArguments:
              e.typeArguments?.arguments
                  .map((type) => TypeRef.fromAnnotation(ctx, ctx.library, type))
                  .map((type) => type.runtimeTypeId(ctx))
                  .toList() ??
              const [],
        ),
      );
    }
  }

  mReturnType ??= AlwaysReturnType.fromInstanceMethodOrBuiltin(
    ctx,
    isStatic ? staticType! : L.type,
    staticMemberName,
    argTypes,
    namedArgTypes,
    $static: isStatic,
  );

  final v = Variable.of(
    ctx,
    result,
    mReturnType?.type?.copyWith(boxed: true) ?? CoreTypes.dynamic.ref(ctx),
  );

  return v;
}

Map<String, TypeRef> _bridgeClassTypeArguments(
  CompilerContext ctx,
  TypeRef receiver,
  int declarationLibrary,
) {
  final resolved = receiver.resolveTypeChain(ctx);
  final declaration =
      ctx.topLevelDeclarationsMap[declarationLibrary]?[resolved.name];
  final bridge = declaration?.bridge;
  if (bridge is! BridgeClassDef) return const {};
  final names = bridge.type.generics.keys.toList();
  return {
    for (
      var index = 0;
      index < names.length && index < resolved.specifiedTypeArgs.length;
      index++
    )
      names[index]: resolved.specifiedTypeArgs[index],
  };
}

void _inferBridgeTypeParameters(
  BridgeFunctionDef function,
  List<Variable> arguments,
  Map<String, TypeRef> inferred, {
  Set<String> inferableNames = const {},
}) {
  void infer(BridgeTypeRef formal, TypeRef actual) {
    final reference = formal.ref;
    if (reference != null &&
        (function.generics.containsKey(reference) ||
            inferableNames.contains(reference))) {
      inferred[reference] = actual;
      return;
    }
    final genericFunction = formal.gft;
    final actualFunction = actual.functionType;
    if (genericFunction != null && actualFunction != null) {
      final actualReturn = actualFunction.returnType.type;
      if (actualReturn != null) {
        infer(genericFunction.returns.type, actualReturn);
      }
      return;
    }
    final formalArguments = formal.typeArgs;
    final actualArguments = actual.specifiedTypeArgs;
    for (
      var index = 0;
      index < formalArguments.length && index < actualArguments.length;
      index++
    ) {
      infer(formalArguments[index].type, actualArguments[index]);
    }
  }

  for (
    var index = 0;
    index < function.params.length && index < arguments.length;
    index++
  ) {
    infer(function.params[index].type.type, arguments[index].type);
  }
}

/// Emits a call to a resolved extension member: `E.m(receiver, args...)` —
/// the receiver prepended to the argument vector, the extension's `on`
/// bindings plus the method's resolved type arguments passed in the type
/// environment.
Variable _invokeExtensionMethod(
  CompilerContext ctx,
  Variable receiver,
  MethodInvocation call,
  EvalExtension ext,
  MethodDeclaration member,
  List<TypeRef> bindings,
) {
  final extParams =
      ext.declaration.typeParameters?.typeParameters ??
      const <TypeParameter>[];
  final result = _compileNonBridgeArgs(
    ctx,
    ext.library,
    member,
    call.argumentList,
    before: [receiver.boxIfNeeded(ctx)],
    typeArguments: call.typeArguments,
    seedGenerics: {
      for (var i = 0; i < bindings.length && i < extParams.length; i++)
        extParams[i].name.lexeme: bindings[i],
    },
    source: call,
  );
  final s = ctx.svar('method_result');
  ctx.pushOp(
    Call(
      DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
      result.args.ssa,
      result: s,
      typeArguments:
          extensionCallTypeArguments(
            ctx,
            ext,
            member,
            bindings,
            result.resolveGenerics,
          ) ??
          _runtimeTypeArguments(ctx, call),
    ),
  );
  return Variable.of(
    ctx,
    s,
    result.returnType?.type?.copyWith(boxed: true) ??
        CoreTypes.dynamic.ref(ctx),
  );
}

List<int> _runtimeTypeArguments(CompilerContext ctx, MethodInvocation call) =>
    call.typeArguments?.arguments
        .map((type) => TypeRef.fromAnnotation(ctx, ctx.library, type))
        .map((type) => type.runtimeTypeId(ctx))
        .toList() ??
    const [];

Map<String, TypeRef> _classTypeArguments(
  CompilerContext ctx,
  TypeRef receiver,
  int ownerLibrary,
  MethodDeclaration method,
) {
  final owner = method.parent?.parent;
  if (owner is! ClassDeclaration && owner is! MixinDeclaration) {
    return const {};
  }
  // Worklist over supertypes: extends, `with` applications, and implements
  // edges each carry the substitutions accumulated along their own path.
  final worklist = <(TypeRef, Map<(String, int), TypeRef>)>[(receiver, {})];
  final seen = <String>{};
  while (worklist.isNotEmpty) {
    final (current, substitutions) = worklist.removeLast();
    if (!seen.add('${current.file}:${current.name}')) continue;
    if (owner is ClassDeclaration &&
        current.file == ownerLibrary &&
        current.name == owner.namePart.typeName.lexeme) {
      final parameters =
          owner.namePart.typeParameters?.typeParameters ?? const [];
      return {
        for (var index = 0; index < parameters.length; index++)
          parameters[index].name.lexeme:
              index < current.specifiedTypeArgs.length
              ? current.specifiedTypeArgs[index]
              : CoreTypes.dynamic.ref(ctx),
      };
    }
    final decl =
        ctx.topLevelDeclarationsMap[current.file]?[current.name]?.declaration;
    if (decl == null) continue;
    // Fold the current type's arguments into the substitution map so a
    // `with M<T>` clause resolves `T` to the receiver-provided argument.
    final levelParams = current.resolveTypeChain(ctx).genericParams;
    final nextSubstitutions = {
      ...substitutions,
      for (var index = 0; index < levelParams.length; index++)
        (
          'class:${current.file}:${current.name}',
          index,
        ): index < current.specifiedTypeArgs.length
            ? current.specifiedTypeArgs[index]
            : levelParams[index].extendsType ?? CoreTypes.dynamic.ref(ctx),
    };
    if (owner is MixinDeclaration) {
      // The folded method's owner is a mixin: find the `with M<args>` entry
      // on the current class (or on a mixin it applies) and map the mixin's
      // parameters to its applied arguments.
      final applied = findMixinApplication(
        ctx,
        decl,
        current.file,
        current.name,
        owner,
        ownerLibrary,
        nextSubstitutions,
      );
      if (applied != null) {
        return applied;
      }
    }
    final resolved = current.resolveTypeChain(ctx);
    final parent = resolved.extendsType;
    if (parent != null && !parent.hasSameDeclarationAs(current)) {
      worklist.add((
        parent.substituteTypeParameters(nextSubstitutions),
        nextSubstitutions,
      ));
    }
    final (_, mixinTypes, interfaceTypes, _) = classLikeClauses(decl);
    for (final supertype in [...mixinTypes, ...interfaceTypes]) {
      final resolved2 = _resolveAppliedInterface(
        ctx,
        current,
        decl,
        supertype,
        nextSubstitutions,
      );
      if (resolved2 != null) worklist.add((resolved2, nextSubstitutions));
    }
  }
  return const {};
}

/// Resolves an `implements`/`on` entry of [decl] (on receiver [current]) to
/// a concrete [TypeRef]: bare arguments naming one of [current]'s type
/// parameters become parameter references, then [substitutions] maps those
/// to the receiver-provided arguments.
TypeRef? _resolveAppliedInterface(
  CompilerContext ctx,
  TypeRef current,
  Declaration decl,
  NamedType interface,
  Map<(String, int), TypeRef> substitutions,
) {
  final prefix = interface.importPrefix;
  final name = prefix == null
      ? interface.name.lexeme
      : '${prefix.name.lexeme}.${interface.name.lexeme}';
  final base = ctx.visibleTypes[current.file]?[name];
  if (base == null) return null;
  final args = interface.typeArguments?.arguments;
  if (args == null) return base;
  final classParams = classLikeClauses(decl).$4?.typeParameters;
  return base.copyWith(
    specifiedTypeArgs: [
      for (var i = 0; i < args.length; i++)
        (resolveAppliedTypeArgument(
                  ctx,
                  current.file,
                  current.name,
                  classParams,
                  args[i],
                ) ??
                TypeRef.fromAnnotation(ctx, current.file, args[i]))
            .substituteTypeParameters(substitutions),
    ],
  );
}


/// Resolves [methodName] on [instanceType] to its declaration or bridge. The
/// declaration is normally a [MethodDeclaration]; when [methodName] names a
/// *field* holding a callable (invoked via implicit `.call`), it is the
/// enclosing [FieldDeclaration] instead.
DeclarationOrBridge<ClassMember, BridgeMethodDef> resolveInstanceMethod(
  CompilerContext ctx,
  TypeRef instanceType,
  String methodName, [
  AstNode? source,
  TypeRef? bottomType,
]) {
  if (instanceType.isTypeParameter) {
    final bound = instanceType.typeParameterBound ?? CoreTypes.dynamic.ref(ctx);
    if (bound == CoreTypes.dynamic.ref(ctx)) {
      throw CompileError(
        'Cannot resolve $methodName on unbounded type parameter $instanceType',
        source,
      );
    }
    return resolveInstanceMethod(
      ctx,
      bound,
      methodName,
      source,
      bottomType ?? instanceType,
    );
  }
  final dec0 =
      ctx.topLevelDeclarationsMap[instanceType.file]?[instanceType.name];
  if (dec0 == null) {
    throw CompileError(
      'Missing declaration for instance method $methodName on '
      '${instanceType.name}',
      source,
    );
  }
  final bottomType0 = bottomType ?? instanceType;
  if (dec0.isBridge) {
    // Bridge
    final bridge = dec0.bridge!;
    final method = bridge is BridgeClassDef
        ? bridge.methods[methodName]
        : (bridge as BridgeEnumDef).methods[methodName];
    if (method == null) {
      final $extendsBridgeType = bridge is BridgeClassDef
          ? bridge.type.$extends
          : null;
      if ($extendsBridgeType == null && bridge is! BridgeEnumDef) {
        throw CompileError('Unknown method $bottomType0.$methodName', source);
      }
      final $extendsType = bridge is BridgeEnumDef
          ? CoreTypes.enumType.ref(ctx)
          : TypeRef.fromBridgeTypeRef(
              ctx,
              $extendsBridgeType!,
              specifiedType: bottomType0,
            );
      return resolveInstanceMethod(
        ctx,
        $extendsType,
        methodName,
        source,
        bottomType0,
      );
    }
    return DeclarationOrBridge(instanceType.file, bridge: method);
  }

  final dec =
      ctx.instanceDeclarationsMap[instanceType.file]![instanceType
          .name]![methodName] ??
      ctx.instanceDeclarationsMap[instanceType.file]![instanceType
          .name]!['$methodName*g'];

  if (dec != null) {
    // A field holding a callable resolves to its FieldDeclaration, so callers
    // can distinguish `a.field()` (invoke `.call` on the field's value) from a
    // true method invocation.
    return DeclarationOrBridge(
      instanceType.file,
      declaration: dec is VariableDeclaration
          ? dec.parent!.parent as ClassMember
          : dec as ClassMember,
    );
  } else if (dec0.declaration is EnumDeclaration) {
    // Enum declarations resolve undeclared members through the Enum bridge
    // declaration (and transitively Object).
    return resolveInstanceMethod(
      ctx,
      CoreTypes.enumType.ref(ctx),
      methodName,
      source,
      bottomType0,
    );
  } else {
    final (extendsNamed, mixins, interfaces, _) = classLikeClauses(
      dec0.declaration,
    );
    TypeRef? resolveClauseType(NamedType named) {
      final prefix = named.importPrefix;
      final name = prefix == null
          ? named.name.lexeme
          : '${prefix.name.lexeme}.${named.name.lexeme}';
      final direct = ctx.visibleTypes[instanceType.file]![name];
      if (direct != null) return direct;
      final alias = ctx.typeAliases[instanceType.file]?[name];
      return alias == null
          ? null
          : resolveTypeAlias(
              ctx,
              instanceType.file,
              alias,
              typeArgs: named.typeArguments?.arguments,
            );
    }

    if (extendsNamed != null) {
      final $supertype =
          resolveClauseType(extendsNamed) ??
          (throw CompileError(
            'Superclass ${extendsNamed.name.lexeme} not found',
            source,
          ));
      final result = _tryResolveInstanceMethod(
        ctx,
        $supertype,
        methodName,
        source,
        bottomType0,
      );
      if (result != null) return result;
    }
    for (final interface in [...mixins, ...interfaces]) {
      final ifaceType = resolveClauseType(interface);
      if (ifaceType == null) continue;
      final result = _tryResolveInstanceMethod(
        ctx,
        ifaceType,
        methodName,
        source,
        bottomType0,
      );
      if (result != null) return result;
    }
    return resolveInstanceMethod(
      ctx,
      CoreTypes.object.ref(ctx),
      methodName,
      source,
      bottomType0,
    );
  }
}

/// Whether [instanceType] declares or inherits an instance member named
/// [methodName] — probes [resolveInstanceMethod] so callers can fall back to
/// extension members when instance lookup fails.
bool hasInstanceMethod(
  CompilerContext ctx,
  TypeRef instanceType,
  String methodName,
) {
  try {
    resolveInstanceMethod(ctx, instanceType, methodName);
    return true;
  } on CompileError {
    return false;
  }
}

/// [resolveInstanceMethod], returning null when [instanceType] and its chain
/// lack [methodName] instead of throwing.
DeclarationOrBridge<ClassMember, BridgeMethodDef>?
_tryResolveInstanceMethod(
  CompilerContext ctx,
  TypeRef instanceType,
  String methodName,
  AstNode? source,
  TypeRef bottomType0,
) {
  try {
    return resolveInstanceMethod(
      ctx,
      instanceType,
      methodName,
      source,
      bottomType0,
    );
  } on CompileError catch (e) {
    if (e.message.startsWith('Unknown method')) return null;
    rethrow;
  }
}

DeclarationOrBridge<ClassMember, BridgeDeclaration> resolveStaticMethod(
  CompilerContext ctx,
  TypeRef classType,
  String methodName,
) {
  final method =
      ctx.topLevelDeclarationsMap[classType
          .file]!['${classType.name}.$methodName'] ??
      ctx.topLevelDeclarationsMap[classType
          .file]!['${classType.name}.$methodName*g'];
  if (method != null) {
    if (method.declaration != null) {
      final member = method.declaration!;
      return DeclarationOrBridge(
        classType.file,
        declaration:
            member is VariableDeclaration
                ? member.parent!.parent as ClassMember
                : member as ClassMember,
      );
    } else {
      return DeclarationOrBridge(classType.file, bridge: method.bridge!);
    }
  }

  throw CompileError('Cannot find static method $classType.$methodName');
}

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

/// The result of [_compileNonBridgeArgs].
class _ResolvedArgs {
  _ResolvedArgs(
    this.args,
    this.returnType,
    this.boxedBySubstitution,
    this.resolveGenerics,
    this.classTypeParameters,
  );

  final ArgumentListResult args;

  /// The return type after substituting resolved generics into the declared
  /// return annotation, or null when the annotation isn't generic-dependent.
  final AlwaysReturnType? returnType;

  /// Whether generic substitution narrowed the language return type without
  /// changing the callee's compiled ABI, forcing the result to stay boxed.
  /// Null when the return annotation doesn't reference type parameters.
  final bool? boxedBySubstitution;

  /// The call's resolved generic bindings by parameter name — for constructor
  /// calls these hold the class type arguments inferred from the arguments
  /// (or the parameters' bounds when unconstrained).
  final Map<String, TypeRef> resolveGenerics;

  /// The declaring class's type parameters, in order, when [args] belongs to
  /// a constructor declaration.
  final List<TypeParameter>? classTypeParameters;
}

/// Compiles the argument list for a call to a non-bridge declaration [dec],
/// resolving generic type parameters at the call site. [seedGenerics] provides
/// receiver-class type arguments (for instance calls); [typeArguments] are the
/// call's explicit type arguments, whose presence disables inference.
_ResolvedArgs _compileNonBridgeArgs(
  CompilerContext ctx,
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
      ClassDeclaration() ||
      MixinDeclaration() ||
      ClassTypeAlias() => classLikeClauses(owner as Declaration).$4?.typeParameters,
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
      ctx,
      sourceLib,
      typeParams,
      typeArguments?.arguments.toList(),
      resolveGenerics,
      source!,
    );
  }

  bool? boxedBySubstitution;
  if (returnAnnotation != null &&
      _annotationUsesTypeParameters(returnAnnotation, resolveGenerics)) {
    // Substitution narrows the language type, not the compiled callee's ABI.
    boxedBySubstitution = true;
  }

  final argsPair = compileArgumentList(
    ctx,
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
  );

  AlwaysReturnType? returnType;
  if (returnAnnotation != null && resolveGenerics.isNotEmpty) {
    final resolvedReturn = TypeRef.fromAnnotation(
      ctx,
      sourceLib,
      returnAnnotation,
      typeParameters: resolveGenerics,
    );
    returnType = AlwaysReturnType(
      resolvedReturn,
      returnAnnotation.question != null,
    );
  }
  return _ResolvedArgs(
    argsPair,
    returnType,
    boxedBySubstitution,
    resolveGenerics,
    classParams,
  );
}


/// Resolves the receiver for a `super.m(args)` call: finds the nearest
/// concrete member above `this` — mixin-clause members first (below the
/// member's own layer), then the superclass chain — and returns the
/// appropriately-levelled super-link variable.
///
/// When no concrete member exists (only abstract declarations or none),
/// the call is dispatched to `noSuchMethod` on the real receiver and the
/// result is returned in the second position.
(Variable, Variable?) _resolveSuperReceiver(
  CompilerContext ctx,
  MethodInvocation e,
  Variable L,
) {
  final memberName = e.methodName.name;
  final lib = ctx.enclosingLibrary ?? ctx.library;
  final (_, withClause, _, _) = classLikeClauses(ctx.currentClass!);
  // `with` mixins below the member's own layer, nearest first (all of them
  // for the class's own members); their members fold onto the applying
  // class, so a hit dispatches against it. Then the superclass's own chain.
  var stop = withClause.length;
  final declaring = ctx.memberDeclaringClass;
  if (declaring != null) {
    final declaringName = switch (declaring) {
      ClassDeclaration() ||
      MixinDeclaration() ||
      ClassTypeAlias() ||
      EnumDeclaration() => declarationName(declaring),
      _ => null,
    };
    for (var j = 0; j < withClause.length; j++) {
      if (withClause[j].name.lexeme == declaringName) {
        stop = j;
        break;
      }
    }
  }
  var found = false;
  for (var j = stop - 1; !found && j >= 0; j--) {
    final mixinRef = clauseNamedType(ctx, lib, withClause[j]);
    if (mixinRef == null) continue;
    final memberDecl = ctx
            .instanceDeclarationsMap[mixinRef.file]?[mixinRef.name]
                ?[memberName] ??
        ctx.instanceDeclarationsMap[mixinRef
            .file]?[mixinRef.name]?[memberKey(memberName, 0)];
    if (memberDecl == null) continue;
    // Abstract mixin members defer to the next mixin or superclass.
    if (memberDecl is MethodDeclaration && !memberDecl.isComplete) {
      continue;
    }
    final appType = TypeRef.lookupDeclaration(ctx, lib, ctx.currentClass!);
    L = Variable.of(ctx, L.ssa, appType, concreteTypes: [appType]);
    found = true;
  }
  final superStart = L.type;
  var owner = superStart.resolveTypeChain(ctx);
  // Search the superclass chain for a concrete member without emitting
  // `loadsuper` ops yet — a failed walk must not leave dead loads that
  // execute on a null receiver.
  final superTypes = <TypeRef>[];
  // Kind of the nearest *abstract* declaration, if any is seen before a
  // concrete implementation: decides the Invocation shape for a noSuchMethod
  // dispatch (getter read vs. method call).
  bool? abstractGetter;
  while (!found) {
    // `Object.noSuchMethod` exists on every class but is implicit — it is
    // not present in bridge/declaration metadata.
    if (memberName == 'noSuchMethod') {
      found = true;
      break;
    }
    // Abstract re-declarations have no body — skip them like runtime
    // dispatch does; the implementation lives deeper in the chain.
    if (concreteMemberDecl(ctx, owner, memberName, kind: 2) != null ||
        concreteMemberDecl(ctx, owner, memberName, kind: 0) != null) {
      found = true;
      break;
    }
    if (abstractGetter == null) {
      final decls = ctx.instanceDeclarationsMap[owner.file]?[owner.name];
      if (decls != null) {
        if (decls.containsKey(memberKey(memberName, 0))) {
          abstractGetter = true;
        } else if (decls.containsKey(memberName)) {
          abstractGetter = false;
        }
      }
    }
    final bridgeOwner =
        ctx.topLevelDeclarationsMap[owner.file]?[owner.name]?.bridge;
    if (bridgeOwner is BridgeClassDef &&
        bridgeOwner.methods.containsKey(memberName)) {
      found = true;
      break;
    }
    final parent = owner.extendsType;
    if (parent == null) break;
    owner = parent.resolveTypeChain(ctx);
    superTypes.add(owner);
  }
  if (!found) {
    return (
      L,
      _invokeSuperNoSuchMethod(ctx, e, abstractGetter ?? false),
    );
  }
  for (final superType in superTypes) {
    L = Variable.ssa(
      ctx,
      LoadSuper(ctx.svar('super'), L.ssa),
      superType,
      concreteTypes: [superType],
    );
  }
  return (L, null);
}

/// `super.m(args)` where no concrete `m` exists above `this` dispatches to
/// `noSuchMethod` on the real receiver with an Invocation describing the
/// call — the semantics for abstract super-members.
Variable _invokeSuperNoSuchMethod(
  CompilerContext ctx,
  MethodInvocation e,
  bool abstractGetter,
) {
  final coreLib = ctx.libraryMap['dart:core']!;
  final bridge = ctx.bridgeStaticFunctionIndices[coreLib]!;

  Variable symbolFor(String name) {
    final arg = BuiltinValue(stringval: name).push(ctx).boxIfNeeded(ctx);
    return Variable.ssa(
      ctx,
      InvokeExternal(ctx.svar('sym'), bridge['Symbol.']!, [arg.ssa]),
      CoreTypes.symbol.ref(ctx),
    );
  }

  final $this = ctx.lookupLocal('#this')!;

  // `super.m(args)` on an abstract getter is a function-expression
  // invocation: fetch the getter's value via noSuchMethod, then invoke it.
  if (abstractGetter) {
    final invocation = Variable.ssa(
      ctx,
      InvokeExternal(ctx.svar('inv'), bridge['Invocation.getter']!, [
        symbolFor(e.methodName.name).ssa,
      ]),
      CoreTypes.invocation.ref(ctx),
    );
    final getterValue = $this.invoke(ctx, 'noSuchMethod', [
      invocation,
    ]).result;
    return _invokeValue(ctx, getterValue, e);
  }

  final (positional, named) = _compileCallArgs(ctx, e);
  final listType = CoreTypes.list.ref(ctx).copyWith(
    specifiedTypeArgs: [CoreTypes.dynamic.ref(ctx).copyWith(boxed: true)],
  );
  final list = Variable.ssa(
    ctx,
    NewList(ctx.svar('list')),
    listType.copyWith(boxed: false),
  );
  for (final arg in positional) {
    ctx.pushOp(ListAppend(list.ssa, arg.boxIfNeeded(ctx).ssa));
  }
  final invArgs = [
    symbolFor(e.methodName.name).ssa,
    list.boxIfNeeded(ctx).ssa,
  ];
  if (named.isNotEmpty) {
    final mapType = CoreTypes.map.ref(ctx).copyWith(
      specifiedTypeArgs: [
        CoreTypes.symbol.ref(ctx).copyWith(boxed: true),
        CoreTypes.dynamic.ref(ctx).copyWith(boxed: true),
      ],
    );
    final map = Variable.ssa(
      ctx,
      NewMap(ctx.svar('map')),
      mapType.copyWith(boxed: false),
    );
    for (final entry in named.entries) {
      ctx.pushOp(
        MapSet(
          map.ssa,
          symbolFor(entry.key).ssa,
          entry.value.boxIfNeeded(ctx).ssa,
        ),
      );
    }
    invArgs.add(map.boxIfNeeded(ctx).ssa);
  }
  final invocation = Variable.ssa(
    ctx,
    InvokeExternal(
      ctx.svar('inv'),
      bridge['Invocation.method']!,
      invArgs,
    ),
    CoreTypes.invocation.ref(ctx),
  );
  return $this.invoke(ctx, 'noSuchMethod', [invocation]).result;
}

/// Invokes [value] — the read result of a member *value* (field/getter/
/// callable) — with the call's argument list. The member read already
/// happened; this is the function-expression invocation.
Variable _invokeValue(CompilerContext ctx, Variable value, MethodInvocation e) {
  return invokeClosure(
    ctx,
    null,
    value,
    e.argumentList,
    typeArguments: e.typeArguments?.arguments.toList(),
  ).result;
}

/// Compiles a call's argument list into positional/named variable pairs. Used
/// when the callee is a member *value* (field or getter) whose read must be
/// sequenced after the arguments per method-invocation evaluation order.
(List<Variable>, Map<String, Variable>) _compileCallArgs(
  CompilerContext ctx,
  MethodInvocation e,
) {
  final positional = <Variable>[];
  final named = <String, Variable>{};
  for (final arg in e.argumentList.arguments) {
    if (arg is NamedArgument) {
      named[arg.name.lexeme] = compileExpression(
        arg.argumentExpression,
        ctx,
      );
    } else {
      positional.add(compileExpression(arg.argumentExpression, ctx));
    }
  }
  return (positional, named);
}
