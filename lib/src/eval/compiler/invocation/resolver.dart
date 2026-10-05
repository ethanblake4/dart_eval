import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/variable/value_facts.dart';
import 'package:dart_eval/src/eval/ir/alu.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/macros/loop.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/variable/binding.dart';
import 'package:dart_eval/src/eval/compiler/values/value_rep.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/helpers/context_type.dart';
import '../helpers/constructor_type.dart';
import '../helpers/extension_type.dart';
import '../helpers/external.dart';
import '../helpers/weak_tearoff.dart';
import 'package:dart_eval/src/eval/compiler/helpers/mixin_application.dart';
import '../member/call_signature.dart';
import '../member/resolved_member.dart';
import 'deferred.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show Assign, SSA;
import 'binder.dart';
import 'bound_call.dart';
import 'call.dart';
import 'accessors.dart';
import 'devirtualizer.dart';
import 'intrinsics.dart';
import 'numeric_types.dart';
import 'targets.dart';

const _nonNullReceiverOperators = {
  '+',
  '-',
  '*',
  '/',
  '~/',
  '%',
  '<',
  '>',
  '<=',
  '>=',
  '&',
  '|',
  '^',
  '<<',
  '>>',
  '>>>',
  '~',
  'unary-',
  '[]',
  '[]=',
};

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
          bound: bound,
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
      if (getter == null) {
        final host = ctx.currentClass;
        if (host is! EnumDeclaration || name != 'toString') return null;
        if (source.argumentList.arguments.isNotEmpty ||
            source.typeArguments != null) {
          throw CompileError('Enum.toString takes no arguments', source);
        }
        final library = ctx.enclosingLibrary ?? ctx.library;
        final offset = ctx
            .enumBaseToStringOffsets[(library, host.namePart.typeName.lexeme)]!;
        return StaticCall(
          DeferredOrOffset(offset: offset),
          receiver: ctx.lookupLocal('#this')!,
        ).emit(
          ctx,
          BoundCall(
            positional: const [],
            named: const [],
            returnType: CoreTypes.string.ref(ctx),
          ),
        );
      }
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
    if (callable != null) _checkImplicitCallable(callable.type, site);
    if (callable != null) {
      final extension = _implicitCallExtension(callable.type, site);
      if (extension != null) {
        // An argument can assign to the callee's local slot. Capture its
        // value now; member-value calls still read after their arguments.
        final boxed = callable.boxed
            ? callable
            : callable.boxIntoFreshSlot(ctx);
        final receiver = Variable.ssa(
          ctx,
          Assign(ctx.svar('extension_target'), boxed.ssa),
          boxed.type,
          rep: boxed.rep,
        );
        return _invokeExtensionValue(site, () => receiver, extension);
      }
    }
    final target = ClosureCall(callee: callable, known: direct);
    final bound = ArgumentBinder(
      ctx,
    ).bindSuppliedOnly(target, site, callee: callable);
    return (target.emit(ctx, bound), bound);
  }

  (EvalExtension, MethodDeclaration, List<TypeRef>)? _implicitCallExtension(
    TypeRef type,
    CallSite site,
  ) {
    if (type.isFunctionLike ||
        type.isSpec(CoreTypes.dynamic) ||
        ctx.memberLookup.hasInstanceMember(type, MemberName.method('call'))) {
      return null;
    }
    return resolveExtensionMember(
      ctx,
      type,
      'call',
      arity: site.shape.positionalArity,
    );
  }

  (Variable, BoundCall) _invokeExtensionValue(
    CallSite site,
    Variable Function() read,
    (EvalExtension, MethodDeclaration, List<TypeRef>) extension,
  ) {
    final (ext, member, bindings) = extension;
    final signature = CallSignature.forDeclaration(ctx, ext.library, member);
    final extParams = ext.declaration.typeParameters?.typeParameters;
    final arguments = ArgumentBinder(ctx).bindDeclaration(
      ext.library,
      member,
      null,
      suppliedShape: site.shape,
      typeArguments: switch (site.source) {
        FunctionExpressionInvocation(:final typeArguments) => typeArguments,
        MethodInvocation(:final typeArguments) => typeArguments,
        _ => null,
      },
      seedGenerics: {
        for (var i = 0; i < bindings.length; i++)
          extParams![i].name.lexeme: bindings[i],
      },
      source: site.source,
      returnContext: site.context,
      targetSignature: signature,
    );
    final target = StaticCall(
      DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
      receiver: read().boxIfNeeded(ctx),
      sourceDeclaration: member,
      signature: signature,
    );
    final bound = BoundCall(
      positional: arguments.positional,
      named: arguments.named,
      vectorOverride: arguments.vector(),
      returnType: arguments.declaredReturn ?? CoreTypes.dynamic.ref(ctx),
      runtimeTypeArguments:
          extensionCallTypeArguments(
            ctx,
            ext,
            member,
            bindings,
            arguments.typeArguments,
          ) ??
          const [],
    );
    return (target.emit(ctx, bound), bound);
  }

  void _checkImplicitCallable(TypeRef type, CallSite site) {
    type = ctx.typeSystem.throughTypeParameters(type);
    if (type is TypeParameterTypeRef) {
      throw CompileError('Type $type is not callable', site.source);
    }
    if (type.isFunctionLike ||
        type.isSpec(CoreTypes.dynamic) ||
        type.isSpec(CoreTypes.never)) {
      return;
    }
    final member = ctx.memberLookup
        .tryInterfaceMember(
          type,
          MemberName.method('call'),
          source: site.source,
        )
        ?.member;
    if (member != null) {
      final isMethod = switch (member) {
        SourceMember(:final node) =>
          node is MethodDeclaration && !node.isGetter && !node.isSetter,
        BridgeMember(:final def, :final name) =>
          def is BridgeMethodDef && name.kind == MemberKind.method,
      };
      if (isMethod && !member.isStatic) return;
    } else if (resolveExtensionMember(
          ctx,
          type,
          'call',
          arity: site.shape.positionalArity,
        ) !=
        null) {
      return;
    }
    throw CompileError('Type $type is not callable', site.source);
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
    if (L.type.isSpec(CoreTypes.never)) return L;
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
        bound: bound,
      );
    }
    ResolvedMember? resolved;
    final bool isStatic;
    TypeRef? staticType;

    // `C.new(...)` invokes the unnamed constructor.
    final staticMemberName = ctorNameOf(e.methodName.name);

    if (receiver case TypeLiteralReceiver(:final type)) {
      final declaration = nominalDeclOf(type);
      if (declaration is SourceTypeDecl &&
          declaration.kind == TypeDeclKind.extensionType &&
          isExtensionTypeConstructor(declaration, staticMemberName)) {
        return constructExtensionType(
          ctx,
          declaration,
          type,
          staticMemberName,
          e.argumentList,
          isConst: callSite().inConstContext,
          source: e,
        );
      }
      // Static method
      staticType = type;
      final staticMember = ctx.memberLookup.staticMember(
        staticType,
        staticMemberName,
        MemberKind.method,
      );
      if (staticMember == null) {
        final enumValue =
            ctx.enumValueIndices[type.file]?[type.name]?[staticMemberName];
        if (enumValue != null) {
          return _invokeEnumConstant(
            IdentifierReference(L, staticMemberName).getValue(ctx, e),
            e,
            bound,
          );
        }
        // A member invoked on a `Type` literal may still be an extension
        // member on `Type` — `C.expectStaticType<Exactly<Type>>()`.
        final found = resolveExtensionMember(
          ctx,
          L.type,
          e.methodName.name,
          arity: callSite().shape.positionalArity,
        );
        if (found != null) {
          return invokeExtensionMethod(
            ctx,
            L,
            e,
            found.$1,
            found.$2,
            found.$3,
            bound: bound,
          );
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
      resolved = ResolvedMember(
        staticMember,
        staticMember.ownerDecl?.thisType ?? staticType,
      );
      isStatic = true;
    } else if (L.type.isFunctionLike && e.methodName.name == 'call') {
      // `fn.call(...)`: Function has no declared `call` member; the call is
      // the invocation itself, typed by the callee's own signature.
      return invokeValue(callSite(), callee: L);
    } else if (!L.type.isSpec(CoreTypes.dynamic) &&
        !(L.type is TypeParameterTypeRef &&
            extensionLookupType(ctx, L.type).isSpec(CoreTypes.dynamic))) {
      // `record.field(args)` on a named record field invokes the field's
      // value — a property read followed by an implicit `.call`, matching
      // the field/getter path below.
      final receiverType = L.type;
      if (extensionRepresentationField(ctx, receiverType, e.methodName.name) !=
          null) {
        return invokeValue(
          callSite(),
          callee: IdentifierReference(L, e.methodName.name).getValue(ctx, e),
        );
      }
      if (receiverType is RecordTypeRef &&
          receiverType.named.containsKey(e.methodName.name)) {
        final target = MemberValueCall(
          read: (ctx) => GetTarget.read(ctx, L, e.methodName.name),
          valueType: receiverType.named[e.methodName.name],
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
          return invokeExtensionMethod(
            ctx,
            L,
            e,
            found.$1,
            found.$2,
            found.$3,
            bound: bound,
          );
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
        // A recorded member promotion narrows the read — after
        // `if (_f is T Function())`, `_f()` yields `T`, not `T?`.
        // `super._f`'s facts live on `#this` under a `super:` key.
        final viaSuper = e.target is SuperExpression;
        Variable readMember(CompilerContext ctx) {
          final value = GetTarget.read(ctx, L, e.methodName.name);
          final factOwner = viaSuper
              ? ctx.lookupLocal('#this')
              : L.binding?.current ?? L;
          final recorded =
              factOwner?.facts.promotedMembers?[viaSuper
                  ? 'super:${e.methodName.name}'
                  : e.methodName.name];
          return recorded == null ? value : value.withType(recorded);
        }

        if (viaSuper) {
          // `super.m(args)` is a function-expression invocation: the member
          // value is read before the arguments evaluate.
          return invokeValue(callSite(), callee: readMember(ctx));
        }
        // `receiver.field(...)` / `receiver.getter(...)`: the member's
        // *value* is invoked, not a method — property read then implicit
        // `.call`. The arguments evaluate before the member read.
        final factOwner = L.binding?.current ?? L;
        final valueType =
            factOwner.facts.promotedMembers?[e.methodName.name] ??
            ctx.memberLookup.fieldType(L.type, e.methodName.name, source: e);
        if (valueType != null) {
          final extension = _implicitCallExtension(valueType, callSite());
          if (extension != null) {
            return _invokeExtensionValue(
              callSite(),
              () => readMember(ctx),
              extension,
            ).$1;
          }
        }
        final target = MemberValueCall(read: readMember, valueType: valueType);
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
        return invokeExtensionMethod(
          ctx,
          L,
          e,
          found.$1,
          found.$2,
          found.$3,
          bound: bound,
        );
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
      if (memberDecl is MethodDeclaration) {
        final weak = compileWeakTearOffReference(
          ctx,
          (resolved!.member as SourceMember).library,
          memberDecl,
          e,
          bound: bound,
        );
        if (weak != null) return weak;
      }
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
            bound: bound,
          );
        }
      }
    }

    final (target, arguments) = _bindMethod(
      L,
      e,
      resolved: resolved,
      isStatic: isStatic,
      staticType: staticType,
      bound: bound,
    );
    if (e.target is SuperExpression &&
        e.methodName.name == 'toString' &&
        resolved?.member is BridgeMember &&
        resolved!.member.ownerDecl?.thisType.isSpec(CoreTypes.object) == true) {
      // Source instances have no Object link. Its lexical default still uses
      // the real receiver's type, bypassing any overridden toString/runtimeType.
      final type = Variable.ssa(
        ctx,
        LoadRuntimeType(ctx.svar('object_type'), ctx.lookupLocal('#this')!.ssa),
        CoreTypes.type.ref(ctx),
      );
      final name = invokeOperator(type, 'toString', const []).result;
      final prefix = BuiltinValue(stringval: "Instance of '").push(ctx);
      final suffix = BuiltinValue(stringval: "'").push(ctx);
      final description = invokeOperator(prefix, '+', [name]).result;
      return invokeOperator(description, '+', [suffix]).result;
    }
    if (resolved?.member is BridgeMember &&
        !isStatic &&
        e.typeArguments == null &&
        arguments.named.isEmpty) {
      if (e.methodName.name == 'forEach') {
        final forEach = _tryCompileNativeForEach(
          L,
          arguments.positional,
          resolved,
        );
        if (forEach != null) return forEach;
      }
      final intrinsic = Intrinsics(
        ctx,
      ).tryEmit(L, e.methodName.name, arguments.positional);
      if (intrinsic != null) {
        return intrinsic.result.type.isSpec(CoreTypes.voidType)
            ? intrinsic.result
            : intrinsic.result.copyWith(type: arguments.returnType);
      }
      return _invokeResolvedOperator(
        L,
        e.methodName.name,
        arguments.positional,
        null,
        resolved: resolved,
        returnType: arguments.returnType,
      ).result;
    }
    return target.emit(ctx, arguments);
  }

  /// The binding phase of [invokeMethod]: compile the argument list
  /// against the resolved target — the padded bridge ABI vector for
  /// [BridgeMember]s, the supplied-only layout for dynamic receivers, and the
  /// member's own declaration signature for source members (the interface
  /// signature while the call stays virtual, the concrete
  /// implementation's once it's static or devirtualized).
  (CallTarget, BoundCall) _bindMethod(
    Variable L,
    MethodInvocation e, {
    required ResolvedMember? resolved,
    required bool isStatic,
    required TypeRef? staticType,
    required TypeRef? bound,
    String? invokedName,
  }) {
    final methodName = invokedName ?? e.methodName.name;
    TypeRef? mReturnType;
    BoundCall argsPair;
    CallTarget target;
    final bridgeTypeParameters = <String, TypeRef>{};
    final resolvedMember = resolved?.member;
    if (resolvedMember is BridgeMember) {
      final br = resolvedMember.def;
      final fd = br is BridgeMethodDef
          ? br.functionDescriptor
          : (br as BridgeConstructorDef).functionDescriptor;
      final ownerType = isStatic ? staticType! : resolved!.viewedAs;
      final receiverTypeParameters = isStatic
          // The class's own generics stay as parameters while arguments
          // bind — `Iterable<T>` keeps literal arguments at their natural
          // type and `T` is inferred from them afterwards.
          ? bridgeClassGenericParameters(ctx, staticType!)
          : _bridgeClassTypeArguments(
              ctx,
              ownerType,
              resolvedMember.ownerDecl!.library,
            );
      if (isStatic && br is BridgeConstructorDef) {
        // Omitted class arguments are inferred at this call, rather than
        // constrained by the declaring class's type-parameter bounds.
        var index = 0;
        for (final name in receiverTypeParameters.keys) {
          bridgeTypeParameters[name] = TypeParameterTypeRef(
            ctx.typeParameterDefs.key(
              TypeParameterOwner(
                TypeParameterOwnerKind.callSite,
                ctx.library,
                '${staticType!.name}.$methodName',
                e.offset,
              ),
              index++,
              name,
            ),
          );
        }
      }
      if (isStatic && br is BridgeConstructorDef && bound != null) {
        final declaration = nominalDeclOf(staticType!);
        final context = inferContextType(
          ctx,
          declaration?.thisType ?? staticType,
          bound,
        );
        final view = declaration == null
            ? null
            : ctx.typeSystem.asInstanceOf(
                declaration.thisType,
                nominalDeclOf(context),
              );
        if (view != null) {
          final inferred = <TypeParameterDef, TypeRef>{};
          ctx.typeSystem.unify(view, context, inferred);
          for (final entry in receiverTypeParameters.entries) {
            final parameter = (entry.value as TypeParameterTypeRef).parameter;
            if (inferred[parameter] case final argument?) {
              bridgeTypeParameters[entry.key] = argument;
            }
          }
        }
      }
      final signature = CallSignature.bridge(
        ctx,
        fd,
        returnFallback: CoreTypes.dynamic.ref(ctx),
        owner: ownerType,
        typeParameters: {
          ...receiverTypeParameters.cast<String, TypeRef>(),
          ...bridgeTypeParameters,
        },
      );
      final bridgeTargetName = isStatic
          ? '${staticType!.name}.${ctorNameOf(methodName)}'
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
          ? br is BridgeConstructorDef
                ? ConstructorCall(
                    staticType: staticType!,
                    name: ctorNameOf(methodName),
                    externalIndex: externalIndex,
                    classBridge: resolvedMember.ownerDecl is BridgeTypeDecl
                        ? (resolvedMember.ownerDecl as BridgeTypeDecl).classDef
                        : null,
                    bridgeFunction: fd,
                    signature: signature,
                    isConst: e.inConstantContext,
                  )
                : StaticCall(
                    null,
                    externalIndex: externalIndex,
                    member: resolvedMember,
                    bridgeFunction: fd,
                    signature: signature,
                  )
          : BridgeCall(
              receiver: L,
              name: methodName,
              member: resolvedMember,
              signature: signature,
            );
      final numericContexts =
          !isStatic &&
              const {'remainder', 'clamp'}.contains(methodName) &&
              L.type.isAssignableTo(
                ctx,
                CoreTypes.num.ref(ctx),
                forceAllowDynamic: false,
              )
          ? switch (methodName) {
              'remainder' => [numericArgumentContext(ctx, L.type, bound)],
              'clamp' => [
                numericClampArgumentContext(ctx, L.type, bound),
                numericClampArgumentContext(ctx, L.type, bound),
              ],
              _ => const <TypeRef?>[],
            }
          : const <TypeRef?>[];
      argsPair = ArgumentBinder(ctx).bindBridgeTarget(
        target,
        e.argumentList,
        positionalContexts: numericContexts,
        typeArguments: e.typeArguments,
        returnContext: bound,
      );
      // Static calls on generic bridge classes (e.g. `Stream.fromIterable`)
      // infer the class's own type parameters — `T` in `Iterable<T>` — from
      // the argument types, which then resolve `returns:` annotations.
      _inferBridgeTypeParameters(
        ctx,
        fd,
        argsPair.positional,
        bridgeTypeParameters,
        inferableNames: receiverTypeParameters.keys.toSet(),
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
      mReturnType =
          argsPair.declaredReturn ??
          resolveCallResultType(
            ctx,
            signature: resultSignature,
            targetType: isStatic ? staticType : L.type,
            argTypes: argsPair.positional.map((a) => a.type).toList(),
            namedArgTypes: argsPair.namedValues.map(
              (k, v) => MapEntry(k, v.type),
            ),
          );
      if (!isStatic &&
          methodName == 'then' &&
          ownerType.isSpec(CoreTypes.future) &&
          argsPair.positional.isNotEmpty) {
        // The bridge `then` signature declares a raw `Future` return and a
        // raw `Function` callback — recover `Future<S>` from the callback's
        // return type `R` as `Future<flatten(R)>` (onValue returns
        // `FutureOr<S>`).
        final callback = argsPair.positional.first.type;
        final returnType = switch (callback) {
          FunctionTypeRef(:final signature) => signature.returnType,
          _ => null,
        };
        if (returnType != null) {
          var flattened = ctx.typeSystem.flatten(returnType);
          if (flattened.isSpec(CoreTypes.dynamic) && bound != null) {
            // The callback's `FutureOr<S>` surface degrades to `dynamic`
            // (no union types) — recover `S` from the assignment context.
            final viewed = ctx.typeSystem.asInstanceOf(
              bound,
              ctx.types.bySpec(CoreTypes.future),
            );
            if (viewed != null && interfaceArgumentsOf(viewed).isNotEmpty) {
              flattened = interfaceArgumentsOf(viewed).first;
            }
          }
          mReturnType = ctx.types.bySpec(CoreTypes.future).instantiate([
            flattened,
          ]);
        }
      }
      if (isStatic &&
          br is BridgeConstructorDef &&
          staticType is InterfaceTypeRef &&
          bridgeTypeParameters.isNotEmpty) {
        mReturnType = staticType.copyWith(
          arguments: [
            for (final name in receiverTypeParameters.keys)
              bridgeTypeParameters[name] ??
                  (receiverTypeParameters[name] as TypeParameterTypeRef)
                      .parameter
                      .bound ??
                  CoreTypes.dynamic.ref(ctx),
          ],
        );
      }
    } else if (L.type.isSpec(CoreTypes.dynamic) ||
        L.type is TypeParameterTypeRef &&
            extensionLookupType(ctx, L.type).isSpec(CoreTypes.dynamic)) {
      target = DynamicCall(
        receiver: L.copyIntoFreshSlot(ctx, 'dynamic_receiver'),
        name: methodName,
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
      final specialized = _specializeDynamicCall(
        target as DynamicCall,
        argsPair,
        e,
      );
      if (specialized != null) {
        // Binding supplied operands above preserves dynamic argument contexts.
        // The specialization only supplies the concrete callee's defaults.
        (target, argsPair) = specialized;
        mReturnType = CoreTypes.dynamic.ref(ctx);
      }
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
                  methodName,
                ),
                member: sourceMember,
              )
            : e.target is SuperExpression
            ? Devirtualizer(ctx).refineSuper(
                VirtualCall(
                  receiver: L,
                  name: methodName,
                  member: sourceMember,
                  signature: resolved.signatureOverride,
                ),
              )
            : Devirtualizer(ctx).refine(
                VirtualCall(
                  receiver: L,
                  name: methodName,
                  member: sourceMember,
                  signature: resolved.signatureOverride,
                ),
              );
        if (e.target is SuperExpression && target is VirtualCall) {
          throw CompileError(
            'Cannot resolve a direct target for super.$methodName',
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
        var instantiatedType = staticType!;
        // A context fills unresolved class arguments; it must not replace
        // concrete arguments supplied through an alias such as T = C<List<int>>.
        if (bound != null &&
            e.typeArguments == null &&
            staticType is InterfaceTypeRef &&
            (staticType.arguments.isEmpty ||
                staticType.arguments.any((arg) => arg.hasInferenceVariables))) {
          final owner = nominalDeclOf(staticType);
          final inferred = constructorContextArguments(ctx, staticType, bound);
          if (inferred.isNotEmpty) {
            instantiatedType = staticType.copyWith(
              arguments: [
                for (final parameter in owner!.typeParameters)
                  inferred[parameter] ?? TypeParameterTypeRef(parameter),
              ],
            );
          }
        }
        target = ConstructorCall(
          staticType: staticType,
          instantiatedType: interfaceArgumentsOf(instantiatedType).isEmpty
              ? null
              : instantiatedType,
          name: ctorNameOf(methodName),
          offset: DeferredOrOffset.lookupStatic(
            ctx,
            staticType.file,
            staticType.name,
            ctorNameOf(methodName),
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
        mReturnType = argsPair.returnType;
      } else {
        if (!isStatic) throw StateError('Instance call has no resolved target');
        target = StaticCall(
          DeferredOrOffset.lookupStatic(
            ctx,
            staticType!.file,
            staticType.name,
            ctorNameOf(methodName),
          ),
          member: sourceMember,
        );
        argsPair = ArgumentBinder(ctx).bindDeclaration(
          sourceMember.library,
          declaration,
          e.argumentList,
          typeArguments: e.typeArguments,
          source: e,
          returnContext: bound,
        );
      }
      mReturnType ??= argsPair.declaredReturn;
    }

    final numericReturn = resolvedMember is BridgeMember && !isStatic
        ? switch (methodName) {
            'remainder' when argsPair.positional.length == 1 =>
              numericArithmeticResultType(
                ctx,
                L.type,
                argsPair.positional.single.type,
              ),
            'clamp' when argsPair.positional.length == 2 =>
              numericClampResultType(
                ctx,
                L.type,
                argsPair.positional[0].type,
                argsPair.positional[1].type,
              ),
            _ => null,
          }
        : null;
    final returnType =
        numericReturn ??
        mReturnType ??
        memberCallResultType(
          ctx,
          isStatic ? staticType! : L.type,
          ctorNameOf(methodName),
          [for (final arg in argsPair.positional) arg.type],
          {for (final (name, arg) in argsPair.named) name: arg.type},
          $static: isStatic,
          source: e,
          resolved: resolved,
        ) ??
        CoreTypes.dynamic.ref(ctx);
    final explicitTypeArguments = runtimeTypeArguments(ctx, e);
    return (
      target,
      BoundCall(
        receiver: isStatic ? null : L,
        positional: argsPair.positional,
        named: argsPair.named,
        runtimeTypeArguments: explicitTypeArguments.isNotEmpty
            ? explicitTypeArguments
            : argsPair.runtimeTypeArguments,
        returnType: returnType,
        vectorOverride: isStatic || resolvedMember is BridgeMember
            ? argsPair.vector()
            : null,
      ),
    );
  }

  /// Specialize proven allocations after evaluating dynamic operands unchanged.
  (StaticCall, BoundCall)? _specializeDynamicCall(
    DynamicCall target,
    BoundCall supplied,
    MethodInvocation invocation,
  ) {
    final exact = target.receiver.exactType;
    final owner = exact == null ? null : nominalDeclOf(exact);
    if (exact == null ||
        exact.nullable ||
        owner is! SourceTypeDecl ||
        owner.typeParameters.isNotEmpty ||
        invocation.typeArguments != null) {
      return null;
    }
    final name = ctx.memberNameOf(target.name, MemberKind.method);
    final implementation = ctx.memberLookup.implementationOwner(exact, name);
    final member = implementation == null
        ? null
        : ctx.memberLookup.concreteMemberOn(implementation, name);
    if (member is! SourceMember ||
        member.sourceDeclaration is! MethodDeclaration ||
        (member.sourceDeclaration as MethodDeclaration).isGetter ||
        member.declaringDecl?.typeParameters.isNotEmpty == true) {
      return null;
    }
    final refined = Devirtualizer(ctx).refine(
      VirtualCall(
        receiver: target.receiver.withType(exact),
        name: target.name,
        member: member,
        signature: member.signature,
      ),
    );
    if (refined is! StaticCall) return null;
    final signature = refined.signature!;
    if (signature.typeParameters.isNotEmpty ||
        supplied.positional.length > signature.positional.length ||
        signature.positional
            .skip(supplied.positional.length)
            .any((parameter) => parameter.isRequired) ||
        signature.named.any(
          (parameter) =>
              parameter.isRequired &&
              !supplied.named.any((entry) => entry.$1 == parameter.name),
        )) {
      return null;
    }
    bool accepts(Variable argument, ParameterSpec parameter) =>
        !parameter.erased &&
        !parameter.type.isFunctionLike &&
        argument.type.assignmentConversionTo(ctx, parameter.type) ==
            AssignmentConversion.none;
    for (var i = 0; i < supplied.positional.length; i++) {
      if (!accepts(supplied.positional[i], signature.positional[i])) {
        return null;
      }
    }
    for (final (name, argument) in supplied.named) {
      final parameter = signature.named.firstWhereOrNull((p) => p.name == name);
      if (parameter == null || !accepts(argument, parameter)) return null;
    }
    return (
      refined,
      ArgumentBinder(ctx).bindSourceValues(
        refined,
        supplied.positional,
        supplied.namedValues,
        source: invocation,
      ),
    );
  }

  /// Bind an enum constant invocation through its ordinary instance `call`.
  Variable _invokeEnumConstant(
    Variable value,
    MethodInvocation invocation,
    TypeRef? context,
  ) {
    final resolved = ctx.memberLookup.interfaceMember(
      value.type,
      MemberName.method('call'),
      source: invocation,
    );
    final (target, arguments) = _bindMethod(
      value,
      invocation,
      resolved: resolved,
      isStatic: false,
      staticType: null,
      bound: context,
      invokedName: 'call',
    );
    return target.emit(ctx, arguments);
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
    // The bound signature is the interface member's — seed its owner's
    // parameters from the receiver's view alongside the implementation
    // owner's parameters from the declaring link.
    return {
      ...resolved.ownerTypeArguments,
      ...ownerTypeArgumentsOf(owner, viewedAs),
    };
  }

  bool _needsNullableOperatorExtension(TypeRef receiver, String operator) =>
      !receiver.isSpec(CoreTypes.dynamic) &&
      _nonNullReceiverOperators.contains(operator) &&
      extensionLookupType(ctx, receiver).nullable;

  /// Operand context, with inherited and extension type arguments substituted.
  TypeRef? operatorParameterType(
    TypeRef receiver,
    String operator,
    int index, {
    AstNode? source,
    BoundExtension? extensionPin,
  }) {
    if (extensionPin != null) {
      final member = extensionMember(extensionPin.ext, operator);
      final parameter = member?.parameters?.parameters.elementAtOrNull(index);
      return parameter == null
          ? null
          : ctx.typeFactory.formalParameterAnnotationType(
              extensionPin.ext.library,
              parameter,
              typeParameters: extBindingsMap(
                extensionPin.ext,
                extensionPin.onBindings,
              ),
            );
    }
    if (!_needsNullableOperatorExtension(receiver, operator)) {
      try {
        return ctx.memberLookup
            .interfaceMember(
              receiver,
              MemberName.method(operator),
              source: source,
            )
            .signature
            .positional
            .elementAtOrNull(index)
            ?.type;
      } on CompileError {
        // An extension operator may apply instead.
      }
    }
    final found = resolveExtensionMember(
      ctx,
      receiver,
      operator,
      arity: operator == '[]=' ? 2 : 1,
    );
    if (found == null) return null;
    final (ext, member, bindings) = found;
    final parameter = member.parameters?.parameters.elementAtOrNull(index);
    if (parameter == null) return null;
    return ctx.typeFactory.formalParameterAnnotationType(
      ext.library,
      parameter,
      typeParameters: extBindingsMap(ext, bindings),
    );
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
    bool lexicalSuper = false,
  }) {
    if (method == null) {
      return invokeFunctionValue(receiver, args, namedArgs);
    }
    final nullableOperator = _needsNullableOperatorExtension(
      receiver.type,
      method,
    );
    final numericResult =
        (namedArgs == null || namedArgs.isEmpty) &&
            contextualNumericOperators.contains(method) &&
            args.length == 1
        ? numericArithmeticResultType(ctx, receiver.type, args.single.type)
        : null;
    final arithmetic = contextualNumericOperators.contains(method);
    final hasNeverOperand =
        arithmetic &&
        [receiver, ...args].any(
          (value) => value.type.isSpec(CoreTypes.never) && !value.type.nullable,
        );
    if ((namedArgs == null || namedArgs.isEmpty) &&
        extensionPin == null &&
        !hasNeverOperand &&
        !nullableOperator) {
      Variable primitiveView(Variable value) {
        if (!arithmetic) return value;
        final primitive = numericPrimitiveOperandType(ctx, value.type);
        if (primitive == null || sameDeclaration(value.type, primitive)) {
          return value;
        }
        // The subtype proof chooses an unbox bank; the source binding keeps
        // its nominal type and representation for later reads.
        return Variable.of(
          ctx,
          value.ssa,
          primitive,
          rep: value.rep,
          facts: value.facts,
        );
      }

      final intrinsic = Intrinsics(ctx).tryEmit(
        primitiveView(receiver),
        method,
        args.map(primitiveView).toList(),
      );
      if (intrinsic != null) {
        return numericResult == null
            ? intrinsic
            : (
                target: intrinsic.target,
                result: intrinsic.result.copyWith(type: numericResult),
                args: intrinsic.args,
                namedArgs: intrinsic.namedArgs,
              );
      }
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
      if (nullableOperator ||
          !ctx.memberLookup.hasInstanceMember(
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
    if (nullableOperator) {
      throw CompileError('Cannot invoke operator $method on ${receiver.type}');
    }
    return _invokeResolvedOperator(
      recv,
      method,
      args,
      namedArgs,
      returnType: numericResult,
      lexicalSuper: lexicalSuper,
    );
  }

  /// Bind and emit evaluated operands; callers with a resolved member retain it.
  OperatorResult _invokeResolvedOperator(
    Variable receiver,
    String method,
    List<Variable> args,
    Map<String, Variable>? namedArgs, {
    ResolvedMember? resolved,
    TypeRef? returnType,
    bool lexicalSuper = false,
  }) {
    var recv = receiver;
    final values = [...args];
    final equality = (method == '==' || method == '!=') && values.length == 1;
    final negateSuperEquality = equality && lexicalSuper && method == '!=';
    final boxed = Variable.boxUnboxMultiple(ctx, [recv, ...values], true);
    recv = boxed.first;
    final prepared = boxed.sublist(1);
    if (equality && !lexicalSuper) {
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
    // Lexical super equality calls the superclass operator without virtual
    // dispatch. Dart defines != as the negation of that same == operator.
    if (equality) method = '==';
    final argTypes = prepared.map((arg) => arg.type).toList();
    final namedArgTypes =
        namedArgs?.map((key, arg) => MapEntry(key, arg.type)) ?? {};
    // The '.call' member on a bare Function-typed receiver can't resolve an
    // instance method; the callee's own signature carries the result type.
    final isBareCall = recv.type.isFunctionLike && method == 'call';
    if (!isBareCall &&
        !recv.type.isSpec(CoreTypes.dynamic) &&
        resolved == null) {
      try {
        resolved = ctx.memberLookup.interfaceMember(
          recv.type,
          ctx.memberNameOf(method, MemberKind.method),
        );
      } on CompileError {
        // Unresolvable operator targets retain the dynamic fallback.
      }
    }
    if (_nonNullReceiverOperators.contains(method) &&
        resolved?.member is BridgeMember) {
      final parameters = resolved!.signature.positional;
      for (var i = 0; i < prepared.length && i < parameters.length; i++) {
        final argument = prepared[i].type;
        final parameter = parameters[i].type;
        if (argument.assignmentConversionTo(ctx, parameter) ==
            AssignmentConversion.invalid) {
          throw CompileError(
            'Cannot assign operator argument of type $argument to $parameter',
          );
        }
      }
    }
    returnType ??=
        (isBareCall
            ? callResultType(
                ctx,
                callee: recv,
                dispatch: null,
                argTypes: argTypes,
                namedArgTypes: namedArgTypes,
              )
            : memberCallResultType(
                ctx,
                recv.type,
                method,
                argTypes,
                namedArgTypes,
                resolved: resolved,
              )) ??
        CoreTypes.dynamic.ref(ctx);
    var boundCall = BoundCall(
      receiver: recv,
      positional: prepared,
      named: [
        for (final entry in (namedArgs ?? const <String, Variable>{}).entries)
          (entry.key, entry.value.boxIfNeeded(ctx)),
      ],
      returnType: returnType,
    );
    final virtual = VirtualCall(
      receiver: recv,
      name: method,
      member: resolved?.member,
    );
    final target = lexicalSuper
        ? Devirtualizer(ctx).refineSuper(virtual)
        : Devirtualizer(ctx).refine(virtual);
    if (resolved?.member case SourceMember sourceMember
        when sourceMember.sourceDeclaration is MethodDeclaration) {
      final seedGenerics = _sourceTargetTypeArguments(target, resolved!);
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
    var result = target.emit(ctx, boundCall);
    if (negateSuperEquality) {
      result = Variable.ssa(
        ctx,
        LogicalNot(ctx.svar('super_not_equal'), result.unboxIfNeeded(ctx).ssa),
        CoreTypes.bool.ref(ctx),
        rep: ValueRep.bool,
      );
    }
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

  /// `forEach` on a natively-held collection: an index pump that invokes
  /// the closure in place of a per-element bridge round-trip. Mutation
  /// during iteration follows index semantics, not the iterable's
  /// concurrent-modification check.
  Variable? _tryCompileNativeForEach(
    Variable receiver,
    List<Variable> args,
    ResolvedMember? resolved,
  ) {
    if (args.length != 1) return null;
    final collectionRep = unboxedRepOf(receiver.type);
    final isMap = collectionRep == ValueRep.nativeMap;
    final isSet = collectionRep == ValueRep.nativeSet;
    if (!isMap && !isSet && collectionRep != ValueRep.nativeList) {
      return null;
    }
    final function = args.single;
    if (receiver.boxed) {
      // A boxed value promoted to a collection type can still be an
      // evaluated-class implementation — VM-check the storage once and
      // fall back to the bridged member for non-natives.
      macroBranch(
        ctx,
        null,
        condition: (ctx) => Variable.ssa(
          ctx,
          isMap
              ? IsNativeMap(ctx.svar('is_native'), receiver.ssa)
              : isSet
              ? IsNativeSet(ctx.svar('is_native'), receiver.ssa)
              : IsNativeList(ctx.svar('is_native'), receiver.ssa),
          CoreTypes.bool.ref(ctx),
          rep: ValueRep.bool,
        ),
        thenBranch: (ctx, ert) =>
            _compileNativeForEachPump(ctx, receiver, function, isMap, isSet),
        elseBranch: (ctx, ert) {
          _invokeResolvedOperator(
            receiver,
            'forEach',
            args,
            null,
            resolved: resolved,
          );
          return StatementInfo();
        },
      );
      return _forEachResult();
    }
    _compileNativeForEachPump(ctx, receiver, function, isMap, isSet);
    return _forEachResult();
  }

  Variable _forEachResult() => BuiltinValue()
      .push(ctx)
      .boxIfNeeded(ctx)
      .copyWith(type: CoreTypes.voidType.ref(ctx));

  /// The index-pump loop for [_tryCompileNativeForEach].
  StatementInfo _compileNativeForEachPump(
    CompilerContext ctx,
    Variable receiver,
    Variable function,
    bool isMap,
    bool isSet,
  ) {
    final intType = CoreTypes.int.ref(ctx);
    final elements = receiver.unboxIfNeeded(ctx);
    final list = isMap
        ? Variable.ssa(
            ctx,
            MapKeys(ctx.svar('for_each_keys'), elements.ssa),
            CoreTypes.list.ref(ctx),
          )
        : isSet
        ? Variable.ssa(
            ctx,
            SetToList(ctx.svar('for_each_set'), elements.ssa),
            receiver.type,
          )
        : elements;
    final length = Variable.ssa(
      ctx,
      ListLength(ctx.svar('for_each_length'), list.ssa),
      intType,
      rep: ValueRep.int,
    );
    late LocalBinding index;
    return macroLoop(
      ctx,
      null,
      initialization: (ctx) {
        index = ctx.setLocal(
          '#forEachIndex',
          BuiltinValue().push(ctx).copyWith(type: intType, rep: ValueRep.int),
          declaredType: intType,
        );
        index.write(
          ctx,
          Variable.ssa(
            ctx,
            LoadInt(ctx.svar('for_each_init'), 0),
            intType,
            rep: ValueRep.int,
          ),
        );
      },
      condition: (ctx) => Variable.ssa(
        ctx,
        IntLessThan(ctx.svar('for_each_cond'), index.read(ctx).ssa, length.ssa),
        CoreTypes.bool.ref(ctx),
        rep: ValueRep.bool,
      ),
      body: (ctx, ert) {
        final key = Variable.ssa(
          ctx,
          IndexList(
            ctx.svar('for_each_element'),
            list.ssa,
            index.read(ctx).ssa,
          ),
          CoreTypes.dynamic.ref(ctx),
          rep: ValueRep.boxed,
        );
        if (isMap) {
          final value = Variable.ssa(
            ctx,
            IndexMap(ctx.svar('for_each_value'), elements.ssa, key.ssa),
            CoreTypes.dynamic.ref(ctx),
            rep: ValueRep.boxed,
          );
          invokeFunctionValue(function, [key, value], null);
        } else {
          invokeFunctionValue(function, [key], null);
        }
        return StatementInfo();
      },
      update: (ctx) {
        index.write(
          ctx,
          Variable.ssa(
            ctx,
            Increment(ctx.svar('for_each_next'), index.read(ctx).ssa),
            intType,
            rep: ValueRep.int,
          ),
        );
      },
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
        bound: bound,
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
    TypeRef? bridgeConstructorType;
    final bridgeConstructorGenerics = <String, TypeRef>{};
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
          final names = bridge.type.generics.keys.toList();
          final explicit = e.typeArguments?.arguments;
          if (explicit != null && explicit.length != names.length) {
            throw CompileError(
              'Expected ${names.length} type arguments for ${e.methodName.name}',
              e,
            );
          }
          List<TypeRef>? inferred;
          if (explicit != null) {
            inferred = [
              for (final argument in explicit)
                TypeRef.fromAnnotation(ctx, ctx.library, argument),
            ];
          } else if (bound != null && names.isNotEmpty) {
            final declaration = nominalDeclOf(bridgeType);
            final view = declaration == null
                ? null
                : ctx.typeSystem.asInstanceOf(
                    declaration.thisType,
                    nominalDeclOf(bound),
                  );
            if (view != null) {
              final bindings = <TypeParameterDef, TypeRef>{};
              ctx.typeSystem.unify(view, bound, bindings);
              inferred = [
                for (var i = 0; i < declaration!.typeParameters.length; i++)
                  bindings[declaration.typeParameters[i]] ??
                      declaration.defaultTypeArguments[i],
              ];
            }
          }
          if (inferred != null) {
            bridgeConstructorType = (bridgeType as InterfaceTypeRef).copyWith(
              arguments: inferred,
            );
            for (var index = 0; index < names.length; index++) {
              bridgeConstructorGenerics[names[index]] = inferred[index];
            }
          }
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
        final extensionType = nominalDeclOf(type);
        if (extensionType is SourceTypeDecl &&
            extensionType.kind == TypeDeclKind.extensionType) {
          var instantiated = type;
          if (e.typeArguments != null) {
            instantiated = (type as InterfaceTypeRef).copyWith(
              arguments: [
                for (final argument in e.typeArguments!.arguments)
                  TypeRef.fromAnnotation(ctx, ctx.library, argument),
              ],
            );
          } else {
            final inferred = constructorContextArguments(ctx, type, bound);
            if (inferred.isNotEmpty) {
              instantiated = (type as InterfaceTypeRef).copyWith(
                arguments: [
                  for (final parameter in extensionType.typeParameters)
                    inferred[parameter] ?? TypeParameterTypeRef(parameter),
                ],
              );
            }
          }
          return constructExtensionType(
            ctx,
            extensionType,
            instantiated,
            '',
            e.argumentList,
            isConst: site.inConstContext,
            source: e,
          );
        }
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
              constrainInferredTypeArguments(ctx, bindings);
              resolved = resolved.substituteTypeParameters(
                Substitution.of(bindings),
              );
            }
          }
          aliasType = resolved;
          final targetBridge = ctx
              .topLevelDeclarationsMap[resolved.file]?[resolved.name]
              ?.bridge;
          if (targetBridge is BridgeClassDef) {
            bridgeDecl = targetBridge;
            sigReturn = resolved;
            bridgeConstructorType = resolved;
            final names = targetBridge.type.generics.keys.toList();
            final arguments = interfaceArgumentsOf(resolved);
            for (var i = 0; i < names.length && i < arguments.length; i++) {
              bridgeConstructorGenerics[names[i]] = arguments[i];
            }
            offset = DeferredOrOffset(
              file: resolved.file,
              name: '${resolved.name}.',
            );
            break;
          }
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
          // Call to an implicit default constructor. Downward inference
          // fills the class's arguments from the context, as for a declared
          // constructor (`A<num> a = A()` instantiates A<num>).
          mReturnType = type;
          var instantiatedType = instantiateConstructorType(ctx, e, type);
          if (bound != null && e.typeArguments == null) {
            final owner = nominalDeclOf(instantiatedType);
            final view = owner == null
                ? null
                : ctx.typeSystem.asInstanceOf(
                    owner.thisType,
                    nominalDeclOf(bound),
                  );
            if (view != null && owner!.typeParameters.isNotEmpty) {
              final inferred = <TypeParameterDef, TypeRef>{};
              ctx.typeSystem.unify(view, bound, inferred);
              final contextArgs = [
                for (var i = 0; i < owner.typeParameters.length; i++)
                  inferred[owner.typeParameters[i]] ??
                      owner.defaultTypeArguments[i],
              ];
              if (!contextArgs.any((t) => t.hasInferenceVariables)) {
                instantiatedType = (instantiatedType as InterfaceTypeRef)
                    .copyWith(arguments: contextArgs);
              }
            }
          }
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

    if (sourceDecl != null) {
      final weak = compileWeakTearOffReference(
        ctx,
        offset.file!,
        sourceDecl,
        e,
        bound: bound,
      );
      if (weak != null) return weak;
    }
    if (sourceDecl is FunctionDeclaration &&
        isExternalEffect(ctx, offset.file!, sourceDecl)) {
      final target = StaticCall(
        offset,
        sourceDeclaration: sourceDecl,
        signature: CallSignature.forDeclaration(ctx, offset.file!, sourceDecl),
      );
      analyzeExternalEffectArgument(ctx, () {
        ArgumentBinder(ctx).bindSourceTarget(
          target,
          e.argumentList,
          typeArguments: e.typeArguments,
          source: e,
        );
      });
      return BuiltinValue()
          .push(ctx)
          .copyWith(type: CoreTypes.voidType.ref(ctx));
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
        instantiatedType: bridgeConstructorType,
        externalIndex:
            ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.']!,
        classBridge: bridge,
        isConst: e.inConstantContext,
        bridgeFunction: function,
        signature: CallSignature.bridge(
          ctx,
          function,
          returnFallback: CoreTypes.dynamic.ref(ctx),
          typeParameters: bridgeConstructorGenerics,
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
      final argsPair = ArgumentBinder(ctx).bindBridgeTarget(
        callTarget,
        e.argumentList,
        typeArguments: callTarget is ConstructorCall ? null : e.typeArguments,
        returnContext: bound,
      );

      mReturnType = argsPair.declaredReturn;

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
            constrainInferredTypeArguments(ctx, bindings);
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
      positional: isConstructor ? args : const [],
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
  // A raw receiver supplies the class's default arguments to callbacks,
  // rather than leaving its declaration parameters in the method signature.
  final arguments = receiver is InterfaceTypeRef && receiver.arguments.isEmpty
      ? receiver.decl.defaultTypeArguments
      : interfaceArgumentsOf(receiver);
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
  CompilerContext ctx,
  BridgeFunctionDef function,
  List<Variable> arguments,
  Map<String, TypeRef> inferred, {
  Set<String> inferableNames = const {},
}) {
  void infer(BridgeTypeRef formal, TypeRef actual) {
    final spec = formal.spec;
    if (spec?.library == AsyncTypes.futureOr.library &&
        spec?.name == AsyncTypes.futureOr.name &&
        formal.typeArgs.isNotEmpty) {
      if (actual is InterfaceTypeRef && actual.isSpec(AsyncTypes.futureOr)) {
        final arguments = interfaceArgumentsOf(actual);
        if (arguments.isNotEmpty) {
          infer(formal.typeArgs.first.type, arguments.first);
        }
        return;
      }
      final future = ctx.typeSystem.asInstanceOf(
        actual,
        ctx.types.bySpec(CoreTypes.future),
      );
      infer(
        formal.typeArgs.first.type,
        future == null
            ? actual
            : interfaceArgumentsOf(future).firstOrNull ??
                  CoreTypes.dynamic.ref(ctx),
      );
      return;
    }
    final reference = formal.ref;
    if (reference != null &&
        (function.generics.containsKey(reference) ||
            inferableNames.contains(reference))) {
      final existing = inferred[reference];
      // A seeded call-site placeholder yields to the argument's binding —
      // it marks "to be inferred", not a committed solution.
      if (existing == null ||
          (existing is TypeParameterTypeRef &&
              existing.parameter.owner.kind ==
                  TypeParameterOwnerKind.callSite)) {
        inferred[reference] = actual;
      } else if (existing.hasSchemaHoles) {
        // Argument inference completes a partial context without replacing
        // its declared components with unrelated argument types.
        inferred[reference] = ctx.typeSystem.greatestLowerBound(
          existing,
          actual,
        );
      }
      return;
    }
    final genericFunction = formal.gft;
    final actualFunction = actual is FunctionTypeRef ? actual.signature : null;
    if (genericFunction != null && actualFunction != null) {
      infer(genericFunction.returns.type, actualFunction.returnType);
      return;
    }
    final formalArguments = formal.typeArgs;
    final actualView = formalArguments.isEmpty || spec == null
        ? actual
        : ctx.typeSystem.asInstanceOf(actual, ctx.types.bySpec(spec)) ?? actual;
    final actualArguments = interfaceArgumentsOf(actualView);
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
  inferred.updateAll((_, type) => ctx.typeSystem.closeSchemaHoles(type));
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
  return ctx.withDeferredWriteCaptures(() {
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
  });
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
  TypeRef? bound,
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
    returnContext: bound,
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
      returnType: result.declaredReturn ?? target.signature!.returnType,
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
  Variable receiver, {
  TypeRef? bound,
}) {
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
      final getterValue = GetTarget.readSuper(
        ctx,
        receiver,
        name,
        fieldType: () =>
            ctx.memberLookup.fieldType(receiver.type, name, source: e) ??
            CoreTypes.dynamic.ref(ctx),
      );
      return (
        receiver,
        CallResolver(ctx).invokeValue(
          CallSite(
            shape: CallShape.fromArgumentList(
              e.argumentList,
              e.typeArguments?.arguments,
            ),
            source: e,
            context: bound,
          ),
          callee: getterValue,
        ),
      );
    }
    final fallback = NoSuchMethodCall(name: name);
    final arguments = ArgumentBinder(ctx).bindSuppliedOnly(
      fallback,
      CallSite(
        shape: CallShape.fromArgumentList(
          e.argumentList,
          e.typeArguments?.arguments,
        ),
        source: e,
        context: bound,
      ),
      callee: null,
    );
    return (receiver, fallback.emit(ctx, arguments));
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
