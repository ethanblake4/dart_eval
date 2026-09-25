import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/variable/value_facts.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/helpers/mixin_application.dart';
import '../member/call_signature.dart';
import '../member/resolved_member.dart';
import 'deferred.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
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

  /// An extension namespace has no runtime receiver. Its instance methods
  /// consume an explicitly supplied receiver; static members bind normally.
  Variable invokeExtensionNamespace(
    ExtensionNamespaceReceiver receiver,
    MethodInvocation invocation, {
    TypeRef? bound,
  }) {
    final denotation = resolveMemberAccess(
      ctx,
      receiver,
      invocation.methodName.name,
      forSet: false,
      source: invocation,
    );
    if (denotation is ExtensionMemberDenotation &&
        !denotation.member.isGetter &&
        !denotation.member.isSetter) {
      final member = denotation.member;
      if (!member.isStatic) {
        final arguments = invocation.argumentList.arguments;
        if (arguments.isEmpty || arguments.first is NamedArgument) {
          throw CompileError(
            'Extension ${receiver.ext.name} requires a receiver argument',
            invocation,
          );
        }
        final value = compileExpression(
          arguments.first.argumentExpression,
          ctx,
        );
        final bindings = matchExtensionOn(ctx, value.type, receiver.ext);
        if (bindings == null) {
          throw CompileError(
            '${value.type} is not assignable to the on clause of extension ${receiver.ext.name}',
            invocation,
          );
        }
        return invokeExtensionMethod(
          ctx,
          value,
          invocation,
          receiver.ext,
          member,
          bindings,
          argIndexOffset: 1,
        );
      }
      final target = StaticCall(
        DeferredOrOffset(
          file: receiver.ext.library,
          name: receiver.ext.memberKey(member),
        ),
        sourceDeclaration: member,
        signature: CallSignature.forDeclaration(
          ctx,
          receiver.ext.library,
          member,
        ),
      );
      final arguments = ArgumentBinder(ctx).bindSourceTarget(
        target,
        invocation.argumentList,
        typeArguments: invocation.typeArguments,
        source: invocation,
        returnContext: bound,
      );
      return target.emit(
        ctx,
        BoundCall(
          positional: arguments.positional,
          named: arguments.named,
          vectorOverride: arguments.vector(),
          runtimeTypeArguments: invocation.typeArguments == null
              ? arguments.runtimeTypeArguments
              : runtimeTypeArguments(ctx, invocation),
          returnType: arguments.declaredReturn ?? target.signature!.returnType,
        ),
      );
    }
    return invokeValue(
      CallSite(
        shape: CallShape.fromArgumentList(
          invocation.argumentList,
          invocation.typeArguments?.arguments,
        ),
        context: bound,
        source: invocation,
        inConstContext: invocation.inConstantContext,
      ),
      callee: denotation.read(ctx, source: invocation),
    );
  }

  /// A lexical `super.m()` in a folded mixin calls the body from the
  /// preceding application layer. The host's dispatch table already points
  /// at the current override, so its earlier body needs an exact offset.
  Variable? invokeLexicalSuper(CallSite site, {TypeRef? bound}) {
    final source = site.source;
    if (source is! MethodInvocation) return null;
    final name = source.methodName.name;
    final body = ctx.memberLookup.lexicalSuperBody(name, MemberKind.method);
    if (body == null) {
      final getter = ctx.memberLookup.lexicalSuperBody(name, MemberKind.getter);
      if (getter == null) return null;
      final self = ctx.lookupLocal('#this')!;
      final value = FoldedMixinGetterCall(getter, self).emit(ctx);
      return invokeValue(site, callee: value);
    }
    final member = ctx.memberLookup.lexicalSuperMember(body);
    if (member == null) return null;

    final bindings = foldedMemberTypeParams(
      ctx,
      ctx.currentClass!,
      body.declaration,
      body.library,
      ctx.enclosingLibrary ?? ctx.library,
    );
    final args = ArgumentBinder(ctx).bindDeclaration(
      body.library,
      body.declaration,
      source.argumentList,
      typeArguments: source.typeArguments,
      source: source,
      seedGenerics: bindings ?? const {},
      returnContext: bound,
    );
    final returnType =
        args.declaredReturn ??
        member.signature.returnType.substituteTypeParameters(
          member.signature.substitutionFor(args.typeArguments),
        );
    final self = ctx.lookupLocal('#this')!;
    return StaticCall(
      DeferredOrOffset(offset: body.offset),
      member: member,
      receiver: self,
      typeEnvironmentReceiver: self,
    ).emit(
      ctx,
      BoundCall(
        positional: const [],
        named: const [],
        vectorOverride: args.vector(),
        runtimeTypeArguments: args.runtimeTypeArguments,
        returnType: returnType,
      ),
    );
  }

  /// `value(args)` — a function-expression invocation.
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
    final read = ref?.getValue(ctx, site.source);
    // Function values use the closure ABI and bind their own defaults. A
    // direct target here often carries only a return type, not the formals
    // needed to safely emit a source call. Type literals retain their direct
    // construction path.
    final direct = known is StaticCall && read?.type.isFunctionLike != true
        ? known
        : null;
    final callable = direct == null ? (read ?? callee!) : null;
    final target = ClosureCall(callee: callable, known: direct);
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
          bound.positional,
          namedArgs: {for (final e in bound.named) e.$1: e.$2},
        ).result;
      }
    }
    return target.emit(ctx, bound);
  }

  /// The [Variable] behind a [Receiver] that carries a concrete value.
  Variable _receiverVariable(Receiver r) =>
      r.value ?? (throw CompileError('Unresolved import prefix'));

  /// `receiver.m(args)` — an instance-target invocation. Member resolution
  /// consults the receiver's static type (bound extensions, type literals,
  /// records, interface members, extensions, `dynamic`); emission routes
  /// through the [CallTarget] pipeline — [VirtualCall] refined by
  /// [Devirtualizer], [DynamicCall], [MemberValueCall], or a bridge path.
  Variable invokeMethod(
    Variable L,
    MethodInvocation e, {
    TypeRef? bound,
    Receiver? receiver,
  }) {
    receiver ??= receiverOf(ctx, L, pin: extensionPinOf(ctx, e.target, L.type));
    CallSite callSite() => CallSite(
      shape: CallShape.fromArgumentList(
        e.argumentList,
        e.typeArguments?.arguments,
      ),
      source: e,
      context: bound,
      inConstContext: e.inConstantContext,
    );

    // `E(x).m(...)` — explicit application pins member resolution to E.
    if (receiver case ExtensionApplicationReceiver boundExt) {
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
    ResolvedMember? resolved;
    final bool isStatic;
    TypeRef? staticType;

    // `C.new(...)` invokes the unnamed constructor.
    final staticMemberName = ctorNameOf(e.methodName.name);

    if (receiver case TypeLiteralReceiver(:final type)) {
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
          arity: callSite().shape.positionalArity,
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
          arity: callSite().shape.positionalArity,
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
          final (positional, named) = _evaluateCallShape(ctx, callSite().shape);
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
        arity: callSite().shape.positionalArity,
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

    final boundArgs = _bindInvokeMethodArgs(
      L,
      e,
      resolved: resolved,
      isStatic: isStatic,
      staticType: staticType,
      bound: bound,
    );
    return _emitResolvedInvoke(
      L,
      e,
      resolved: resolved,
      isStatic: isStatic,
      staticType: staticType,
      staticMemberName: staticMemberName,
      argsPair: boundArgs.args,
      mReturnType: boundArgs.returnType,
      resolvedTarget: boundArgs.target,
    );
  }

  /// The binding phase of [invokeMethod]: compile the argument list
  /// against the resolved target — the padded bridge ABI vector for
  /// [BridgeMember]s, the supplied-only layout for dynamic receivers, and the
  /// member's own declaration signature for source members (the interface
  /// signature while the call stays virtual, the concrete
  /// implementation's once it's static or devirtualized).
  ({BoundCall args, TypeRef? returnType, CallTarget? target})
  _bindInvokeMethodArgs(
    Variable L,
    MethodInvocation e, {
    required ResolvedMember? resolved,
    required bool isStatic,
    required TypeRef? staticType,
    required TypeRef? bound,
  }) {
    TypeRef? mReturnType;
    BoundCall argsPair;
    CallTarget? target;
    final bridgeTypeParameters = <String, TypeRef>{};
    final resolvedMember = resolved?.member;
    if (resolvedMember is BridgeMember) {
      final br = resolvedMember.def;
      final fd = br is BridgeMethodDef
          ? br.functionDescriptor
          : (br as BridgeConstructorDef).functionDescriptor;
      final ownerType = isStatic ? staticType! : resolved!.viewedAs;
      final receiverTypeParameters = isStatic
          ? const <String, TypeRef>{}
          : _bridgeClassTypeArguments(
              ctx,
              L.type,
              resolvedMember.ownerDecl!.library,
            );
      final signature = CallSignature.bridge(
        ctx,
        fd,
        returnFallback: CoreTypes.dynamic.ref(ctx),
        owner: ownerType,
        typeParameters: receiverTypeParameters,
      );
      final bridgeTargetName = isStatic
          ? '${staticType!.name}.${e.methodName.name}'
          : null;
      final externalIndex = bridgeTargetName == null
          ? null
          : ctx.bridgeStaticFunctionIndices[staticType!
                .file]?[bridgeTargetName];
      if (isStatic && externalIndex == null) {
        throw CompileError(
          'Bridge target $bridgeTargetName is not registered',
          e,
        );
      }
      target = isStatic
          ? StaticCall(
              null,
              externalIndex: externalIndex,
              member: resolvedMember,
              bridgeFunction: fd,
              signature: signature,
            )
          : BridgeCall(
              receiver: L,
              name: e.methodName.name,
              member: resolvedMember,
              signature: signature,
            );
      argsPair = ArgumentBinder(ctx).bindBridgeTarget(target, e.argumentList);
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
        argsPair.positional,
        bridgeTypeParameters,
        inferableNames: classGenericNames,
      );
      final resultSignature = bridgeTypeParameters.isEmpty
          ? target.signature!
          : CallSignature.bridge(
              ctx,
              fd,
              returnFallback: CoreTypes.dynamic.ref(ctx),
              owner: ownerType,
              typeParameters: {
                ...receiverTypeParameters,
                ...bridgeTypeParameters,
              },
            );
      mReturnType = resolveCallResultType(
        ctx,
        signature: resultSignature,
        targetType: isStatic ? staticType : L.type,
        argTypes: argsPair.positional.map((a) => a.type).toList(),
        namedArgTypes: argsPair.namedValues.map((k, v) => MapEntry(k, v.type)),
      );
    } else if (L.type.isSpec(CoreTypes.dynamic)) {
      target = DynamicCall(
        receiver: L.copyIntoFreshSlot(ctx, 'dynamic_receiver'),
        name: e.methodName.name,
      );
      argsPair = ArgumentBinder(ctx).bindSuppliedOnly(
        target,
        CallSite(
          shape: CallShape.fromArgumentList(
            e.argumentList,
            e.typeArguments?.arguments,
          ),
          context: bound,
          source: e,
        ),
        callee: null,
      );
    } else {
      final sourceMember = resolved!.member as SourceMember;
      final declaration = sourceMember.sourceDeclaration;
      if (declaration is MethodDeclaration) {
        // Refine before binding. The chosen target owns the signature and
        // default policy, including an override's concrete defaults.
        target = isStatic
            ? StaticCall(
                DeferredOrOffset.lookupStatic(
                  ctx,
                  staticType!.file,
                  staticType.name,
                  e.methodName.name,
                ),
                member: sourceMember,
              )
            : e.target is SuperExpression
            ? Devirtualizer(ctx).refineSuper(
                VirtualCall(
                  receiver: L,
                  name: e.methodName.name,
                  member: sourceMember,
                ),
              )
            : Devirtualizer(ctx).refine(
                VirtualCall(
                  receiver: L,
                  name: e.methodName.name,
                  member: sourceMember,
                ),
              );
        if (e.target is SuperExpression && target is VirtualCall) {
          throw CompileError(
            'Cannot resolve a direct target for super.${e.methodName.name}',
            e,
          );
        }
        final seedGenerics = isStatic
            ? const <String, TypeRef>{}
            : _sourceTargetTypeArguments(target, resolved);
        argsPair = ArgumentBinder(ctx).bindSourceTarget(
          target,
          e.argumentList,
          typeArguments: e.typeArguments,
          source: e,
          seedGenerics: seedGenerics,
          returnContext: bound,
        );
      } else if (declaration is ConstructorDeclaration && isStatic) {
        target = ConstructorCall(
          staticType: staticType!,
          name: e.methodName.name,
          offset: DeferredOrOffset.lookupStatic(
            ctx,
            staticType.file,
            staticType.name,
            e.methodName.name,
          ),
          constructor: declaration,
          isConst: e.inConstantContext,
          signature: sourceMember.signature,
        );
        argsPair = ArgumentBinder(ctx).bindSourceTarget(
          target,
          e.argumentList,
          typeArguments: e.typeArguments,
          source: e,
          returnContext: bound,
        );
      } else {
        argsPair = ArgumentBinder(ctx).bindDeclaration(
          sourceMember.library,
          declaration,
          e.argumentList,
          typeArguments: e.typeArguments,
          source: e,
          returnContext: bound,
        );
      }
      mReturnType = argsPair.declaredReturn;
    }

    return (args: argsPair, returnType: mReturnType, target: target);
  }

  /// Bind receiver class parameters in the selected implementation's scope.
  /// A virtual call uses the interface view; a direct call may instead name
  /// an inherited implementation with a different declaring type.
  Map<String, TypeRef> _sourceTargetTypeArguments(
    CallTarget target,
    ResolvedMember resolved,
  ) {
    if (target is VirtualCall) return resolved.ownerTypeArguments;
    final (member, link) = switch (target) {
      StaticCall(member: SourceMember member, :final declaringLink) => (
        member,
        declaringLink,
      ),
      _ => throw StateError('Expected a source method target'),
    };
    final owner = member.declaringDecl ?? member.ownerDecl;
    final viewedAs = link == null
        ? resolved.viewedAs
        : ctx.typeSystem.asInstanceOf(link, owner) ?? link;
    return ownerTypeArgumentsOf(owner, viewedAs);
  }

  /// The emission phase of [invokeMethod]: resolve the call's return type
  /// and emit through the matching [CallTarget] — [ConstructorCall] or
  /// [StaticCall] for resolved static members, [BridgeCall] for bridge
  /// members, [DynamicCall] for dynamic receivers, and the devirtualized
  /// [VirtualCall] otherwise.
  Variable _emitResolvedInvoke(
    Variable L,
    MethodInvocation e, {
    required ResolvedMember? resolved,
    required bool isStatic,
    required TypeRef? staticType,
    required String staticMemberName,
    required BoundCall argsPair,
    required TypeRef? mReturnType,
    required CallTarget? resolvedTarget,
  }) {
    final resolvedMember = resolved?.member;
    final returnType =
        mReturnType ??
        memberCallResultType(
          ctx,
          isStatic ? staticType ?? CoreTypes.dynamic.ref(ctx) : L.type,
          staticMemberName,
          [for (final arg in argsPair.positional) arg.type],
          {for (final (name, arg) in argsPair.named) name: arg.type},
          $static: isStatic,
          source: e,
        ) ??
        CoreTypes.dynamic.ref(ctx);
    final explicitTypeArguments = runtimeTypeArguments(ctx, e);
    final boundCall = BoundCall(
      receiver: isStatic ? null : L,
      positional: argsPair.positional,
      named: argsPair.named,
      runtimeTypeArguments: explicitTypeArguments.isNotEmpty
          ? explicitTypeArguments
          : argsPair.runtimeTypeArguments,
      returnType: returnType,
      // Source direct calls can include hidden arguments. Bridge calls need
      // their padded vector; other instance calls use only supplied values.
      vectorOverride: isStatic || resolvedMember is BridgeMember
          ? argsPair.vector()
          : null,
    );
    if (resolvedMember is BridgeMember) {
      // Instance calls that carry no named or explicit type arguments take
      // the intrinsic path, which preserves operator optimizations for
      // core types. The argument vector stays padded with null
      // placeholders so generated wrappers keep the flattened ABI; the
      // declared return type (inferred generics and parameter-type
      // dependencies included) still applies to the result.
      if (!isStatic && e.typeArguments == null && argsPair.named.isEmpty) {
        final invokeResult = invokeOperator(
          L,
          e.methodName.name,
          argsPair.positional,
        ).result;
        final preciseType = mReturnType;
        if (preciseType != null) {
          return invokeResult.copyWith(type: preciseType);
        }
        return invokeResult;
      }
    }
    final target =
        resolvedTarget ??
        (isStatic
            ? StaticCall(
                DeferredOrOffset.lookupStatic(
                  ctx,
                  staticType!.file,
                  staticType.name,
                  staticMemberName,
                ),
                member: resolvedMember,
              )
            : throw StateError('Instance call has no resolved target'));
    return target.emit(ctx, boundCall);
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
      // `E(x)` pins member resolution to E, including operator members.
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
      positional: prepared,
      named: [
        for (final entry in (namedArgs ?? const <String, Variable>{}).entries)
          (entry.key, entry.value.boxIfNeeded(ctx)),
      ],
      returnType: returnType,
    );
    ResolvedMember? opResolved;
    if (!isBareCall && !recv.type.isSpec(CoreTypes.dynamic)) {
      try {
        opResolved = ctx.memberLookup.interfaceMember(
          recv.type,
          ctx.memberNameOf(method, MemberKind.method),
        );
      } on CompileError {
        // No resolvable declaration — the untyped dispatch applies.
      }
    }
    final target = Devirtualizer(ctx).refine(
      VirtualCall(receiver: recv, name: method, member: opResolved?.member),
    );
    if (opResolved?.member case SourceMember sourceMember
        when sourceMember.sourceDeclaration is MethodDeclaration) {
      final seedGenerics = _sourceTargetTypeArguments(target, opResolved!);
      final typed = ArgumentBinder(ctx).bindSourceValues(
        target,
        prepared,
        namedArgs ?? const {},
        seedGenerics: seedGenerics,
      );
      boundCall = BoundCall(
        receiver: recv,
        positional: typed.positional,
        named: typed.named,
        runtimeTypeArguments: typed.runtimeTypeArguments,
        returnType: target.signature?.returnAnnotated == true
            ? typed.returnType
            : returnType,
      );
    }
    final result = target.emit(ctx, boundCall);
    return (
      target: recv,
      result: result,
      args: boundCall.positional,
      namedArgs: boundCall.namedValues,
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
    final (result, bound) = invokeValueWithArgs(
      CallSite(shape: CallShape.values(args, namedArgs)),
      callee: callee,
    );
    return (
      target: null,
      result: result,
      args: bound.positional,
      namedArgs: {for (final e in bound.named) e.$1: e.$2},
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
    final target = StaticCall(
      DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
      receiver: receiver.boxIfNeeded(ctx),
      sourceDeclaration: member,
      signature: CallSignature.forDeclaration(ctx, ext.library, member),
    );
    final bound = ArgumentBinder(ctx).bindSourceValues(
      target,
      args,
      const {},
      seedGenerics: typeParams,
      source: member,
    );
    return (
      target: receiver,
      result: target.emit(
        ctx,
        BoundCall(
          positional: bound.positional,
          named: bound.named,
          runtimeTypeArguments:
              extensionCallTypeArguments(
                ctx,
                ext,
                member,
                bindings,
                bound.typeArguments,
              ) ??
              const [],
          returnType: bound.returnType,
          vectorOverride: bound.vector(),
        ),
      ),
      args: bound.positional,
      namedArgs: bound.namedValues,
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
          ? ctx.lookupLocal('#this') ??
                (throw CompileError(
                  'Cannot access instance member $name without an instance receiver',
                  e,
                ))
          : _receiverVariable(d.receiver!);
      return invokeMethod(recv, e, bound: bound);
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
      return invokeValue(
        CallSite(
          receiver: site.receiver,
          name: site.name,
          shape: site.shape,
          context: bound,
          source: site.source,
          inConstContext: site.inConstContext,
        ),
        ref: ref,
      );
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
          sourceDecl = ctx
              .topLevelDeclarationsMap[resolved.file]!['${resolved.name}.']
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
        sourceDecl = ctx
            .topLevelDeclarationsMap[type.file]?[constructorKey]
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

    // Resolve the call kind and its declaration shape before any argument
    // compiles. Constructor instantiation is completed after inference and
    // delivered through BoundCall.returnType.
    final CallTarget callTarget;
    if (bridgeDecl is BridgeClassDef) {
      final bridge = bridgeDecl;
      final function =
          bridge.constructors['']?.functionDescriptor ??
          (throw CompileError(
            'Class "${e.methodName.name}" does not have a default constructor',
            e,
          ));
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);
      callTarget = ConstructorCall(
        staticType: type,
        externalIndex:
            ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.']!,
        classBridge: bridge,
        isConst: e.inConstantContext,
        bridgeFunction: function,
        signature: CallSignature.bridge(
          ctx,
          function,
          returnFallback: CoreTypes.dynamic.ref(ctx),
        ),
      );
    } else if (bridgeDecl is BridgeFunctionDeclaration) {
      final function = bridgeDecl.function;
      callTarget = StaticCall(
        null,
        externalIndex:
            ctx.bridgeStaticFunctionIndices[offset.file]![offset.name]!,
        bridgeFunction: function,
        signature: CallSignature.bridge(
          ctx,
          function,
          returnFallback: CoreTypes.dynamic.ref(ctx),
        ),
      );
    } else if (sourceDecl is ConstructorDeclaration) {
      callTarget = ConstructorCall(
        staticType: aliasType ?? sigReturn!,
        offset: offset,
        constructor: sourceDecl,
        isConst: e.inConstantContext,
        signature: CallSignature.forDeclaration(ctx, offset.file!, sourceDecl),
      );
    } else if (sourceDecl != null) {
      callTarget = StaticCall(
        offset,
        sourceDeclaration: sourceDecl,
        signature: CallSignature.forDeclaration(ctx, offset.file!, sourceDecl),
      );
    } else {
      throw CompileError('Cannot call $name', e);
    }

    final List<Variable> args;
    final Map<String, Variable> namedArgs;
    final List<SSA> callArgs;
    List<int> inferredTypeArgs = const [];

    final isConstructor = callTarget is ConstructorCall;
    List<TypeRef>? inferredCtorArgs;

    if (bridgeDecl != null) {
      final argsPair = ArgumentBinder(
        ctx,
      ).bindBridgeTarget(callTarget, e.argumentList);

      args = argsPair.positional;
      namedArgs = argsPair.namedValues;
      callArgs = argsPair.vector();
    } else {
      final dec = sourceDecl!;
      final result = ArgumentBinder(ctx).bindSourceTarget(
        callTarget,
        e.argumentList,
        typeArguments: e.typeArguments,
        source: e,
        returnContext: bound,
      );

      mReturnType = result.declaredReturn;
      args = result.positional;
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
      vectorOverride: callArgs,
    );
    return callTarget.emit(ctx, boundCall);
  }
}

Map<String, TypeRef> _bridgeClassTypeArguments(
  CompilerContext ctx,
  TypeRef receiver,
  int declarationLibrary,
) {
  final declaration =
      ctx.topLevelDeclarationsMap[declarationLibrary]?[receiver.name];
  final bridge = declaration?.bridge;
  if (bridge is! BridgeClassDef) return const {};
  final names = bridge.type.generics.keys.toList();
  final arguments = interfaceArgumentsOf(receiver);
  return {
    for (
      var index = 0;
      index < names.length && index < arguments.length;
      index++
    )
      names[index]: arguments[index],
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

TypeRef instantiateConstructorType(
  CompilerContext ctx,
  MethodInvocation invocation,
  TypeRef base, [
  List<TypeRef>? inferredArgs,
]) {
  final arguments = invocation.typeArguments?.arguments;
  if (arguments == null || arguments.isEmpty) {
    if (inferredArgs == null) return base;
    final baseArgs = interfaceArgumentsOf(base);
    if (baseArgs.isEmpty || baseArgs.every((a) => a.isTypeParameter)) {
      return (base as InterfaceTypeRef).copyWith(arguments: inferredArgs);
    }
    return base.substituteTypeParameters(
      Substitution.of({
        for (var i = 0; i < inferredArgs.length; i++)
          (nominalDeclOf(base)?.typeParameters[i] ??
                  ctx.typeParameterDefs.key(
                    TypeParameterOwner(
                      TypeParameterOwnerKind.classLike,
                      base.file,
                      base.name,
                    ),
                    i,
                    '',
                  )):
              inferredArgs[i],
      }),
    );
  }
  return (base as InterfaceTypeRef).copyWith(
    arguments: [
      for (final argument in arguments)
        TypeRef.fromAnnotation(ctx, ctx.library, argument),
    ],
  );
}

/// Evaluate a call shape in source order before dynamic dispatch.
/// The receiver has already been read by the caller.
(List<Variable>, Map<String, Variable>) _evaluateCallShape(
  CompilerContext ctx,
  CallShape shape,
) {
  final positional = List<Variable?>.filled(shape.positional.length, null);
  final named = <String, Variable>{};
  for (final index in shape.sourceOrder) {
    if (index >= 0) {
      positional[index] = compileExpression(
        (shape.positional[index] as ExpressionArg).expression,
        ctx,
      );
    } else {
      final (name, source) = shape.named[-1 - index];
      named[name] = compileExpression(
        (source as ExpressionArg).expression,
        ctx,
      );
    }
  }
  return (positional.cast<Variable>(), named);
}

/// Compiles `E(receiver)` — explicit extension application. The resolver
/// handles the extension pin at the call site; this validates the receiver
/// and returns its value without retaining a local binding.
Variable applyExtension(
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
  boundExtensionFor(ctx, e, ext, receiver.type); // validates `on` bindings
  // The application result shares the receiver's SSA but cannot rebind the
  // source local when a later conversion changes its representation.
  return receiver.copyWith()..binding = null;
}

/// Emits a call to a resolved extension member: `x.m(args)` and the
/// explicit `E.m(x, args)` both land here — the receiver binds through the
/// vector's leading slot and is skipped in the arg list for the explicit
/// form ([argIndexOffset]); the extension's `on` bindings plus the
/// method's resolved type arguments go in the type environment.
Variable invokeExtensionMethod(
  CompilerContext ctx,
  Variable receiver,
  MethodInvocation call,
  EvalExtension ext,
  MethodDeclaration member,
  List<TypeRef> bindings, {
  int argIndexOffset = 0,
}) {
  final extParams =
      ext.declaration.typeParameters?.typeParameters ?? const <TypeParameter>[];
  final target = StaticCall(
    DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
    sourceDeclaration: member,
    signature: CallSignature.forDeclaration(ctx, ext.library, member),
  );
  final result = ArgumentBinder(ctx).bindSourceTarget(
    target,
    call.argumentList,
    before: [receiver.boxIfNeeded(ctx)],
    typeArguments: call.typeArguments,
    seedGenerics: {
      for (var i = 0; i < bindings.length && i < extParams.length; i++)
        extParams[i].name.lexeme: bindings[i],
    },
    argIndexOffset: argIndexOffset,
    source: call,
  );

  return target.emit(
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
            result.typeArguments,
          ) ??
          runtimeTypeArguments(ctx, call),
      returnType: result.declaredReturn ?? CoreTypes.dynamic.ref(ctx),
      vectorOverride: result.vector(),
    ),
  );
}

List<int> runtimeTypeArguments(CompilerContext ctx, MethodInvocation call) =>
    call.typeArguments?.arguments
        .map((type) => TypeRef.fromAnnotation(ctx, ctx.library, type))
        .map((type) => ctx.runtimeTypes.idOf(type))
        .toList() ??
    const [];

/// Resolves the receiver for a `super.m(args)` call. A missing concrete
/// member dispatches to noSuchMethod on the real receiver.
(Variable, Variable?) resolveSuperReceiver(
  CompilerContext ctx,
  MethodInvocation e,
  Variable receiver,
) {
  final name = e.methodName.name;
  final target = ctx.memberLookup.superMemberTarget(
    receiver.type,
    name,
    kind: MemberKind.getter,
    methodCall: true,
  );
  if (!target.found) {
    // A getter-shaped call reads before evaluating the arguments.
    if (target.abstractGetter ?? false) {
      final getterValue = NoSuchMethodCall(
        name: name,
        getterShaped: true,
      ).emitGetterValue(ctx);
      return (
        receiver,
        CallResolver(ctx).invokeValue(
          CallSite(
            shape: CallShape.fromArgumentList(
              e.argumentList,
              e.typeArguments?.arguments,
            ),
            source: e,
          ),
          callee: getterValue,
        ),
      );
    }
    final fallback = NoSuchMethodCall(name: name);
    final bound = ArgumentBinder(ctx).bindSuppliedOnly(
      fallback,
      CallSite(
        shape: CallShape.fromArgumentList(
          e.argumentList,
          e.typeArguments?.arguments,
        ),
        source: e,
      ),
      callee: null,
    );
    return (receiver, fallback.emit(ctx, bound));
  }

  if (target.hops.isEmpty && target.owner != receiver.type) {
    receiver = Variable.of(
      ctx,
      receiver.ssa,
      target.owner,
      rep: receiver.rep,
      facts: ValueFacts(possibleClasses: [target.owner]),
    );
  }
  for (final parent in target.hops) {
    receiver = Variable.ssa(
      ctx,
      LoadSuper(ctx.svar('super'), receiver.ssa),
      parent,
      facts: ValueFacts(possibleClasses: [parent]),
    );
  }
  return (receiver, null);
}
