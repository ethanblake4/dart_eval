import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import '../member/member_lookup.dart' show hasBridgeSuperclass;
import '../type.dart';
import 'deferred.dart';
import 'targets.dart';

/// A non-generic source class with no descendants has an exact runtime layout.
/// Generic classes are excluded because a covariant instantiation can narrow
/// member contracts even without introducing a subclass.
TypeRef? declaredLeafClass(CompilerContext ctx, TypeRef type) {
  final declaration = nominalDeclOf(type);
  if (type.nullable ||
      declaration is! SourceTypeDecl ||
      declaration.typeParameters.isNotEmpty ||
      ctx.hasSubclasses(type.file, type.name) ||
      hasBridgeSuperclass(ctx, type)) {
    return null;
  }
  return type;
}

/// Turns a [VirtualCall] into a [StaticCall] when the receiver's chain pins
/// a unique implementation. A `super` link or an allocation-exact
/// receiver always devirtualizes (with `LoadSuper` hops when the callee
/// body uses `super`), and a merely-declared type devirtualizes only when
/// no descendant overrides the member and the body needs no owner link.
final class Devirtualizer {
  const Devirtualizer(this.ctx);

  final CompilerContext ctx;

  CallTarget refine(VirtualCall target) => _refine(target, lexicalSuper: false);

  CallTarget refineSuper(VirtualCall target) =>
      _refine(target, lexicalSuper: true);

  CallTarget _refine(VirtualCall target, {required bool lexicalSuper}) {
    final L = target.receiver;
    final exact = L.exactType ?? declaredLeafClass(ctx, L.type);
    // A nullable receiver may be null — a direct call would skip the
    // runtime's null dispatch (e.g. interpolated toString on null).
    final linkType = switch ((lexicalSuper, exact)) {
      (true, _) => L.type,
      (false, final exactType?) when !L.type.nullable => exactType,
      _ => null,
    };
    final name = target.name;
    // The member key as written in the current library — a private member
    // folded in from another library registers under `uri::_name`.
    final memberName = ctx.memberNameOf(name, MemberKind.method);
    var directOwner =
        lexicalSuper &&
            ctx.memberLookup.concreteMemberOn(L.type, memberName)
                is SourceMember
        ? L.type
        : linkType != null
        ? ctx.memberLookup.implementationOwner(linkType, memberName)
        : null;
    if (directOwner == null &&
        !lexicalSuper &&
        exact == null &&
        // A nullable receiver may be null — a direct call would skip the
        // runtime's null dispatch (e.g. interpolated toString on null).
        !L.type.nullable &&
        L.concreteTypes.length == 1) {
      // The receiver may hold a subclass: the fixed target must not be
      // overridden by any descendant of its static type.
      directOwner = ctx.memberLookup.directImplementationOwner(
        L.concreteTypes.first,
        memberName,
      );
    }
    // A callee needs `this` bound to its declaring link only when its body
    // uses `super`; otherwise any link — including the dispatch root —
    // works, which also allows devirtualizing non-exact receivers.
    final needsLink =
        directOwner != null &&
        ctx.memberLookup.needsOwnerLink(directOwner, memberName);
    if (directOwner != null && (linkType != null || !needsLink)) {
      final member = ctx.memberLookup.concreteMemberOn(directOwner, memberName);
      if (member is! SourceMember) return target;
      return StaticCall(
        DeferredOrOffset(
          file: directOwner.file,
          className: directOwner.name,
          methodType: MemberKind.method,
          name: memberName.nameKey,
        ),
        receiver: L,
        ownerLink: linkType != null && needsLink
            ? (linkType, directOwner)
            : null,
        typeEnvironmentReceiver: L,
        declaringLink: directOwner,
        member: member,
        // The interface signature binds the call — a devirtualized callee
        // may narrow bounds (e.g. `H extends List<int>` vs `List<T>`) that
        // only hold for the implementation's checked-stub, not statically.
        signature: target.signature,
      );
    }
    return target;
  }
}
