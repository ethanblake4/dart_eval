import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import '../member/call_signature.dart';
import '../member/resolved_member.dart';
import 'deferred.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import '../builtins.dart';
import '../values/abi.dart';
import 'binder.dart';
import 'bound_call.dart';
import 'call.dart';
import 'accessors.dart';
import 'devirtualizer.dart';
import 'intrinsics.dart';
import 'targets.dart';

/// Turns a [CallSite] into a [CallTarget] and emits the call. Resolution
/// consults only the receiver's static type and facts plus the syntactic
/// shape; arguments are compiled by the [ArgumentBinder].
final class CallResolver {
  const CallResolver(this.ctx);

  final CompilerContext ctx;

  /// `value(args)` — a function-expression invocation. When [ref] is given
  /// a statically-known target short-circuits to a direct [Call] without
  /// materializing the callee.
  Variable invokeValue(CallSite site, {Reference? ref, Variable? callee}) =>
      invokeValueWithArgs(site, ref: ref, callee: callee).$1;

  /// [invokeValue] plus the bound call — callers needing the post-coercion
  /// argument values read them from the [BoundCall].
  (Variable, BoundCall) invokeValueWithArgs(
    CallSite site, {
    Reference? ref,
    Variable? callee,
  }) {
    final known = ref?.getDirectCall(ctx, site.source);
    final callable = known == null
        ? (ref?.getValue(ctx, site.source) ?? callee!)
        : null;
    final target = ClosureCall(
      callee: callable,
      known: known is StaticCall ? known : null,
    );
    final bound = ArgumentBinder(
      ctx,
    ).bindSuppliedOnly(target, site, callee: callable);
    return (_emitValue(target, bound, callable, site), bound);
  }

  Variable _emitValue(
    ClosureCall target,
    BoundCall bound,
    Variable? callable,
    CallSite site,
  ) {
    if (target.known != null) {
      return target.emit(ctx, bound);
    }
    final callableVar = callable!;
    // `x(...)` where `x` isn't a function is an implicit `x.call(...)` — an
    // extension `call` member applies statically before the dynamic
    // fallback.
    if (!callableVar.type.isAssignableTo(ctx, CoreTypes.function.ref(ctx))) {
      if (!ctx.memberLookup.hasInstanceMember(
            callableVar.type,
            MemberName.method('call'),
          ) &&
          resolveExtensionMember(
                ctx,
                callableVar.type,
                'call',
                arity: bound.positional.length,
              ) !=
              null) {
        return invokeOperator(
          callableVar,
          'call',
          [for (final a in bound.positional) a.value],
          namedArgs: {for (final e in bound.named) e.$1: e.$2.value},
        ).result;
      }
    }
    return target.emit(ctx, bound);
  }

  /// The [Variable] behind a [Receiver] that carries a concrete value.
  Variable _receiverVariable(Receiver r) => switch (r) {
    ValueReceiver(:final value) => value,
    ExtensionApplicationReceiver(:final value) => value,
    TypeLiteralReceiver(:final value) => value,
    ExtensionNamespaceReceiver(:final value) => value,
    SuperReceiver(:final self) => self,
    PrefixReceiver() => throw CompileError('Unresolved import prefix'),
  };

  /// `receiver.m(args)` — an instance-target invocation. Member resolution
  /// consults the receiver's static type (bound extensions, type literals,
  /// records, interface members, extensions, `dynamic`); emission routes
  /// through the [CallTarget] pipeline — [VirtualCall] refined by
  /// [Devirtualizer], [DynamicCall], [MemberValueCall], or a bridge path.
  Variable invokeMethod(Variable L, MethodInvocation e, {TypeRef? bound}) {
    CallSite callSite() => CallSite(
      shape: CallShape.fromArgumentList(
        e.argumentList,
        e.typeArguments?.arguments,
      ),
      source: e,
      inConstContext: e.inConstantContext,
    );

    // `E(x).m(...)` — explicit application pins member resolution to E.
    if (extensionPinOf(ctx, e.target, L.type) case final boundExt?) {
      final member = extensionMember(boundExt.ext, e.methodName.name);
      if (member == null) {
        // `E(x).g(...)`: the getter's result is the call target.
        final getter = extensionMember(
          boundExt.ext,
          e.methodName.name,
          getter: true,
        );
        if (getter != null) {
          return invokeValue(
            callSite(),
            callee: invokeExtensionGetter(
              ctx,
              L,
              boundExt.ext,
              getter,
              boundExt.onBindings,
            ),
          );
        }
        throw CompileError(
          'Extension ${boundExt.ext.name} has no member ${e.methodName.name}',
          e,
        );
      }
      return invokeExtensionMethod(
        ctx,
        L,
        e,
        boundExt.ext,
        member,
        boundExt.onBindings,
      );
    }
    TypeRef? mReturnType;
    final bridgeTypeParameters = <String, TypeRef>{};

    ResolvedMember? resolved;
    final bool isStatic;
    TypeRef? staticType;

    BoundCall argsPair;

    // `C.new(...)` invokes the unnamed constructor.
    final staticMemberName = ctorNameOf(e.methodName.name);

    final receiver =
        receiverOf(ctx, L, pin: extensionPinOf(ctx, e.target, L.type));
    EvalExtension? namespaceExt;
    if (receiver is ExtensionNamespaceReceiver) {
      // `E.m(...)` — a member of the extension's namespace: an instance
      // member applied explicitly (receiver is the first argument) or a
      // static member.
      namespaceExt = receiver.ext;
      final member = ctx.memberLookup.extensionMember(
        receiver.ext,
        staticMemberName,
        MemberKind.method,
      );
      resolved = member == null
          ? null
          : ResolvedMember(member, CoreTypes.dynamic.ref(ctx));
      if (resolved == null) {
        throw CompileError(
          'Cannot find member ${receiver.ext.name}.$staticMemberName',
          e,
        );
      }
      isStatic = true;
    } else if (receiver case TypeLiteralReceiver(:final type)) {
      // Static method
      staticType = type;
      if (ctx.topLevelDeclarationsMap[staticType
                  .file]?['${staticType.name}.$staticMemberName'] ==
              null &&
          ctx.topLevelDeclarationsMap[staticType
                  .file]?['${staticType.name}.${MemberName.getter(staticMemberName).key}'] ==
              null) {
        // A member invoked on a `Type` literal may still be an extension
        // member on `Type` — `C.expectStaticType<Exactly<Type>>()`.
        final found = resolveExtensionMember(
          ctx,
          L.type,
          e.methodName.name,
          arity: positionalArity(e),
        );
        if (found != null) {
          return invokeExtensionMethod(ctx, L, e, found.$1, found.$2, found.$3);
        }
        // Not a static member of the class — it's an instance method of the
        // `Type` object itself (`Foo.toString()`, `Foo.hashCode`, ...).
        final args = [
          for (final arg in e.argumentList.arguments)
            if (arg is! NamedArgument)
              compileExpression(arg.argumentExpression, ctx),
        ];
        return invokeOperator(L, e.methodName.name, args).result;
      }
      final staticMember = ctx.memberLookup.staticMember(
        staticType,
        staticMemberName,
        MemberKind.method,
      );
      resolved = staticMember == null
          ? null
          : ResolvedMember(
              staticMember,
              staticMember.ownerDecl?.thisType ?? staticType,
            );
      if (resolved == null) {
        throw CompileError(
          'Cannot find static method $staticType.$staticMemberName',
          e,
        );
      }
      isStatic = true;
    } else if (L.type.isFunctionLike && e.methodName.name == 'call') {
      // `fn.call(...)`: Function has no declared `call` member; the call is
      // the invocation itself, typed by the callee's own signature.
      return invokeValue(callSite(), callee: L);
    } else if (!L.type.isSpec(CoreTypes.dynamic)) {
      // `record.field(args)` on a named record field invokes the field's
      // value — a property read followed by an implicit `.call`, matching
      // the field/getter path below.
      final receiverType = L.type;
      if (receiverType is RecordTypeRef &&
          receiverType.named.containsKey(e.methodName.name)) {
        final target = MemberValueCall(
          read: (ctx) => GetTarget.read(ctx, L, e.methodName.name),
        );
        final bound = ArgumentBinder(
          ctx,
        ).bindSuppliedOnly(target, callSite(), callee: null);
        return target.emit(ctx, bound);
      }
      try {
        resolved = ctx.memberLookup.interfaceMember(
          L.type,
          ctx.memberNameOf(e.methodName.name, MemberKind.method),
          source: e,
        );
      } on CompileError {
        // No such instance member: an extension member may apply.
        final found = resolveExtensionMember(
          ctx,
          L.type,
          e.methodName.name,
          arity: positionalArity(e),
        );
        if (found != null) {
          return invokeExtensionMethod(ctx, L, e, found.$1, found.$2, found.$3);
        }
        final foundGetter = resolveExtensionMember(
          ctx,
          L.type,
          e.methodName.name,
          getter: true,
        );
        if (foundGetter == null && e.methodName.name == 'noSuchMethod') {
          // `Object.noSuchMethod` is implicit — absent from all declaration
          // metadata. Dispatch dynamically.
          final (positional, named) = compileCallArgs(ctx, e);
          return invokeOperator(
            L,
            'noSuchMethod',
            positional,
            namedArgs: named,
          ).result;
        }
        if (foundGetter == null) rethrow;
        // `recv.m(args)` where extension member m is a getter — a
        // function-expression invocation: the getter's value is read first,
        // then the arguments evaluate.
        return invokeValue(
          callSite(),
          callee: invokeExtensionGetter(
            ctx,
            L,
            foundGetter.$1,
            foundGetter.$2,
            foundGetter.$3,
          ),
        );
      }
      final memberNode = resolved.member is SourceMember
          ? (resolved.member as SourceMember).node
          : null;
      final isFieldOrGetter =
          memberNode is FieldDeclaration ||
          (memberNode is MethodDeclaration && memberNode.isGetter);
      if (isFieldOrGetter) {
        if (e.target is SuperExpression) {
          // `super.m(args)` is a function-expression invocation: the member
          // value is read before the arguments evaluate.
          return invokeValue(
            callSite(),
            callee: GetTarget.read(ctx, L, e.methodName.name),
          );
        }
        // `receiver.field(...)` / `receiver.getter(...)`: the member's
        // *value* is invoked, not a method — property read then implicit
        // `.call`. The arguments evaluate before the member read.
        final target = MemberValueCall(
          read: (ctx) => GetTarget.read(ctx, L, e.methodName.name),
        );
        final bound = ArgumentBinder(
          ctx,
        ).bindSuppliedOnly(target, callSite(), callee: null);
        return target.emit(ctx, bound);
      }
      isStatic = false;
    } else {
      isStatic = false;
      // Extension resolution is static, so it still applies to a dynamic
      // receiver (`on T` binds T=dynamic) — `d.expectStaticType<...>()`.
      final found = resolveExtensionMember(
        ctx,
        L.type,
        e.methodName.name,
        arity: positionalArity(e),
      );
      if (found != null) {
        return invokeExtensionMethod(ctx, L, e, found.$1, found.$2, found.$3);
      }
    }

    if (isStatic) {
      // `C.field(args)`/`E.field(args)` where `field` holds a closure, or a
      // static getter invoked with arguments, reads the member value and
      // invokes its result rather than calling a function named
      // `C.field`/`C.x`.
      final memberDecl = resolved?.member is SourceMember
          ? (resolved!.member as SourceMember).node
          : null;
      if (memberDecl is FieldDeclaration ||
          (memberDecl is MethodDeclaration && memberDecl.isGetter)) {
        return invokeValue(
          callSite(),
          callee: IdentifierReference(L, staticMemberName).getValue(ctx, e),
        );
      }
      // `E.m(receiver, ...)` — explicit application of an instance
      // extension member through the namespace. The receiver is the first
      // argument and binds the extension's `on` type parameters.
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
          final receiverArg = compileExpression(
            positional.first.argumentExpression,
            ctx,
          );
          final bindings = matchExtensionOn(ctx, receiverArg.type, memberExt);
          if (bindings == null) {
            throw CompileError(
              '${receiverArg.type} is not assignable to the `on` clause of '
              'extension ${memberExt.name}',
              e,
            );
          }
          return invokeExtensionMethod(
            ctx,
            receiverArg,
            e,
            memberExt,
            memberDecl,
            bindings,
            argIndexOffset: 1,
          );
        }
      }
    }

    final resolvedMember = resolved?.member;
    if (resolvedMember is BridgeMember) {
      final br = resolvedMember.def;
      final fd = br is BridgeMethodDef
          ? br.functionDescriptor
          : (br as BridgeConstructorDef).functionDescriptor;
      final receiverTypeParameters = isStatic
          ? const <String, TypeRef>{}
          : _bridgeClassTypeArguments(
              ctx,
              L.type,
              resolvedMember.ownerDecl!.library,
            );
      argsPair = ArgumentBinder(ctx).bindBridgeVector(
        e.argumentList,
        fd,
        before: [],
        typeParameters: receiverTypeParameters,
      );
      // Static calls on generic bridge classes (e.g. `Stream.fromIterable`)
      // infer the class's own type parameters — `T` in `Iterable<T>` — from
      // the argument types, which then resolve `returns:` annotations.
      final classGenericNames = isStatic
          ? switch (ctx
                .topLevelDeclarationsMap[staticType!.file]?[staticType.name]
                ?.bridge) {
              BridgeClassDef b => b.type.generics.keys.toSet(),
              _ => const <String>{},
            }
          : const <String>{};
      _inferBridgeTypeParameters(
        fd,
        argsPair.positionalValues,
        bridgeTypeParameters,
        inferableNames: classGenericNames,
      );
      mReturnType = resolveCallResultType(
        ctx,
        signature: CallSignature.bridge(
          ctx,
          fd,
          returnFallback: CoreTypes.dynamic.ref(ctx),
          owner: isStatic ? staticType : L.type,
          typeParameters: bridgeTypeParameters,
        ),
        targetType: isStatic ? staticType : L.type,
        argTypes: argsPair.positionalValues.map((a) => a.type).toList(),
        namedArgTypes: argsPair.namedValues.map((k, v) => MapEntry(k, v.type)),
      );
      // Instance calls that carry no named or explicit type arguments route
      // through the modern invocation path, which preserves intrinsic
      // optimizations for core types. The argument vector stays padded with
      // null placeholders so generated wrappers keep the legacy flattened
      // ABI. The declared return type (including inferred generics and
      // parameter-type dependencies) still applies to the result.
      if (!isStatic &&
          e.typeArguments == null &&
          argsPair.namedValues.isEmpty) {
        final invokeResult = invokeOperator(
          L,
          e.methodName.name,
          argsPair.positionalValues,
        ).result;
        final preciseType = mReturnType;
        if (preciseType != null) {
          return invokeResult.copyWith(type: preciseType);
        }
        return invokeResult;
      }
    } else if (L.type.isSpec(CoreTypes.dynamic)) {
      argsPair = ArgumentBinder(
        ctx,
      ).bindDynamicVector(e.argumentList, before: [L]);
    } else {
      final dec = (resolved!.member as SourceMember).node as Declaration;
      final memberLibrary = (resolved.member as SourceMember).library;
      // Instance calls compile supplied arguments against the resolved
      // signature — context types and coercion apply — but only a call
      // proven static fills omitted arguments. A call that stays virtual
      // leaves names and defaults for the runtime to bind (`calleeBinds`).
      final refined = isStatic
          ? null
          : Devirtualizer(ctx).refine(
              VirtualCall(
                receiver: L,
                name: e.methodName.name,
                member: resolved.member,
                isSuperReceiver: e.target is SuperExpression,
              ),
            );
      if (!isStatic && refined is VirtualCall) {
        // Still virtual: bind against the interface signature resolved on
        // the receiver's static type — supplied arguments only.
        argsPair = ArgumentBinder(ctx).bindDeclaration(
          memberLibrary,
          dec,
          e.argumentList,
          typeArguments: e.typeArguments,
          source: e,
          seedGenerics: dec is MethodDeclaration
              ? resolved.ownerTypeArguments
              : const {},
          returnContext: bound,
          fillOmitted: false,
        );
        mReturnType = argsPair.declaredReturn;
      } else {
        // Static (and devirtualized) calls bind against the concrete
        // implementation's signature: [refine] resolved the declaring
        // owner, which may differ from the static declaration when an
        // override carries its own defaults.
        var bindingLib = memberLibrary;
        Declaration bindingDec = dec;
        var bindingMember = resolved.member;
        var bindingView = resolved.viewedAs;
        if (refined is StaticCall && refined.declaringLink != null) {
          final member = ctx.memberLookup.concreteMemberOn(
            refined.declaringLink!,
            MemberName(e.methodName.name, MemberKind.method),
          );
          if (member is SourceMember) {
            bindingLib = refined.offset!.file ?? memberLibrary;
            bindingDec = member.sourceDeclaration;
            bindingMember = member;
            bindingView =
                ctx.typeSystem.asInstanceOf(
                  refined.declaringLink!,
                  member.declaringDecl ?? member.ownerDecl,
                ) ??
                refined.declaringLink!;
          }
        }
        argsPair = ArgumentBinder(ctx).bindDeclaration(
          bindingLib,
          bindingDec,
          e.argumentList,
          typeArguments: e.typeArguments,
          source: e,
          seedGenerics: !isStatic && bindingDec is MethodDeclaration
              ? ownerTypeArgumentsOf(
                  bindingMember.declaringDecl ?? bindingMember.ownerDecl,
                  bindingView,
                )
              : const {},
          returnContext: bound,
        );
        mReturnType = argsPair.declaredReturn;
      }
    }

    final argTypes = argsPair.positionalValues.map((e) => e.type).toList();
    final namedArgTypes = argsPair.namedValues.map(
      (key, value) => MapEntry(key, value.type),
    );
    mReturnType ??= memberCallResultType(
      ctx,
      isStatic ? staticType ?? CoreTypes.dynamic.ref(ctx) : L.type,
      staticMemberName,
      argTypes,
      namedArgTypes,
      $static: isStatic,
      source: e,
    );
    final returnType = mReturnType ?? CoreTypes.dynamic.ref(ctx);

    if (isStatic) {
      final declaration = resolved?.member is SourceMember
          ? (resolved!.member as SourceMember).node
          : null;
      final boundCall = BoundCall(
        positional: const [],
        named: const [],
        runtimeTypeArguments: runtimeTypeArguments(ctx, e).isNotEmpty
            ? runtimeTypeArguments(ctx, e)
            : argsPair.runtimeTypeArguments,
        returnType: returnType,
        vectorOverride: argsPair.vector(),
      );
      if (declaration is ConstructorDeclaration) {
        return ConstructorCall(
          staticType: staticType!,
          instantiatedType: returnType,
          name: staticMemberName,
          offset: DeferredOrOffset.lookupStatic(
            ctx,
            staticType.file,
            staticType.name,
            staticMemberName,
          ),
          constructor: declaration,
          isConst: e.inConstantContext,
        ).emit(ctx, boundCall);
      }
      if (resolved?.member is BridgeMember) {
        return StaticCall(
          null,
          externalIndex:
              ctx.bridgeStaticFunctionIndices[staticType!
                  .file]!['${staticType.name}.$staticMemberName']!,
          member: resolved?.member,
        ).emit(ctx, boundCall);
      }
      return StaticCall(
        DeferredOrOffset.lookupStatic(
          ctx,
          namespaceExt?.library ?? staticType!.file,
          namespaceExt?.name ?? staticType!.name,
          staticMemberName,
        ),
        member: resolved?.member,
      ).emit(ctx, boundCall);
    }

    final boundCall = BoundCall(
      receiver: L,
      positional: [
        for (final arg in argsPair.positionalValues) BoundArgument(arg),
      ],
      named: [
        for (final entry in argsPair.namedValues.entries)
          (entry.key, BoundArgument(entry.value)),
      ],
      runtimeTypeArguments: runtimeTypeArguments(ctx, e).isNotEmpty
          ? runtimeTypeArguments(ctx, e)
          : argsPair.runtimeTypeArguments,
      returnType: returnType,
      // The dynamic and bridge vectors aren't decomposable into
      // positional-then-named (source order / padded ABI) — carry the raw
      // vector.
      vectorOverride:
          resolved?.member is BridgeMember || L.type.isSpec(CoreTypes.dynamic)
          ? (resolvedMember is BridgeMember
                ? argsPair.vector()
                : argsPair.vector().skip(1).toList())
          : null,
    );
    if (resolvedMember is BridgeMember) {
      return BridgeCall(
        receiver: L,
        name: e.methodName.name,
        isSuperReceiver: e.target is SuperExpression,
        member: resolvedMember,
      ).emit(ctx, boundCall);
    }
    if (L.type.isSpec(CoreTypes.dynamic)) {
      return DynamicCall(
        receiver: L,
        name: e.methodName.name,
      ).emit(ctx, boundCall);
    }
    return Devirtualizer(ctx)
        .refine(
          VirtualCall(
            receiver: L,
            name: e.methodName.name,
            member: resolvedMember,
            isSuperReceiver: e.target is SuperExpression,
          ),
        )
        .emit(ctx, boundCall);
  }

  /// `a + b`, `a[i]`, `!x`, `a == b`, `it.moveNext()` — the operator and
  /// legacy dynamic-dispatch entry point: [Intrinsics] first, then
  /// extension members, then [EqualityCall]/[VirtualCall] on the operand
  /// vector bound to the declared operator signature.
  OperatorResult invokeOperator(
    Variable receiver,
    String? method,
    List<Variable> args, {
    Map<String, Variable>? namedArgs,
    BoundExtension? extensionPin,
  }) {
    if (method == null) {
      return invokeFunctionValue(receiver, args, namedArgs);
    }
    if (namedArgs == null || namedArgs.isEmpty) {
      final intrinsic = Intrinsics(ctx).tryEmit(receiver, method, args);
      if (intrinsic != null) return intrinsic;
    }
    var recv = receiver;
    if ((namedArgs == null || namedArgs.isEmpty) &&
        !recv.type.isSpec(CoreTypes.dynamic)) {
      // `E(x).m(...)` — explicit application pins member resolution to E.
      // Operators are never extension members, so a pinned receiver can
      // only reach this path dead — the probe is preserved for parity.
      final bound = extensionPin;
      if (bound != null) {
        final member = extensionMember(bound.ext, method);
        if (member == null) {
          throw CompileError(
            'Extension ${bound.ext.name} has no member $method',
          );
        }
        return _invokeExtensionOperator(
          recv,
          bound.ext,
          member,
          bound.onBindings,
          extBindingsMap(bound.ext, bound.onBindings),
          args,
        );
      }
      // A member the class doesn't declare may be an extension method (e.g.
      // `operator []=` defined in `extension on T`). Instance members win —
      // the extension only applies when instance lookup fails.
      if (!ctx.memberLookup.hasInstanceMember(
        recv.type,
        MemberName.method(method),
      )) {
        // `unary-` maps to the extension member `-` of positional arity 0.
        final found = resolveExtensionMember(
          ctx,
          recv.type,
          method == 'unary-' ? '-' : method,
          arity: args.length,
        );
        if (found != null) {
          final (ext, member, bindings) = found;
          return _invokeExtensionOperator(
            recv,
            ext,
            member,
            bindings,
            extBindingsMap(ext, bindings),
            args,
          );
        }
      }
    }
    final values = [...args];
    final equality = (method == '==' || method == '!=') && values.length == 1;
    if (equality &&
        recv.unmaterializedCallable != null &&
        values.single.unmaterializedCallable != null) {
      // Two unmaterialized references to the same function are identical.
      final equal = recv.methodOffset == values.single.methodOffset;
      return (
        target: recv,
        result: BuiltinValue(
          boolval: method == '!=' ? !equal : equal,
        ).push(ctx),
        args: values,
        namedArgs: const {},
      );
    }
    if (recv.unmaterializedCallable != null) {
      recv = recv.tearOff(ctx);
    }
    for (var i = 0; i < values.length; i++) {
      if (values[i].unmaterializedCallable != null) {
        values[i] = values[i].tearOff(ctx);
      }
    }
    final boxed = Variable.boxUnboxMultiple(ctx, [recv, ...values], true);
    recv = boxed.first;
    final prepared = boxed.sublist(1);
    if (equality) {
      final result =
          EqualityCall(
            left: recv,
            right: prepared.single,
            negated: method == '!=',
          ).emit(
            ctx,
            BoundCall(
              positional: const [],
              named: const [],
              returnType: CoreTypes.bool.ref(ctx),
            ),
          );
      return (
        target: recv,
        result: result,
        args: prepared,
        namedArgs: const {},
      );
    }
    final argTypes = prepared.map((arg) => arg.type).toList();
    final namedArgTypes =
        namedArgs?.map((key, arg) => MapEntry(key, arg.type)) ?? {};
    // The '.call' member on a bare Function-typed receiver can't resolve an
    // instance method; the callee's own signature carries the result type.
    final isBareCall = recv.type.isFunctionLike && method == 'call';
    final TypeRef returnType;
    if (isBareCall) {
      returnType =
          callResultType(
            ctx,
            callee: recv,
            dispatch: null,
            argTypes: argTypes,
            namedArgTypes: namedArgTypes,
          ) ??
          CoreTypes.dynamic.ref(ctx);
    } else {
      returnType =
          memberCallResultType(
            ctx,
            recv.type,
            method,
            argTypes,
            namedArgTypes,
          ) ??
          CoreTypes.dynamic.ref(ctx);
    }
    var boundCall = BoundCall(
      receiver: recv,
      positional: [for (final arg in prepared) BoundArgument(arg)],
      named: [
        for (final entry in (namedArgs ?? const <String, Variable>{}).entries)
          (entry.key, BoundArgument(entry.value.boxIfNeeded(ctx))),
      ],
      returnType: returnType,
    );
    // Typed binding: a declared operator coerces its operands to the
    // declared signature (e.g. `int.+` takes num) instead of the legacy
    // box-everything vector.
    if (!isBareCall && !recv.type.isSpec(CoreTypes.dynamic)) {
      try {
        final opResolved = ctx.memberLookup.interfaceMember(
          recv.type,
          ctx.memberNameOf(method, MemberKind.method),
        );
        final opMember = opResolved.member;
        if (opMember is SourceMember && opMember.node is MethodDeclaration) {
          final opDecl = opMember.node as MethodDeclaration;
          final opParams =
              opDecl.parameters?.parameters ?? const <FormalParameter>[];
          final typedPositional = <BoundArgument>[];
          var pi = 0;
          for (final param in opParams) {
            if (param.isNamed || pi >= prepared.length) break;
            var (paramType, _) = getFormalParameterType(
              ctx,
              param,
              opMember.library,
              opDecl,
            );
            paramType ??= CoreTypes.dynamic.ref(ctx);
            typedPositional.add(
              BoundArgument(
                coerceArgumentForParameter(
                  ctx,
                  prepared[pi],
                  paramType,
                  param,
                  opDecl,
                ),
              ),
            );
            pi++;
          }
          for (; pi < prepared.length; pi++) {
            typedPositional.add(BoundArgument(prepared[pi]));
          }
          boundCall = BoundCall(
            receiver: recv,
            positional: typedPositional,
            named: boundCall.named,
            returnType: returnType,
          );
        }
      } on CompileError {
        // No resolvable declaration — the untyped dispatch applies.
      }
    }
    final result = Devirtualizer(
      ctx,
    ).refine(VirtualCall(receiver: recv, name: method)).emit(ctx, boundCall);
    return (
      target: recv,
      result: result,
      args: prepared,
      namedArgs: namedArgs ?? {},
    );
  }

  /// `f(args)` where `f` is a function-typed value — or a non-function
  /// whose implicit `.call` may resolve to an extension member.
  OperatorResult invokeFunctionValue(
    Variable callee,
    List<Variable> args,
    Map<String, Variable>? namedArgs,
  ) {
    if (!callee.type.isAssignableTo(ctx, CoreTypes.function.ref(ctx))) {
      // `x(...)` on a non-function is an implicit `x.call(...)`, which may
      // resolve to an extension `call` member.
      if (resolveExtensionMember(
            ctx,
            callee.type,
            'call',
            arity: args.length,
          ) !=
          null) {
        return invokeOperator(callee, 'call', args, namedArgs: namedArgs);
      }
      throw CompileError(
        'Cannot invoke variable of type ${callee.type} as it is not a function',
      );
    }
    if (callee.callingConvention == CallingConvention.dynamic ||
        callee.methodOffset == null) {
      final (result, bound) = invokeValueWithArgs(
        CallSite(shape: CallShape.values(args, namedArgs)),
        callee: callee,
      );
      return (
        target: null,
        result: result,
        args: [for (final a in bound.positional) a.value],
        namedArgs: {for (final e in bound.named) e.$1: e.$2.value},
      );
    }
    final returnType =
        callResultType(
          ctx,
          callee: callee,
          dispatch: null,
          argTypes: args.map((arg) => arg.type).toList(),
          namedArgTypes:
              namedArgs?.map((key, arg) => MapEntry(key, arg.type)) ?? {},
        ) ??
        CoreTypes.dynamic.ref(ctx);
    return (
      target: callee,
      result: StaticCall(callee.methodOffset!).emit(
        ctx,
        BoundCall(
          positional: const [],
          named: const [],
          returnType: returnType,
          rep: Abi.unboxedAcrossCalls(returnType),
          vectorOverride: [
            ...args.map((arg) => arg.ssa),
            ...?namedArgs?.values.map((arg) => arg.ssa),
          ],
        ),
      ),
      args: args,
      namedArgs: namedArgs ?? {},
    );
  }

  /// Emits a static `Call` to an extension member resolved on the operator
  /// path — receiver first, then the converted and default-filled args.
  OperatorResult _invokeExtensionOperator(
    Variable receiver,
    EvalExtension ext,
    MethodDeclaration member,
    List<TypeRef> bindings,
    Map<String, TypeRef> typeParams,
    List<Variable> args,
  ) {
    final formals = member.parameters?.parameters ?? const [];
    final convertedArgs = [
      for (var i = 0; i < args.length; i++)
        i < formals.length && formals[i].type != null
            ? convertForAssignment(
                ctx,
                args[i],
                ctx.typeFactory.formalParameterAnnotationType(
                  ext.library,
                  formals[i],
                  typeParameters: typeParams,
                ),
                representation: MachineRepresentation.object,
              )
            : args[i],
    ];
    // Pad omitted optional positionals with their declared defaults —
    // extension members are static calls, so the full declared argument
    // vector is always passed.
    final positionalFormals = formals.where((f) => f.isPositional).toList();
    for (var i = convertedArgs.length; i < positionalFormals.length; i++) {
      convertedArgs.add(
        compileOmittedArgument(
          ctx,
          ext.library,
          positionalFormals[i],
          member,
          typeParameters: typeParams,
        ),
      );
    }
    final returnType = member.returnType == null
        ? CoreTypes.dynamic.ref(ctx)
        : TypeRef.fromAnnotation(
            ctx,
            ext.library,
            member.returnType!,
            typeParameters: typeParams,
          );
    return (
      target: receiver,
      result:
          StaticCall(
            DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
            receiver: receiver.boxIfNeeded(ctx),
          ).emit(
            ctx,
            BoundCall(
              positional: const [],
              named: const [],
              runtimeTypeArguments:
                  extensionCallTypeArguments(
                    ctx,
                    ext,
                    member,
                    bindings,
                    const {},
                  ) ??
                  const [],
              returnType: returnType,
              vectorOverride: [
                for (final a in convertedArgs) a.boxIfNeeded(ctx).ssa,
              ],
            ),
          ),
      args: convertedArgs,
      namedArgs: const {},
    );
  }

  /// `f(args)` / `p.f(args)` — a call whose callee is a bare or
  /// prefix-qualified identifier, resolved through the denotation cascade
  /// rather than by materializing a callee [Variable].
  Variable invokeBare(
    String name,
    CallSite site, {
    String? prefix,
    TypeRef? bound,
  }) {
    final e = site.source as MethodInvocation;
    final Reference ref;
    final Denotation d;
    if (prefix == null) {
      final r = IdentifierReference(null, name);
      ref = r;
      d = r.denotation(ctx, source: e);
    } else {
      final r = PrefixedIdentifierReference(prefix, name);
      ref = r;
      d = r.denotation(ctx, source: e);
    }
    // `E(x)` — the namespace literal applied to a receiver.
    if (d is ExtensionNamespaceDenotation) {
      return applyExtension(ctx, e, d.ext);
    }
    // A member of the enclosing scope invoked bare — re-enter through the
    // implicit receiver (declared member, implicit `this`, or the
    // anonymous receiver).
    if (d is InstanceMemberDenotation) {
      final recv = d.receiver == null
          ? ctx.lookupLocal('#this')!
          : _receiverVariable(d.receiver!);
      return invokeMethodWithTarget(ctx, recv, e, bound: bound);
    }
    // A bound extension-method tear-off invoked directly — `x.m(args)`
    // lowers to `E.m(x, args)`; covers `m(args)` inside the extension body
    // where the receiver is `this`.
    if (d is ExtensionMemberDenotation &&
        !d.member.isStatic &&
        !d.member.isGetter &&
        !d.member.isSetter &&
        d.receiver != null) {
      return invokeExtensionMethod(
        ctx,
        d.receiver!,
        e,
        d.ext,
        d.member,
        matchExtensionOn(ctx, d.receiver!.type, d.ext) ?? const [],
      );
    }
    // Values invoke through the value-call path (closure, `.call` member,
    // or dynamic dispatch).
    if (d is LocalDenotation ||
        d is GlobalDenotation ||
        d is TypeParameterDenotation ||
        d is EnumValueDenotation ||
        d is PrefixDenotation) {
      return invokeValue(site, ref: ref);
    }
    return _invokeBareDispatch(d, name, ref, site, e, bound: bound);
  }

  /// The declared-target tail of a bare call: static functions and members,
  /// constructors (including aliases and implicit defaults), and bridges.
  Variable _invokeBareDispatch(
    Denotation d,
    String name,
    Reference ref,
    CallSite site,
    MethodInvocation e, {
    TypeRef? bound,
  }) {
    TypeRef? mReturnType;
    TypeRef? sigReturn;
    DeferredOrOffset offset;
    BridgeDeclaration? bridgeDecl;
    Declaration? sourceDecl;
    TypeRef? aliasType;

    switch (d) {
      case BridgeDenotation(:final target, :final name):
        bridgeDecl = target.bridge;
        final bridge = target.bridge;
        TypeRef? bridgeType;
        if (bridge is BridgeFunctionDeclaration) {
          sigReturn = TypeRef.fromBridgeAnnotation(
            ctx,
            bridge.function.returns,
          );
        } else if (bridge is BridgeClassDef) {
          bridgeType = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);
          sigReturn = bridgeType;
        } else if (bridge is BridgeEnumDef) {
          bridgeType = TypeRef.fromBridgeTypeRef(ctx, bridge.type);
        }
        offset = DeferredOrOffset(
          file: target.sourceLib,
          name: bridgeType != null ? '${bridgeType.name}.' : name,
        );
      case TypeLiteralDenotation(
        :final type,
        :final constructorKey,
        :final declaration,
      ):
        // A class or extension sharing its name with an extension applies as
        // `E(x)` — extension namespaces win over constructor calls.
        final ext = extensionForType(ctx, type);
        if (ext != null) return applyExtension(ctx, e, ext);
        if (declaration is TypeAlias && declaration is! ClassTypeAlias) {
          var resolved = ctx.typeFactory.resolveTypeAlias(
            ctx.library,
            declaration,
            typeArgs: e.typeArguments?.arguments.toList(),
            rawParams: true,
          );
          // Downward inference: `C<num> x = T(num)` instantiates `T` as
          // `C<num>` by unifying against the context type.
          final boundChain = bound;
          if (e.typeArguments == null &&
              boundChain != null &&
              boundChain.file == resolved.file &&
              boundChain.name == resolved.name &&
              interfaceArgumentsOf(boundChain).isNotEmpty) {
            final bindings = <TypeParameterDef, TypeRef>{};
            for (
              var i = 0;
              i < interfaceArgumentsOf(resolved).length &&
                  i < interfaceArgumentsOf(boundChain).length;
              i++
            ) {
              ctx.typeSystem.unify(
                interfaceArgumentsOf(resolved)[i],
                interfaceArgumentsOf(boundChain)[i],
                bindings,
              );
            }
            if (bindings.isNotEmpty) {
              resolved = resolved.substituteTypeParameters(
                Substitution.of(bindings),
              );
            }
          }
          aliasType = resolved;
          sourceDecl =
              ctx.topLevelDeclarationsMap[resolved.file]!['${resolved.name}.']
                  ?.declaration;
          offset = DeferredOrOffset(
            file: resolved.file,
            name: '${resolved.name}.',
          );
          if (sourceDecl == null) {
            // The aliased class has an implicit default constructor — call
            // the synthesized body with just the runtime-type argument.
            return ConstructorCall(
              staticType: resolved,
              instantiatedType: resolved,
              offset: offset,
              implicitDefault: true,
            ).emit(
              ctx,
              BoundCall(
                positional: const [],
                named: const [],
                returnType: resolved,
              ),
            );
          }
          break;
        }
        sourceDecl =
            ctx.topLevelDeclarationsMap[type.file]?[constructorKey]
                ?.declaration;
        offset = DeferredOrOffset(file: type.file, name: constructorKey);
        sigReturn = type;
        if (sourceDecl == null) {
          // Call to an implicit default constructor.
          mReturnType = type;
          final instantiatedType = instantiateConstructorType(ctx, e, type);
          return ConstructorCall(
            staticType: type,
            instantiatedType: instantiatedType,
            offset: offset,
            implicitDefault: true,
          ).emit(
            ctx,
            BoundCall(
              positional: const [],
              named: const [],
              returnType: instantiatedType,
            ),
          );
        }
      case FunctionDenotation() ||
          StaticMemberDenotation() ||
          ExtensionMemberDenotation():
        final target = d.call(ctx, source: e);
        if (target is! StaticCall ||
            target.offset == null ||
            target.signature == null) {
          return invokeValue(site, ref: ref);
        }
        offset = target.offset!;
        sigReturn = target.signature!.returnType;
        sourceDecl = switch (d) {
          FunctionDenotation(:final target) => target.declaration,
          StaticMemberDenotation(:final member) => member,
          ExtensionMemberDenotation(:final member) => member,
          _ => throw CompileError('Cannot call $name', e),
        };
      default:
        return invokeValue(site, ref: ref);
    }

    final List<Variable> args;
    final Map<String, Variable> namedArgs;
    final List<SSA> callArgs;
    List<int> inferredTypeArgs = const [];

    var isConstructor = false;
    List<TypeRef>? inferredCtorArgs;
    bool? genericReturnBoxed;

    if (bridgeDecl != null) {
      final bridge = bridgeDecl;

      /// If we're invoking a class identifier directly (like ClassName()),
      /// call its default constructor
      final fnDescriptor = bridge is BridgeClassDef
          ? (bridge.constructors['']?.functionDescriptor ??
                (throw CompileError(
                  'Class "${e.methodName.name}" does not have a default '
                  'constructor',
                  e,
                )))
          : (bridge as BridgeFunctionDeclaration).function;

      final argsPair = ArgumentBinder(
        ctx,
      ).bindBridgeVector(e.argumentList, fnDescriptor);

      args = argsPair.positionalValues;
      namedArgs = argsPair.namedValues;
      callArgs = argsPair.vector();
      isConstructor = bridge is BridgeClassDef;
    } else {
      final dec = sourceDecl!;
      isConstructor = dec is ConstructorDeclaration;

      final result = ArgumentBinder(ctx).bindDeclaration(
        offset.file!,
        dec,
        e.argumentList,
        typeArguments: e.typeArguments,
        source: e,
      );

      mReturnType = result.declaredReturn;
      genericReturnBoxed = result.genericReturnBoxed;
      args = result.positionalValues;
      namedArgs = result.namedValues;
      callArgs = result.vector();
      inferredTypeArgs = result.runtimeTypeArguments;

      // Upward inference for constructors: the class type arguments inferred
      // from the argument list (or the parameters' bounds), in declaration
      // order.
      final ctorDecl = isConstructor ? dec.parent?.parent : null;
      final ctorClassParams = switch (ctorDecl) {
        ClassDeclaration() || MixinDeclaration() || ClassTypeAlias() =>
          classLikeClauses(ctorDecl as Declaration).$4?.typeParameters,
        _ => null,
      };
      if (ctorClassParams != null) {
        // Downward inference wins: a context type naming the constructed
        // class pins its type arguments (`A<int> get g => A(1)`).
        final boundChain = bound;
        final ctorClassName = ctorDecl is Declaration
            ? declarationName(ctorDecl)
            : null;
        if (boundChain != null &&
            e.typeArguments == null &&
            boundChain.name == ctorClassName) {
          final contextArgs = interfaceArgumentsOf(boundChain);
          if (contextArgs.isNotEmpty &&
              contextArgs.every((t) => !t.isTypeParameter)) {
            inferredCtorArgs = contextArgs;
          }
        }
        inferredCtorArgs ??= [
          for (final param in ctorClassParams)
            result.typeArguments[param.name.lexeme] ??
                CoreTypes.dynamic.ref(ctx),
        ];
        if (aliasType != null && e.typeArguments == null) {
          // The alias's instantiated arguments were left as parameter
          // references for inference; bind them from what the constructor's
          // arguments gave.
          final bindings = <TypeParameterDef, TypeRef>{};
          final aliasArgs = interfaceArgumentsOf(aliasType);
          for (
            var i = 0;
            i < aliasArgs.length && i < inferredCtorArgs.length;
            i++
          ) {
            ctx.typeSystem.unify(aliasArgs[i], inferredCtorArgs[i], bindings);
          }
          if (bindings.isNotEmpty) {
            aliasType = aliasType.substituteTypeParameters(
              Substitution.of(bindings),
            );
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
          ctx.visibleTypes[ctx.enclosingLibrary ??
              ctx.library]![ctx.currentClassName!];
    }

    mReturnType ??= sigReturn == null
        ? null
        : resolveCallResultType(
                ctx,
                signature: CallSignature.returnOnly(sigReturn),
                targetType: thisType,
                argTypes: argTypes,
                namedArgTypes: namedArgTypes,
              ) ??
              sigReturn;
    final returnType = mReturnType ?? CoreTypes.dynamic.ref(ctx);
    final resultRep =
        bridgeDecl != null ||
            sourceDecl is! FunctionDeclaration ||
            (genericReturnBoxed ?? Abi.unboxedAcrossCalls(returnType).isBoxed)
        ? ValueRep.boxed
        : Abi.unboxedAcrossCalls(returnType);
    final instantiatedReturnType = isConstructor
        ? (aliasType ??
              instantiateConstructorType(ctx, e, returnType, inferredCtorArgs))
        : returnType;
    final boundCall = BoundCall(
      positional: const [],
      named: const [],
      runtimeTypeArguments: runtimeTypeArguments(ctx, e).isNotEmpty
          ? runtimeTypeArguments(ctx, e)
          : inferredTypeArgs,
      returnType: instantiatedReturnType,
      rep: resultRep,
      vectorOverride: callArgs,
    );
    if (isConstructor) {
      if (bridgeDecl is BridgeClassDef) {
        final bridge = bridgeDecl;
        final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);
        return ConstructorCall(
          staticType: type,
          instantiatedType: instantiatedReturnType,
          externalIndex:
              ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.']!,
          classBridge: bridge,
          isConst: e.inConstantContext,
        ).emit(ctx, boundCall);
      }
      return ConstructorCall(
        staticType: instantiatedReturnType,
        instantiatedType: instantiatedReturnType,
        offset: offset,
        constructor: sourceDecl! as ConstructorDeclaration,
        isConst: e.inConstantContext,
      ).emit(ctx, boundCall);
    }
    if (bridgeDecl != null) {
      return StaticCall(
        null,
        externalIndex:
            ctx.bridgeStaticFunctionIndices[offset.file]![offset.name]!,
      ).emit(ctx, boundCall);
    }
    return StaticCall(offset).emit(ctx, boundCall);
  }
}

Map<String, TypeRef> _bridgeClassTypeArguments(
  CompilerContext ctx,
  TypeRef receiver,
  int declarationLibrary,
) {
  final resolved = receiver;
  final declaration =
      ctx.topLevelDeclarationsMap[declarationLibrary]?[resolved.name];
  final bridge = declaration?.bridge;
  if (bridge is! BridgeClassDef) return const {};
  final names = bridge.type.generics.keys.toList();
  return {
    for (
      var index = 0;
      index < names.length && index < interfaceArgumentsOf(resolved).length;
      index++
    )
      names[index]: interfaceArgumentsOf(resolved)[index],
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
    final actualFunction = actual is FunctionTypeRef ? actual.signature : null;
    if (genericFunction != null && actualFunction != null) {
      infer(genericFunction.returns.type, actualFunction.returnType);
      return;
    }
    final formalArguments = formal.typeArgs;
    final actualArguments = interfaceArgumentsOf(actual);
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
