import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'targets.dart';

/// Turns a [VirtualCall] into a [StaticCall] when the receiver's chain pins
/// a unique implementation — the direct-call rules of the former
/// `invokeMethodWithTarget` tail: a `super` link or an allocation-exact
/// receiver always devirtualizes (with `LoadSuper` hops when the callee
/// body uses `super`), and a merely-declared type devirtualizes only when
/// no descendant overrides the member and the body needs no owner link.
final class Devirtualizer {
  const Devirtualizer(this.ctx);

  final CompilerContext ctx;

  CallTarget refine(VirtualCall target) {
    final L = target.receiver;
    final linkType = switch ((target.isSuperReceiver, L.exactType)) {
      (true, _) => L.concreteTypes.first,
      (false, final exactType?) => exactType,
      _ => null,
    };
    final name = target.name;
    var directOwner = linkType != null
        ? memberOwner(ctx, linkType, name)
        : null;
    if (directOwner == null &&
        !target.isSuperReceiver &&
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
        directOwner != null && memberNeedsOwnerLink(ctx, directOwner, name);
    if (directOwner != null && (linkType != null || !needsLink)) {
      return StaticCall(
        DeferredOrOffset(
          file: directOwner.file,
          className: directOwner.name,
          methodType: MemberKind.method,
          name: name,
        ),
        receiver: L,
        ownerLink: linkType != null && needsLink
            ? ownerLinkSsa(ctx, L.ssa, linkType, directOwner)
            : null,
        typeEnvironmentReceiver: L,
      );
    }
    return target;
  }
}
