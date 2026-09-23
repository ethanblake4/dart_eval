import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'deferred.dart';
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
    // A nullable receiver may be null — a direct call would skip the
    // runtime's null dispatch (e.g. interpolated toString on null).
    final linkType = switch ((target.isSuperReceiver, L.exactType)) {
      (true, _) => L.concreteTypes.first,
      (false, final exactType?) when !L.type.nullable => exactType,
      _ => null,
    };
    final name = target.name;
    var directOwner = linkType != null
        ? ctx.memberLookup.implementationOwner(linkType, MemberName(name, MemberKind.method))
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
      directOwner = ctx.memberLookup.directImplementationOwner(L.concreteTypes.first, MemberName(name, MemberKind.method));
    }
    // A callee needs `this` bound to its declaring link only when its body
    // uses `super`; otherwise any link — including the dispatch root —
    // works, which also allows devirtualizing non-exact receivers.
    final needsLink =
        directOwner != null && ctx.memberLookup.needsOwnerLink(directOwner, MemberName(name, MemberKind.method));
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
        declaringLink: directOwner,
      );
    }
    return target;
  }
}

/// The SSA of [receiver]'s inheritance-chain link owned by [owner], emitting
/// a LoadSuper hop per level. [from] is the receiver's static type and
/// [owner] a link found on its chain (e.g. via
/// [MemberLookup.implementationOwner]). Method and accessor bodies take
/// `this` as the declaring class's link — the same binding
/// [TypedDispatch.resolve] performs — so direct calls must hand them that
/// link rather than the dispatch root.
SSA ownerLinkSsa(
  CompilerContext ctx,
  SSA receiver,
  TypeRef from,
  TypeRef owner,
) {
  final links = [from, ...ctx.typeSystem.superclassChain(from)];
  var ssa = receiver;
  for (var i = 0; i < links.length; i++) {
    final link = links[i];
    if (link.file == owner.file && link.name == owner.name) return ssa;
    if (i + 1 >= links.length) return receiver; // owner isn't on the chain
    final parent = links[i + 1];
    ssa = Variable.ssa(
      ctx,
      LoadSuper(ctx.svar('super'), ssa),
      parent,
      concreteTypes: [parent],
    ).ssa;
  }
  return ssa;
}
