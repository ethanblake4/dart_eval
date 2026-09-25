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

/// How a member read `o.name` lowers. [GetTarget.resolve] picks the target
/// from the receiver's static type, representations, and facts; [emit]
/// produces the ops. No argument binding — an accessor target stands alone.
sealed class GetTarget {
  const GetTarget();

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
        if (receiver.concreteTypes.isNotEmpty) {
          final concrete = receiver.concreteTypes[0];
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
    final exact = receiver.exactType;
    if (exact != null && !hasBridgeSuperclass(ctx, exact)) {
      // Storage for an inherited field lives on its declaring class's
      // link, reached from the receiver by LoadSuper hops.
      final slot = ctx.memberLookup.accessorSlot(
        exact,
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

/// A `String.length`, native-`List.length`, or `runtimeType` read.
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

  /// The member name — `length` or `runtimeType`.
  final String name;

  /// `length` on a `String` (vs a native `List`).
  final bool string;

  /// `runtimeType` on a statically known concrete type: (type id, whether
  /// the descriptor needs the type environment, the denoted type).
  final (int, bool, TypeRef)? constantType;

  /// `runtimeType` on an unknown runtime value.
  final bool loadRuntime;

  @override
  Variable emit(CompilerContext ctx) {
    final recv = unbox ? receiver.unboxIfNeeded(ctx, false) : receiver;
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
    return Variable.ssa(
      ctx,
      LoadPropertyStatic(ctx.svar(name), linkSsa, index, isLate: isLate),
      fieldType,
      rep: ValueRep.boxed,
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
    final fieldType = declaredFieldType ?? CoreTypes.dynamic.ref(ctx);
    final exact = object.exactType;
    if (exact != null && !hasBridgeSuperclass(ctx, exact)) {
      // Storage for an inherited field lives on its declaring class's
      // link, reached from the receiver by LoadSuper hops.
      final slot = ctx.memberLookup.accessorSlot(
        exact,
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
            fieldType: fieldType,
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
          fieldType: fieldType,
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
          fieldType: fieldType,
          name: name,
        );
      }
    }
    return DynamicSet(object, name, fieldType);
  }

  /// `this.name = v` where `name` is declared on the enclosing class —
  /// always dynamic dispatch on `#this`.
  static Variable writeDeclared(
    CompilerContext ctx,
    Variable object,
    String name,
    Variable value,
    TypeRef fieldType, {
    AstNode? source,
  }) => DynamicSet(object, name, fieldType).emit(ctx, value);

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
  String name,
) => convertForAssignment(
  ctx,
  value,
  fieldType,
  representation: MachineRepresentation.object,
  description:
      'Cannot assign value of type ${value.type} to field "$name" '
      'of type $fieldType',
);

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
    final val = _convertForMember(ctx, value, fieldType, name);
    final linkSsa = _throughSuperLinks(ctx, object.boxIfNeeded(ctx), hops).ssa;
    ctx.pushOp(
      SetPropertyStatic(linkSsa, index, val.ssa, isLateFinal: isLateFinal),
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
    final paramType = member.parameters?.parameters.firstOrNull?.type == null
        ? null
        : ctx.typeFactory.formalParameterAnnotationType(
            ext.library,
            member.parameters!.parameters.first,
            typeParameters: extBindingsMap(ext, bindings),
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
