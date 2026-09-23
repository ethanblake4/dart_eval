import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:dart_eval/src/eval/bridge/declaration/class.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';

/// Compile-time only data describing how to perform a static-dispatch function call (e.g. when the exact function
/// to be called is known at compile time)
class StaticDispatch {
  const StaticDispatch(this.offset, this.returnType);

  final DeferredOrOffset offset;
  final ReturnType returnType;
}

/// A function ID or declaration reference resolved when the backend links calls.
class DeferredOrOffset {
  DeferredOrOffset({
    this.offset,
    this.file,
    this.name,
    this.className,
    this.methodType,
    this.targetName,
  }) : assert(offset != null || name != null);

  final int? offset;
  final int? file;
  final String? className;
  final int? methodType;
  final String? name;
  final String? targetName;

  factory DeferredOrOffset.lookupStatic(
    CompilerContext ctx,
    int library,
    String parent,
    String name,
  ) {
    if (ctx.topLevelDeclarationPositions[library]?.containsKey(
          '$parent.$name',
        ) ??
        false) {
      return DeferredOrOffset(
        file: library,
        offset: ctx.topLevelDeclarationPositions[library]!['$parent.$name'],
        name: '$parent.$name',
      );
    } else {
      return DeferredOrOffset(file: library, name: '$parent.$name');
    }
  }

  @override
  String toString() {
    return 'DeferredOrOffset{offset: $offset, file: $file, name: $name}';
  }

  @override
  bool operator ==(Object other) =>
      other is DeferredOrOffset &&
      other.offset == offset &&
      other.file == file &&
      other.className == className &&
      other.name == name;

  @override
  int get hashCode =>
      offset.hashCode ^ className.hashCode ^ file.hashCode ^ name.hashCode;
}

/// Whether any class in [type]'s superclass chain is bridged. Bridged
/// ancestors provide members natively, so resolving a call to an evaluated
/// class on the chain would skip the real (native) implementation.
bool hasBridgeSuperclass(CompilerContext ctx, TypeRef type) {
  for (final parent in ctx.typeSystem.superclassChain(type)) {
    final bridge =
        ctx.topLevelDeclarationsMap[parent.file]?[parent.name]?.bridge;
    if (bridge is BridgeClassDef && bridge.bridge) return true;
  }
  return false;
}

/// The class at-or-above [type] (in superclass order) that declares instance
/// member [member] of [kind] (0 = getter, 1 = setter, 2 = method) — i.e. the
/// implementation a call resolves to. Null when [member] is only reachable
/// through a bridged ancestor or isn't declared on the chain at all.
TypeRef? memberOwner(
  CompilerContext ctx,
  TypeRef type,
  String member, {
  int kind = 2,
}) {
  if (hasBridgeSuperclass(ctx, type)) {
    return null;
  }
  for (final link in [type, ...ctx.typeSystem.superclassChain(type)]) {
    final positions =
        ctx.instanceDeclarationPositions[link.file]?[link.name]?[kind] as Map?;
    if (positions != null &&
        (positions.containsKey(member) ||
            (member.startsWith('_') &&
                positions.containsKey(
                  '${ctx.libraryUri(link.file)}::$member',
                ))) &&
        concreteMemberDecl(ctx, link, member, kind: kind) != null) {
      return link;
    }
  }
  return null;
}

/// Like [memberOwner], but for a receiver statically typed [type] that may
/// hold a subclass instance: a fixed target exists only while no descendant
/// of [type] redeclares [member] (a subclassed class is fine as long as the
/// member isn't overridden).
TypeRef? directMemberOwner(
  CompilerContext ctx,
  TypeRef type,
  String member, {
  int kind = 2,
}) {
  if (ctx.memberOverriddenInSubclass(type.file, type.name, member)) {
    return null;
  }
  return memberOwner(ctx, type, member, kind: kind);
}

/// The SSA of [receiver]'s inheritance-chain link owned by [owner], emitting
/// a LoadSuper hop per level. [from] is the receiver's static type and
/// [owner] a link found on its chain (e.g. via [memberOwner]). Method and
/// accessor bodies take `this` as the declaring class's link — the same
/// binding [TypedDispatch.resolve] performs — so direct calls must hand them
/// that link rather than the dispatch root.
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

/// Whether calling [name] of [kind] (0 = getter, 1 = setter, 2 = method)
/// declared on [owner] requires `this` to be bound to the declaring link.
/// Bodies that never touch `super` only access members through the dispatch
/// root, so they run correctly on any link of the object — a synthesized
/// field accessor always needs its link since its index is link-relative.
bool memberNeedsOwnerLink(
  CompilerContext ctx,
  TypeRef owner,
  String name, {
  int kind = 2,
}) {
  final decl = concreteMemberDecl(ctx, owner, name, kind: kind);
  if (decl is! MethodDeclaration) return true;
  var usesSuper = false;
  decl.body.accept(_SuperSeeker(() => usesSuper = true));
  return usesSuper;
}

/// The `instanceDeclarationsMap` key for member [name] of [kind]
/// (0 = getter → `name*g`, 1 = setter → `name*s`, 2 = method → `name`).
String memberKey(String name, [int kind = 2]) => switch (kind) {
  0 => '$name*g',
  1 => '$name*s',
  _ => name,
};

/// The declaration of instance member [name] of [kind] (0 = getter,
/// 1 = setter, 2 = method) on [link]. Abstract declarations return null —
/// they register positions but have no body, so an abstract override is
/// skipped in dispatch and the implementation lives deeper in the chain.
Declaration? concreteMemberDecl(
  CompilerContext ctx,
  TypeRef link,
  String name, {
  int kind = 2,
}) {
  final decls = ctx.instanceDeclarationsMap[link.file]?[link.name];
  var decl = decls?[memberKey(name, kind)];
  if (decl == null && name.startsWith('_')) {
    decl = decls?[memberKey('${ctx.libraryUri(link.file)}::$name', kind)];
  }
  if (decl is MethodDeclaration && !decl.isComplete) return null;
  return decl;
}

class _SuperSeeker extends RecursiveAstVisitor<void> {
  _SuperSeeker(this.onSuper);
  final void Function() onSuper;

  @override
  void visitSuperExpression(SuperExpression node) => onSuper();
}
