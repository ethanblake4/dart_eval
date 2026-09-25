import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import '../type.dart';
import 'deferred.dart';
import 'targets.dart';

/// Turns a [VirtualCall] into a [StaticCall] when the receiver's chain pins
/// a unique implementation. A `super` link or an allocation-exact
/// receiver always devirtualizes (with `LoadSuper` hops when the callee
/// body uses `super`), and a merely-declared type devirtualizes only when
/// no descendant overrides the member and the body needs no owner link.
final class Devirtualizer {
  const Devirtualizer(this.ctx);

  final CompilerContext ctx;

  CallTarget refine(VirtualCall target) {
    final L = target.receiver;
    // A nullable receiver may be null — a direct call would skip the
    // runtime's null dispatch (e.g. interpolated toString on null).
    final linkType = switch ((target.isSuperReceiver, L.exactType)) {
      (true, _) => L.concreteTypes.first,
      (false, final exactType?) when !L.type.nullable => exactType,
      _ => null,
    };
    final name = target.name;
    var directOwner = linkType != null
        ? ctx.memberLookup.implementationOwner(
            linkType,
            MemberName(name, MemberKind.method),
          )
        : null;
    if (directOwner == null &&
        !target.isSuperReceiver &&
        L.exactType == null &&
        // A nullable receiver may be null — a direct call would skip the
        // runtime's null dispatch (e.g. interpolated toString on null).
        !L.type.nullable &&
        L.concreteTypes.length == 1) {
      // The receiver may hold a subclass: the fixed target must not be
      // overridden by any descendant of its static type.
      directOwner = ctx.memberLookup.directImplementationOwner(
        L.concreteTypes.first,
        MemberName(name, MemberKind.method),
      );
    }
    // A callee needs `this` bound to its declaring link only when its body
    // uses `super`; otherwise any link — including the dispatch root —
    // works, which also allows devirtualizing non-exact receivers.
    final needsLink =
        directOwner != null &&
        ctx.memberLookup.needsOwnerLink(
          directOwner,
          MemberName(name, MemberKind.method),
        );
    if (directOwner != null && (linkType != null || !needsLink)) {
      final member = ctx.memberLookup.concreteMemberOn(
        directOwner,
        MemberName.method(name),
      );
      if (member is! SourceMember) return target;
      return StaticCall(
        DeferredOrOffset(
          file: directOwner.file,
          className: directOwner.name,
          methodType: MemberKind.method,
          name: name,
        ),
        receiver: L,
        ownerLink: linkType != null && needsLink
            ? (linkType, directOwner)
            : null,
        typeEnvironmentReceiver: L,
        declaringLink: directOwner,
        member: member,
      );
    }
    return target;
  }
}
