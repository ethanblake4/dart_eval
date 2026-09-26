import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart'
    show MachineRepresentation;
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'deferred.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import '../member/call_signature.dart';
import '../member/member.dart';
import '../member/member_lookup.dart' show hasBridgeSuperclass;
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/string.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import '../values/abi.dart';
import '../variable/value_facts.dart';
import 'bound_call.dart';
import 'devirtualizer.dart';
import 'targets.dart';

Variable _throughSuperLinks(
  CompilerContext ctx,
  Variable receiver,
  List<TypeRef> hops,
) {
  var link = receiver;
  for (final parent in hops) {
    link = Variable.ssa(
      ctx,
      LoadSuper(ctx.svar('super'), link.ssa),
      parent,
      facts: ValueFacts(possibleClasses: [parent]),
    );
  }
  return link;
}

Variable _superOwner(
  CompilerContext ctx,
  Variable self,
  String name,
  MemberKind kind,
) {
  final target = ctx.memberLookup.superMemberTarget(
    self.type,
    name,
    kind: kind,
  );
  if (target.hops.isEmpty && target.owner != self.type) {
    return Variable.of(
      ctx,
      self.ssa,
      target.owner,
      rep: self.rep,
      facts: ValueFacts(possibleClasses: [target.owner]),
    );
  }
  var owner = self;
  for (final parent in target.hops) {
    owner = Variable.ssa(ctx, LoadSuper(ctx.svar('super'), owner.ssa), parent);
  }
  return owner;
}

TypeRef? extensionAccessorType(
  CompilerContext ctx,
  EvalExtension ext,
  MethodDeclaration member,
  List<TypeRef> bindings, {
  required bool forSet,
}) {
  final typeParameters = extBindingsMap(ext, bindings);
  if (forSet) {
    final parameter = member.parameters?.parameters.firstOrNull;
    if (parameter?.type == null) return null;
    return ctx.typeFactory.formalParameterAnnotationType(
      ext.library,
      parameter!,
      typeParameters: typeParameters,
    );
  }
  if (!member.isGetter && !member.isSetter) {
    // A method member read is a bound tear-off — its type is the method's
    // signature (own type parameters kept), not its return type.
    return ctx.typeFactory.declaredFunctionType(
      ext.library,
      member.parameters,
      member.returnType,
      member.typeParameters,
      memberTypeParameters: typeParameters,
      ownTypeParameterOwner: TypeParameterOwner(
        TypeParameterOwnerKind.tearOff,
        ext.library,
        '${ext.name}.${member.name.lexeme}',
        member.offset,
      ),
    );
  }
  return member.returnType == null
      ? null
      : TypeRef.fromAnnotation(
          ctx,
          ext.library,
          member.returnType!,
          typeParameters: typeParameters,
        );
}

/// How a member read `o.name` lowers. [GetTarget.resolve] picks the target
/// from the receiver's static type, representations, and facts; [emit]
/// produces the ops. No argument binding — an accessor target stands alone.
sealed class GetTarget {
  const GetTarget();

  static Variable readSuper(
    CompilerContext ctx,
    Variable self,
    String name, {
    required TypeRef Function() fieldType,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) {
    final foldedMethod = ctx.memberLookup.lexicalSuperBody(
      name,
      MemberKind.method,
    );
    if (foldedMethod != null) {
      final owner = foldedMethod.declaration.parent?.parent;
      if (owner is Declaration) {
        return materializeTearOff(
          ctx,
          DeferredOrOffset(
            offset: foldedMethod.offset,
            file: foldedMethod.library,
            className: declarationName(owner),
            name: name,
          ),
          implicitReceiver: ctx.lookupLocal('#this')!,
          boundContext: boundContext,
          typeArguments: typeArguments,
          memberTypeParameters: ctx.memberLookup.lexicalSuperTypeParameters(
            foldedMethod,
          ),
        );
      }
    }
    final foldedGetter = ctx.memberLookup.lexicalSuperBody(
      name,
      MemberKind.getter,
    );
    if (foldedGetter != null) {
      return FoldedMixinGetterCall(
        foldedGetter,
        ctx.lookupLocal('#this')!,
      ).emit(ctx);
    }
    final owner = _superOwner(ctx, self, name, MemberKind.getter);
    final member = ctx.types
        .find(owner.type.file, owner.type.name)
        ?.declaredMember(MemberName.method(name));
    if (member case SourceMember(
      node: MethodDeclaration(isGetter: false, isSetter: false),
    )) {
      return materializeTearOff(
        ctx,
        DeferredOrOffset(
          file: owner.type.file,
          className: owner.type.name,
          name: name,
        ),
        implicitReceiver: owner,
        boundContext: boundContext,
        typeArguments: typeArguments,
      );
    }
    if (ctx
            .topLevelDeclarationsMap[owner.type.file]?[owner.type.name]
            ?.isBridge ??
        false) {
      return DynamicGet(owner, name, fieldType: fieldType()).emit(ctx);
    }
    return SuperGetterCall(owner, name, fieldType()).emit(ctx);
  }

  /// Member-read resolution: intrinsics (`length`, `runtimeType`), bound
  /// extensions, extension getters and method tear-offs, link-relative
  /// field storage, direct getter calls, and the dynamic fallback.
  static GetTarget resolve(
    CompilerContext ctx,
    Variable receiver,
    String name, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
    BoundExtension? extensionPin,
  }) {
    if ((name == 'isEmpty' || name == 'isNotEmpty') &&
        receiver.type.isSpec(CoreTypes.string) &&
        !receiver.type.nullable &&
        extensionPin == null) {
      return IntrinsicGet(receiver, name, string: true, unbox: true);
    }
    if (name == 'length' && !receiver.type.nullable) {
      final isString = receiver.type.isAssignableTo(
        ctx,
        CoreTypes.string.ref(ctx),
        forceAllowDynamic: false,
      );
      // A declared List may be an evaluated class with an overridden
      // getter. Only a natively-held core List proves native storage.
      final isList =
          receiver.rep == ValueRep.nativeList &&
          receiver.type.isSpec(CoreTypes.list);
      if (isString || isList) {
        return IntrinsicGet(receiver, name, string: isString, unbox: true);
      }
    }
    final resolvedReceiver = ctx.typeSystem.throughTypeParameters(
      receiver.type,
    );
    if (name == 'runtimeType') {
      // `runtimeType` is overridable like any other getter — only
      // intrinsify it when the receiver's class doesn't declare it and no
      // descendant overrides it (otherwise dispatch normally).
      final declaredLocally =
          ctx
              .instanceDeclarationPositions[resolvedReceiver
                  .file]?[resolvedReceiver.name]?[MemberKind.getter]
              ?.containsKey('runtimeType') ??
          false;
      final overridable =
          declaredLocally ||
          ctx.memberLookup.implementationOwner(
                resolvedReceiver,
                MemberName.getter('runtimeType'),
              ) !=
              null ||
          ctx.memberOverriddenInSubclass(
            resolvedReceiver.file,
            resolvedReceiver.name,
            'runtimeType',
          );
      if (!overridable) {
        // A concrete type is the runtime type only when the receiver can't
        // be a subclass instance — a link shares the root's type.
        final concrete = receiver.concreteTypes.isNotEmpty
            ? receiver.concreteTypes[0]
            : null;
        if (concrete != null &&
            !ctx.hasSubclasses(concrete.file, concrete.name)) {
          return IntrinsicGet(
            receiver,
            name,
            constantType: (
              ctx.runtimeTypes.idOf(concrete),
              concrete.requiresTypeEnvironment,
              concrete,
            ),
          );
        }
        return IntrinsicGet(receiver, name, loadRuntime: true);
      }
    }
    // Explicit application `E(x)` pins member resolution to E's members.
    if (extensionPin case final bound?) {
      final getter = extensionMember(bound.ext, name, getter: true);
      if (getter != null) {
        return ExtensionGetterCall(
          receiver,
          bound.ext,
          getter,
          bound.onBindings,
        );
      }
      final member = extensionMember(bound.ext, name);
      if (member == null) {
        throw CompileError(
          'Extension ${bound.ext.name} has no member $name',
          source,
        );
      }
      return ExtensionMethodTearOff(
        receiver,
        bound.ext,
        member,
        boundContext: boundContext,
        typeArguments: typeArguments,
      );
    }
    final resolved = resolvedReceiver.isSpec(CoreTypes.dynamic)
        ? null
        : ctx.memberLookup.tryInterfaceMember(
                resolvedReceiver,
                MemberName(name, MemberKind.getter),
                source: source,
              ) ??
              ctx.memberLookup.tryInterfaceMember(
                resolvedReceiver,
                MemberName(name, MemberKind.setter),
                source: source,
              );
    final resolvedField =
        resolved?.fieldType ??
        // Structural reads (record `$n`/named slots) live outside the
        // member hierarchy — `fieldType` answers them.
        ctx.memberLookup.fieldType(resolvedReceiver, name, source: source);
    // The member is a tear-off/write target only when the read produced
    // no field type — a method member found here means a bound tear-off,
    // while a member that yields a type is read as a field.
    final resolvedNode = resolved?.member;
    final methodNode = resolvedNode is SourceMember ? resolvedNode.node : null;
    final isMethod =
        methodNode is MethodDeclaration &&
            !methodNode.isGetter &&
            !methodNode.isSetter ||
        resolvedNode is BridgeMember &&
            resolvedNode.def is BridgeMethodDef &&
            resolvedNode.name.kind == MemberKind.method;
    final member = isMethod || resolvedField == null ? resolved : null;
    if (resolvedField == null &&
        member == null &&
        !resolvedReceiver.isSpec(CoreTypes.dynamic)) {
      // `call` on a function-typed receiver is the function itself — the
      // implicit invoke member needs no declared member.
      if (name == 'call' && resolvedReceiver.isFunctionLike) {
        return ReceiverGet(receiver);
      }
      // An extension getter may apply.
      final found = resolveExtensionMember(
        ctx,
        resolvedReceiver,
        name,
        getter: true,
      );
      if (found != null) {
        return ExtensionGetterCall(receiver, found.$1, found.$2, found.$3);
      }
      // An extension method read produces a bound tear-off.
      final foundMethod = resolveExtensionMember(ctx, resolvedReceiver, name);
      if (foundMethod != null) {
        return ExtensionMethodTearOff(
          receiver,
          foundMethod.$1,
          foundMethod.$2,
          boundContext: boundContext,
          typeArguments: typeArguments,
        );
      }
      throw CompileError(
        'Member "$name" is not defined for type $resolvedReceiver',
        source,
      );
    }
    final memberNode = member?.member;
    final method = memberNode is SourceMember
        ? memberNode.sourceDeclaration
        : null;
    final bridge = memberNode is BridgeMember ? memberNode.def : null;
    final isDeclaredMethod =
        method is MethodDeclaration && !method.isGetter && !method.isSetter;
    final isBridgeMethod = bridge is BridgeMethodDef;

    // A method member read produces a tear-off; carry its signature so
    // calls through the result stay typed.
    final TypeRef fieldType;
    final CallSignature? methodSignature;
    if (isDeclaredMethod) {
      methodSignature = member!.signature;
      fieldType = methodSignature.toFunctionType(ctx);
      if (boundContext is FunctionTypeRef &&
          methodSignature.typeParameters.isNotEmpty) {
        final target = Devirtualizer(ctx).refine(
          VirtualCall(receiver: receiver, name: name, member: member.member),
        );
        if (target is StaticCall) {
          return ContextualMethodTearOff(target, boundContext, typeArguments);
        }
      }
    } else if (isBridgeMethod) {
      fieldType = CoreTypes.function.ref(ctx);
      methodSignature = member?.signature;
    } else {
      fieldType = resolvedField ?? CoreTypes.dynamic.ref(ctx);
      methodSignature = null;
    }
    final exact = receiver.exactType ?? declaredLeafClass(ctx, receiver.type);
    // A provably-class receiver can reach member storage directly. An
    // exact receiver is never a subclass instance; a concreteTypes
    // receiver may be, so the slot is only valid when no descendant
    // redeclares the member.
    final directType =
        exact ??
        (receiver.concreteTypes.length == 1 &&
                !ctx.memberOverriddenInSubclass(
                  receiver.concreteTypes.first.file,
                  receiver.concreteTypes.first.name,
                  name,
                )
            ? receiver.concreteTypes.first
            : null);
    if (directType != null) {
      // Storage for an inherited field lives on its declaring class's
      // link, reached from the receiver by LoadSuper hops. The slot walk
      // only matches guest members — bridged ancestors never appear in
      // `instanceGetterIndices`, so a native member simply falls through.
      final slot = ctx.memberLookup.accessorSlot(
        directType,
        name,
        MemberKind.getter,
      );
      if (slot != null) {
        final (link, fieldIndex, linkHops) = slot;
        // Field members resolve to their [VariableDeclaration]; real
        // accessors resolve to [MethodDeclaration]. Field storage is
        // link-relative so it always needs the declaring link; a real
        // accessor needs it only when its body uses `super`.
        final resolvedDecl = ctx.memberLookup.tryInterfaceMember(
          link,
          MemberName(name, MemberKind.getter),
        );
        final member = resolvedDecl?.member;
        final decl = member is SourceMember ? member.sourceDeclaration : null;
        final fieldDecl = decl is VariableDeclaration
            ? decl.parent?.parent
            : null;
        final needsLink =
            fieldIndex != null ||
            ctx.memberLookup.needsOwnerLink(
              link,
              MemberName(name, MemberKind.getter),
            );
        final hops = needsLink ? linkHops : const <TypeRef>[];
        if (fieldIndex != null) {
          final isLate =
              fieldDecl is FieldDeclaration && fieldDecl.fields.isLate;
          return FieldSlotGet(
            receiver,
            name,
            hops: hops,
            index: fieldIndex,
            isLate: isLate,
            fieldType: fieldType,
          );
        }
        final forward = _trivialGetterForward(ctx, link, decl);
        if (forward != null) {
          return _TrivialGetterCall(
            receiver,
            hops: hops,
            chain: forward,
            fieldType: fieldType,
          );
        }
        return DirectGetterCall(
          receiver,
          hops: hops,
          file: link.file,
          className: link.name,
          nameKey: ctx.memberLookup
              .linkName(MemberName(name, MemberKind.method), link)
              .nameKey,
          fieldType: fieldType,
        );
      }
    }
    if (exact == null &&
        receiver.concreteTypes.length == 1 &&
        !hasBridgeSuperclass(ctx, receiver.concreteTypes.first)) {
      // The receiver may hold a subclass: a getter can be called directly
      // on the dispatch root only when it isn't overridden and its body
      // never touches `super` (so any link works as `this`).
      final owner = ctx.memberLookup.directImplementationOwner(
        receiver.concreteTypes.first,
        MemberName(name, MemberKind.getter),
      );
      if (owner != null &&
          !ctx.memberLookup.needsOwnerLink(
            owner,
            MemberName(name, MemberKind.getter),
          )) {
        final ownerMember = ctx.memberLookup.tryInterfaceMember(
          owner,
          MemberName(name, MemberKind.getter),
        );
        final forward = _trivialGetterForward(
          ctx,
          owner,
          ownerMember?.member is SourceMember
              ? (ownerMember!.member as SourceMember).sourceDeclaration
              : null,
        );
        if (forward != null) {
          return _TrivialGetterCall(
            receiver,
            hops: const [],
            chain: forward,
            fieldType: fieldType,
          );
        }
        final key = name.startsWith('_')
            ? '${ctx.libraryUri(owner.file)}::$name'
            : name;
        return DirectGetterCall(
          receiver,
          hops: const [],
          file: owner.file,
          className: owner.name,
          nameKey: key,
          fieldType: fieldType,
        );
      }
    }
    return DynamicGet(
      receiver,
      name,
      fieldType: fieldType,
      methodSignature: methodSignature,
    );
  }

  /// [resolve] + [emit].
  static Variable read(
    CompilerContext ctx,
    Variable receiver,
    String name, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
    BoundExtension? extensionPin,
  }) => resolve(
    ctx,
    receiver,
    name,
    source: source,
    boundContext: boundContext,
    typeArguments: typeArguments,
    extensionPin: extensionPin,
  ).emit(ctx);

  Variable emit(CompilerContext ctx);
}

/// A native `String`/`List` getter or `runtimeType` read.
final class IntrinsicGet extends GetTarget {
  const IntrinsicGet(
    this.receiver,
    this.name, {
    this.string = false,
    this.constantType,
    this.loadRuntime = false,
    this.unbox = false,
  });

  /// The receiver — unboxed during emission when [unbox] is set.
  final Variable receiver;

  /// Whether [emit] unboxes the receiver first (native `length` reads).
  final bool unbox;

  /// The intrinsic getter's name.
  final String name;

  /// A getter on `String` (vs native `List.length`).
  final bool string;

  /// `runtimeType` on a statically known concrete type: (type id, whether
  /// the descriptor needs the type environment, the denoted type).
  final (int, bool, TypeRef)? constantType;

  /// `runtimeType` on an unknown runtime value.
  final bool loadRuntime;

  @override
  Variable emit(CompilerContext ctx) {
    // Use the resolved receiver view: a null-aware selector may have narrowed
    // its type without changing the nullable local it came from.
    var recv = receiver;
    if (unbox) {
      recv = string && receiver.boxed
          ? receiver.toRep(
              ctx,
              ValueRep.string,
              into: ctx.svar('string_receiver'),
            )
          : receiver.unboxIfNeeded(ctx, false);
    }
    return switch (name) {
      'length' => Variable.ssa(
        ctx,
        string
            ? StringOperation(
                ctx.svar('string_length'),
                StringOperator.length,
                recv.ssa,
              )
            : ListLength(ctx.svar('list_length'), recv.ssa),
        CoreTypes.int.ref(ctx),
        rep: ValueRep.int,
      ),
      'isEmpty' || 'isNotEmpty' => Variable.ssa(
        ctx,
        StringOperation(
          ctx.svar('string_empty'),
          name == 'isEmpty'
              ? StringOperator.isEmpty
              : StringOperator.isNotEmpty,
          recv.ssa,
        ),
        CoreTypes.bool.ref(ctx),
        rep: ValueRep.bool,
      ),
      _ when constantType != null => Variable.ssa(
        ctx,
        constantType!.$2
            ? LoadTypeParameter(ctx.svar('var_type'), constantType!.$1)
            : LoadConstantType(ctx.svar('var_type'), constantType!.$1),
        CoreTypes.type.ref(ctx),
        facts: ValueFacts(denotedType: constantType!.$3),
      ),
      _ => Variable.ssa(
        ctx,
        LoadRuntimeType(ctx.svar('runtime_type'), recv.ssa),
        CoreTypes.type.ref(ctx),
        facts: switch (recv.exactType) {
          final exact? => ValueFacts(denotedType: exact),
          null => null,
        },
      ),
    };
  }
}

/// A field-slot read on a link reached by LoadSuper hops.
final class FieldSlotGet extends GetTarget {
  const FieldSlotGet(
    this.receiver,
    this.name, {
    required this.hops,
    required this.index,
    required this.isLate,
    required this.fieldType,
  });

  /// The receiver the hop chain starts from; boxed during emission.
  final Variable receiver;
  final String name;

  /// The links to hop through (each hop's *target* parent type), empty
  /// when the field lives on the receiver's own link.
  final List<TypeRef> hops;

  final int index;
  final bool isLate;
  final TypeRef fieldType;

  @override
  Variable emit(CompilerContext ctx) {
    final linkSsa = _throughSuperLinks(
      ctx,
      receiver.boxIfNeeded(ctx),
      hops,
    ).ssa;
    final rep = isLate ? MachineRepresentation.object : _loadSlotRep(fieldType);
    return Variable.ssa(
      ctx,
      LoadPropertyStatic(
        ctx.svar(name),
        linkSsa,
        index,
        isLate: isLate,
        rep: rep,
      ),
      fieldType,
      rep: repForType(fieldType, rep),
    );
  }
}

/// A getter invoked directly against a known declaring link.
final class DirectGetterCall extends GetTarget {
  const DirectGetterCall(
    this.receiver, {
    required this.hops,
    required this.file,
    required this.className,
    required this.nameKey,
    required this.fieldType,
  });

  /// The receiver the hop chain starts from; boxed during emission and
  /// reused as the type-environment receiver.
  final Variable receiver;

  /// The links to hop through before the call.
  final List<TypeRef> hops;

  final int file;
  final String className;
  final String nameKey;
  final TypeRef fieldType;

  @override
  Variable emit(CompilerContext ctx) {
    final boxed = receiver.boxIfNeeded(ctx);
    final linkSsa = _throughSuperLinks(ctx, boxed, hops).ssa;
    return Variable.ssa(
      ctx,
      Call(
        DeferredOrOffset(
          file: file,
          className: className,
          methodType: MemberKind.getter,
          name: nameKey,
        ),
        [linkSsa],
        result: ctx.svar(nameKey),
        typeEnvironmentReceiver: boxed.ssa,
      ),
      fieldType,
      rep: ValueRep.boxed,
    );
  }
}

/// The member chain a trivial `=>`-bodied getter forwards to — e.g.
/// `int get len => s.length` yields `['s', 'length']` — when the chain's
/// first element resolves to an instance member on [link]. A `=>` body is
/// a single expression, so the head name can only bind a member (never a
/// local); the rest of the chain resolves normally on each read's type.
List<String>? _trivialGetterForward(
  CompilerContext ctx,
  TypeRef link,
  Declaration? decl,
) {
  if (decl is! MethodDeclaration ||
      !decl.isGetter ||
      decl.body is! ExpressionFunctionBody) {
    return null;
  }
  final chain = <String>[];
  Expression? expr = (decl.body as ExpressionFunctionBody).expression;
  while (true) {
    switch (expr) {
      case PrefixedIdentifier(:final prefix, :final identifier):
        chain.insert(0, identifier.name);
        expr = prefix;
        continue;
      case PropertyAccess(:final target, :final propertyName):
        if (expr.isNullAware) return null;
        chain.insert(0, propertyName.name);
        expr = target;
        continue;
      case SimpleIdentifier(:final name):
        chain.insert(0, name);
      case SuperExpression():
        // `super.m` is not a member read on the receiver — it binds the
        // impl above the declaring class. Forwarding it as `receiver.m`
        // would dispatch from the root.
        return null;
      case ThisExpression():
      default:
        break;
    }
    break;
  }
  if (chain.isEmpty) return null;
  final head = ctx.memberLookup.tryInterfaceMember(
    link,
    MemberName(chain.first, MemberKind.getter),
  );
  final headMember = head?.member;
  if (headMember == null ||
      (headMember is SourceMember && headMember.isStatic)) {
    return null;
  }
  return chain;
}

/// A trivial getter inlined as the member chain it forwards to:
/// `=> s.length` emits `receiver.s.length` through the normal read path.
final class _TrivialGetterCall extends GetTarget {
  const _TrivialGetterCall(
    this.receiver, {
    required this.hops,
    required this.chain,
    required this.fieldType,
  });

  final Variable receiver;
  final List<TypeRef> hops;
  final List<String> chain;
  final TypeRef fieldType;

  @override
  Variable emit(CompilerContext ctx) {
    var value = _throughSuperLinks(ctx, receiver.boxIfNeeded(ctx), hops);
    for (final name in chain) {
      value = GetTarget.read(ctx, value, name);
    }
    return value.copyWith(type: fieldType);
  }
}

/// `super.name` — a getter call on the owner link reached by the
/// denotation's mixin/superclass walk (no type-environment receiver).
final class SuperGetterCall extends GetTarget {
  const SuperGetterCall(this.owner, this.name, this.fieldType);

  final Variable owner;
  final String name;
  final TypeRef fieldType;

  @override
  Variable emit(CompilerContext ctx) => Variable.ssa(
    ctx,
    Call(
      DeferredOrOffset(
        file: owner.type.file,
        className: owner.type.name,
        name: name,
        methodType: MemberKind.getter,
      ),
      [owner.ssa],
      result: ctx.svar(name),
    ),
    fieldType,
    rep: ValueRep.boxed,
  );
}

/// A getter in an earlier folded mixin layer. Its current dispatch-table
/// entry may have been replaced by a later mixin, so call its exact body.
final class FoldedMixinGetterCall extends GetTarget {
  const FoldedMixinGetterCall(this.body, this.self);

  final FoldedMemberBody body;
  final Variable self;

  @override
  Variable emit(CompilerContext ctx) =>
      StaticCall(
        DeferredOrOffset(offset: body.offset),
        member: ctx.memberLookup.lexicalSuperMember(body),
        receiver: self,
        typeEnvironmentReceiver: self,
      ).emit(
        ctx,
        BoundCall(
          positional: const [],
          named: const [],
          returnType: ctx.memberLookup.lexicalSuperResultType(body),
        ),
      );
}

/// `InvokeExternal`-backed extension getter.
final class ExtensionGetterCall extends GetTarget {
  const ExtensionGetterCall(
    this.receiver,
    this.ext,
    this.member,
    this.bindings,
  );

  final Variable receiver;
  final EvalExtension ext;
  final MethodDeclaration member;
  final List<TypeRef> bindings;

  @override
  Variable emit(CompilerContext ctx) =>
      invokeExtensionGetter(ctx, receiver, ext, member, bindings);
}

/// Materializes an extension method as a closure capturing its receiver.
final class ExtensionMethodTearOff extends GetTarget {
  const ExtensionMethodTearOff(
    this.receiver,
    this.ext,
    this.member, {
    this.boundContext,
    this.typeArguments,
  });

  final Variable receiver;
  final EvalExtension ext;
  final MethodDeclaration member;
  final TypeRef? boundContext;
  final List<TypeRef>? typeArguments;

  @override
  Variable emit(CompilerContext ctx) {
    return materializeTearOff(
      ctx,
      DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
      implicitReceiver: receiver,
      boundContext: boundContext,
      typeArguments: typeArguments,
    );
  }
}

/// A source method whose receiver pins its implementation can be specialized
/// before its closure is created, preserving the bound callable type arguments.
final class ContextualMethodTearOff extends GetTarget {
  const ContextualMethodTearOff(
    this.target,
    this.boundContext,
    this.typeArguments,
  );

  final StaticCall target;
  final FunctionTypeRef boundContext;
  final List<TypeRef>? typeArguments;

  @override
  Variable emit(CompilerContext ctx) {
    final receiver = target.receiver!;
    final link = target.ownerLink;
    final captured = link == null
        ? receiver
        : Variable.of(
            ctx,
            ownerLinkSsa(ctx, receiver.ssa, link.$1, link.$2),
            link.$2,
            rep: receiver.rep,
          );
    return materializeTearOff(
      ctx,
      target.offset!,
      implicitReceiver: captured,
      boundContext: boundContext,
      typeArguments: typeArguments,
    );
  }
}

/// `f.call` on a function-typed receiver — the function itself.
final class ReceiverGet extends GetTarget {
  const ReceiverGet(this.receiver);

  final Variable receiver;

  @override
  Variable emit(CompilerContext ctx) => receiver;
}

/// The dynamic member read — `LoadPropertyDynamic`.
final class DynamicGet extends GetTarget {
  const DynamicGet(
    this.receiver,
    this.name, {
    required this.fieldType,
    this.methodSignature,
  });

  /// The receiver; boxed during emission.
  final Variable receiver;
  final String name;
  final TypeRef fieldType;

  /// The signature a method read carries so calls through the result stay
  /// typed.
  final CallSignature? methodSignature;

  @override
  Variable emit(CompilerContext ctx) => Variable.ssa(
    ctx,
    LoadPropertyDynamic(
      ctx.svar(name),
      receiver.boxIfNeeded(ctx).ssa,
      name,
      callerLibrary: ctx.library,
    ),
    fieldType,
    rep: ValueRep.boxed,
    facts: ValueFacts(callableSignature: methodSignature),
  );
}

/// How a member write `o.name = v` lowers. [SetTarget.resolve] picks the
/// target; [emit] converts the value for the member's type and produces
/// the ops, returning the stored variable.
sealed class SetTarget {
  const SetTarget();

  static Variable writeSuper(
    CompilerContext ctx,
    Variable self,
    String name,
    Variable value, {
    required TypeRef Function() fieldType,
  }) {
    final foldedSetter = ctx.memberLookup.lexicalSuperBody(
      name,
      MemberKind.setter,
    );
    if (foldedSetter != null) {
      return FoldedMixinSetterCall(
        foldedSetter,
        ctx.lookupLocal('#this')!,
      ).emit(ctx, value);
    }
    final owner = _superOwner(ctx, self, name, MemberKind.setter);
    if (ctx
            .topLevelDeclarationsMap[owner.type.file]?[owner.type.name]
            ?.isBridge ??
        false) {
      return DynamicSet(owner, name, fieldType()).emit(ctx, value);
    }
    return SuperSetterCall(owner, name, fieldType()).emit(ctx, value);
  }

  /// Member-write resolution: extension setters, link-relative field
  /// storage, direct setter calls, and the dynamic fallback.
  static SetTarget resolve(
    CompilerContext ctx,
    Variable object,
    String name, {
    AstNode? source,
  }) {
    final declaredFieldType = ctx.memberLookup.fieldType(
      object.type,
      name,
      forSet: true,
      source: source,
    );
    if (declaredFieldType == null &&
        !hasInstanceMember(ctx, object.type, name, forSet: true)) {
      // No instance member by this name: an extension setter may apply
      // (`e.name = v` where `set name` lives in `extension on T`).
      final extSetter = resolveExtensionMember(
        ctx,
        object.type,
        name,
        setter: true,
      );
      if (extSetter != null) {
        final (ext, member, bindings) = extSetter;
        return ExtensionSetterCall(object, ext, member, bindings, name);
      }
    }
    // A dynamic receiver devirtualized below still writes through the
    // callee's contract: the write type comes from the resolved member's
    // declaring link, not `object.type` (dynamic queries yield null).
    TypeRef? writeTypeOf(TypeRef declaringType) =>
        declaredFieldType ??
        ctx.memberLookup.fieldType(
          declaringType,
          name,
          forSet: true,
          source: source,
        );
    final fieldType = declaredFieldType ?? CoreTypes.dynamic.ref(ctx);
    final exact = object.exactType ?? declaredLeafClass(ctx, object.type);
    final directType =
        exact ??
        (object.concreteTypes.length == 1 &&
                !ctx.memberOverriddenInSubclass(
                  object.concreteTypes.first.file,
                  object.concreteTypes.first.name,
                  name,
                )
            ? object.concreteTypes.first
            : null);
    if (directType != null) {
      // Storage for an inherited field lives on its declaring class's
      // link, reached from the receiver by LoadSuper hops. The slot walk
      // only matches guest members — bridged ancestors never appear in
      // `instanceGetterIndices`, so a native member simply falls through.
      final slot = ctx.memberLookup.accessorSlot(
        directType,
        name,
        MemberKind.setter,
      );
      if (slot != null) {
        final (link, fieldIndex, linkHops) = slot;
        final resolvedDecl =
            ctx.memberLookup.tryInterfaceMember(
              link,
              MemberName(name, MemberKind.setter),
            ) ??
            ctx.memberLookup.tryInterfaceMember(
              link,
              MemberName(name, MemberKind.getter),
            );
        final member = resolvedDecl?.member;
        final decl = member is SourceMember ? member.sourceDeclaration : null;
        // Field storage is link-relative so it always needs the declaring
        // link; a real setter needs it only when its body uses `super`.
        final fieldDecl = decl is VariableDeclaration
            ? decl.parent?.parent
            : null;
        final needsLink =
            fieldIndex != null ||
            ctx.memberLookup.needsOwnerLink(
              link,
              MemberName(name, MemberKind.setter),
            );
        final hops = needsLink ? linkHops : const <TypeRef>[];
        if (fieldIndex != null) {
          // A widened receiver view must still check the actual setter's
          // contract. Generic fields need its receiver type environment.
          if (member is SourceMember &&
                  (member.fieldType?.requiresTypeEnvironment ?? false) ||
              declaredFieldType != null &&
                  resolvedDecl?.fieldType != declaredFieldType) {
            return DynamicSet(object, name, fieldType);
          }
          final isLateFinal =
              fieldDecl is FieldDeclaration &&
              fieldDecl.fields.isLate &&
              fieldDecl.fields.variables.any(
                (v) => v.name.lexeme == name && (v.isFinal || v.isConst),
              );
          return FieldSlotSet(
            object,
            hops: hops,
            index: fieldIndex,
            isLateFinal: isLateFinal,
            fieldType: writeTypeOf(link) ?? fieldType,
            name: name,
          );
        }
        return DirectSetterCall(
          object,
          hops: hops,
          file: link.file,
          className: link.name,
          nameKey: ctx.memberLookup
              .linkName(MemberName(name, MemberKind.method), link)
              .nameKey,
          fieldType: writeTypeOf(link) ?? fieldType,
          name: name,
        );
      }
    }
    if (exact == null &&
        object.concreteTypes.length == 1 &&
        !hasBridgeSuperclass(ctx, object.concreteTypes.first)) {
      // The receiver may hold a subclass: a setter can be called directly
      // on the dispatch root only when it isn't overridden and its body
      // never touches `super` (so any link works as `this`).
      final owner = ctx.memberLookup.directImplementationOwner(
        object.concreteTypes.first,
        MemberName(name, MemberKind.setter),
      );
      if (owner != null &&
          !ctx.memberLookup.needsOwnerLink(
            owner,
            MemberName(name, MemberKind.setter),
          )) {
        final key = name.startsWith('_')
            ? '${ctx.libraryUri(owner.file)}::$name'
            : name;
        return DirectSetterCall(
          object,
          hops: const [],
          file: owner.file,
          className: owner.name,
          nameKey: key,
          fieldType: writeTypeOf(object.concreteTypes.first) ?? fieldType,
          name: name,
        );
      }
    }
    return DynamicSet(object, name, fieldType);
  }

  /// [resolve] + [emit].
  static Variable write(
    CompilerContext ctx,
    Variable object,
    String name,
    Variable value, {
    AstNode? source,
  }) => resolve(ctx, object, name, source: source).emit(ctx, value);

  Variable emit(CompilerContext ctx, Variable value);
}

/// The conversion a field-shaped set applies to the incoming value.
Variable _convertForMember(
  CompilerContext ctx,
  Variable value,
  TypeRef fieldType,
  String name, {
  MachineRepresentation representation = MachineRepresentation.object,
}) => convertForAssignment(
  ctx,
  value,
  fieldType,
  representation: representation,
  description:
      'Cannot assign value of type ${value.type} to field "$name" '
      'of type $fieldType',
);

/// The bank a field read can land in directly: scalars and strings unbox
/// in the load op, other types stay boxed.
MachineRepresentation _loadSlotRep(TypeRef fieldType) =>
    switch (unboxedRepOf(fieldType)) {
      ValueRep.int => MachineRepresentation.integer,
      ValueRep.double => MachineRepresentation.doublePrecision,
      ValueRep.bool => MachineRepresentation.boolean,
      ValueRep.string => MachineRepresentation.string,
      _ => MachineRepresentation.object,
    };

/// The bank a field write accepts directly. String stays boxed: it shares
/// the object bank with the receiver, so an unboxed store would need the
/// value and receiver in one register.
MachineRepresentation _storeSlotRep(TypeRef fieldType) =>
    switch (unboxedRepOf(fieldType)) {
      ValueRep.int => MachineRepresentation.integer,
      ValueRep.double => MachineRepresentation.doublePrecision,
      ValueRep.bool => MachineRepresentation.boolean,
      _ => MachineRepresentation.object,
    };

/// A field-slot write on a link reached by LoadSuper hops.
final class FieldSlotSet extends SetTarget {
  const FieldSlotSet(
    this.object, {
    required this.hops,
    required this.index,
    required this.isLateFinal,
    required this.fieldType,
    required this.name,
  });

  /// The receiver the hop chain starts from; boxed during emission.
  final Variable object;
  final List<TypeRef> hops;
  final int index;
  final bool isLateFinal;
  final TypeRef fieldType;
  final String name;

  @override
  Variable emit(CompilerContext ctx, Variable value) {
    final rep = isLateFinal
        ? MachineRepresentation.object
        : _storeSlotRep(fieldType);
    final val = _convertForMember(
      ctx,
      value,
      fieldType,
      name,
      representation: rep,
    );
    final linkSsa = _throughSuperLinks(ctx, object.boxIfNeeded(ctx), hops).ssa;
    ctx.pushOp(
      SetPropertyStatic(
        linkSsa,
        index,
        val.ssa,
        isLateFinal: isLateFinal,
        rep: rep,
      ),
    );
    return val;
  }
}

/// A setter invoked directly against a known declaring link.
final class DirectSetterCall extends SetTarget {
  const DirectSetterCall(
    this.object, {
    required this.hops,
    required this.file,
    required this.className,
    required this.nameKey,
    required this.fieldType,
    required this.name,
  });

  /// The receiver the hop chain starts from; boxed during emission and
  /// reused as the call's type-environment receiver.
  final Variable object;
  final List<TypeRef> hops;
  final int file;
  final String className;
  final String nameKey;
  final TypeRef fieldType;
  final String name;

  @override
  Variable emit(CompilerContext ctx, Variable value) {
    final val = _convertForMember(ctx, value, fieldType, name);
    final boxed = object.boxIfNeeded(ctx);
    final linkSsa = _throughSuperLinks(ctx, boxed, hops).ssa;
    ctx.pushOp(
      Call(
        DeferredOrOffset(
          file: file,
          className: className,
          methodType: MemberKind.setter,
          name: nameKey,
        ),
        [linkSsa, val.ssa],
        result: ctx.svar(name),
        typeEnvironmentReceiver: boxed.ssa,
      ),
    );
    return val;
  }
}

/// `super.name = v` — a setter call on the owner link.
final class SuperSetterCall extends SetTarget {
  const SuperSetterCall(this.owner, this.name, this.fieldType);

  final Variable owner;
  final String name;
  final TypeRef fieldType;

  @override
  Variable emit(CompilerContext ctx, Variable value) {
    final boxed = convertForAssignment(
      ctx,
      value,
      fieldType,
      representation: MachineRepresentation.object,
      description:
          'Cannot assign ${value.type} to super.$name of type $fieldType',
    );
    ctx.pushOp(
      Call(
        DeferredOrOffset(
          file: owner.type.file,
          className: owner.type.name,
          name: name,
          methodType: MemberKind.setter,
        ),
        [owner.ssa, boxed.ssa],
        result: ctx.svar('super_set'),
      ),
    );
    return boxed;
  }
}

/// A setter in an earlier folded mixin layer, called by its exact body.
final class FoldedMixinSetterCall extends SetTarget {
  const FoldedMixinSetterCall(this.body, this.self);

  final FoldedMemberBody body;
  final Variable self;

  @override
  Variable emit(CompilerContext ctx, Variable value) {
    final parameterType = ctx.memberLookup.lexicalSuperSetterType(body);
    final converted = convertForAssignment(
      ctx,
      value,
      parameterType,
      representation: MachineRepresentation.object,
      description:
          'Cannot assign ${value.type} to super.${body.declaration.name.lexeme} '
          'of type $parameterType',
    );
    StaticCall(
      DeferredOrOffset(offset: body.offset),
      member: ctx.memberLookup.lexicalSuperMember(body),
      receiver: self,
      typeEnvironmentReceiver: self,
    ).emit(
      ctx,
      BoundCall(
        positional: [converted],
        named: const [],
        returnType: CoreTypes.voidType.ref(ctx),
      ),
    );
    return converted;
  }
}

/// An extension setter — `E.set name(v)` invoked with the receiver first.
final class ExtensionSetterCall extends SetTarget {
  const ExtensionSetterCall(
    this.object,
    this.ext,
    this.member,
    this.bindings,
    this.name,
  );

  /// The receiver; boxed during emission.
  final Variable object;
  final EvalExtension ext;
  final MethodDeclaration member;
  final List<TypeRef> bindings;
  final String name;

  @override
  Variable emit(CompilerContext ctx, Variable value) {
    final paramType = extensionAccessorType(
      ctx,
      ext,
      member,
      bindings,
      forSet: true,
    );
    final arg = paramType == null
        ? value.boxIfNeeded(ctx)
        : convertForAssignment(
            ctx,
            value,
            paramType,
            representation: MachineRepresentation.object,
            description:
                'Cannot assign ${value.type} to setter '
                '${ext.name}.$name on ${object.type}',
          );
    ctx.pushOp(
      Call(
        DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
        [object.boxIfNeeded(ctx).ssa, arg.ssa],
        result: ctx.svar('setter_result'),
        typeArguments:
            extensionCallTypeArguments(ctx, ext, member, bindings, const {}) ??
            const [],
      ),
    );
    // The assignment's value is the value as converted for the setter's
    // parameter — e.g. an implicit `.call` tear-off.
    return arg;
  }
}

/// The dynamic member write — `SetPropertyDynamic`.
final class DynamicSet extends SetTarget {
  const DynamicSet(this.object, this.name, this.fieldType);

  /// The receiver; boxed during emission.
  final Variable object;
  final String name;
  final TypeRef fieldType;

  @override
  Variable emit(CompilerContext ctx, Variable value) {
    final val = _convertForMember(ctx, value, fieldType, name);
    ctx.pushOp(
      SetPropertyDynamic(
        object.boxIfNeeded(ctx).ssa,
        name,
        val.ssa,
        callerLibrary: ctx.library,
      ),
    );
    return val;
  }
}
