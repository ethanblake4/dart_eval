import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

/// An `extension` declaration with the library it was declared in and the
/// name used to register its members (`E.foo`), synthesized when unnamed.
class EvalExtension {
  EvalExtension(this.library, this.declaration, this.name);

  final int library;
  final ExtensionDeclaration declaration;
  final String name;

  /// The members declared in the extension body.
  List<ClassMember> get members => switch (declaration.body) {
    BlockClassBody b => b.members,
    _ => const [],
  };

  /// Member registration key in `topLevelDeclarationPositions`.
  String memberKey(MethodDeclaration member) {
    final suffix = member.isGetter
        ? '*g'
        : member.isSetter
        ? '*s'
        : '';
    return '$name.${member.name.lexeme}$suffix';
  }

  /// The `on` type, or null when it can't be resolved (e.g. it depends on
  /// the extension's own type parameters, which aren't supported yet).
  TypeRef? resolveOnType(CompilerContext ctx) {
    if (declaration.typeParameters != null) return null;
    try {
      return TypeRef.fromAnnotation(
        ctx,
        library,
        declaration.onClause!.extendedType,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Finds the most specific extension member applicable to [receiverType]
/// named [memberName], or null when none apply. Ambiguity between equally
/// specific candidates reports the first — full specificity ordering is not
/// implemented.
(EvalExtension, MethodDeclaration)? resolveExtensionMember(
  CompilerContext ctx,
  TypeRef receiverType,
  String memberName, {
  bool getter = false,
  bool setter = false,
}) {
  EvalExtension? bestExt;
  MethodDeclaration? best;
  TypeRef? bestOnType;
  for (final ext in ctx.visibleExtensions[ctx.library] ?? const []) {
    final onType = ext.resolveOnType(ctx);
    if (onType == null) continue;
    if (!receiverType.isAssignableTo(ctx, onType)) continue;
    for (final member in ext.members) {
      if (member is! MethodDeclaration || member.isStatic) continue;
      if (member.name.lexeme != memberName) continue;
      if (member.isGetter != getter || member.isSetter != setter) continue;
      if (best == null || onType.isAssignableTo(ctx, bestOnType!)) {
        bestExt = ext;
        best = member;
        bestOnType = onType;
      }
    }
  }
  return best == null ? null : (bestExt!, best);
}

/// The extension declaring [member], or null.
EvalExtension? extensionOfMember(CompilerContext ctx, MethodDeclaration member) {
  for (final ext in ctx.extensions) {
    if (ext.members.contains(member)) return ext;
  }
  return null;
}

/// Emits a call to an extension getter: `E.name*g(receiver)` is a static
/// call whose only argument is the receiver.
Variable invokeExtensionGetter(
  CompilerContext ctx,
  Variable receiver,
  EvalExtension ext,
  MethodDeclaration member,
) {
  final s = ctx.svar('method_result');
  ctx.pushOp(
    Call(
      DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
      [receiver.boxIfNeeded(ctx).ssa],
      result: s,
    ),
  );
  final returnType =
      AlwaysReturnType.fromAnnotation(
        ctx,
        ext.library,
        member.returnType,
        CoreTypes.dynamic.ref(ctx),
      ).type ??
      CoreTypes.dynamic.ref(ctx);
  return Variable.of(ctx, s, returnType.copyWith(boxed: true));
}
