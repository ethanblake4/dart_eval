// ignore_for_file: experimental_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileCascadeExpression(
  CascadeExpression e,
  CompilerContext ctx,
  TypeRef? bound,
) {
  // A cascade evaluates to its target, so the context type flows into it.
  final receiverValue = compileExpression(
    e.target,
    ctx,
    bound,
  ).boxIfNeeded(ctx);
  // The cascade target is an implicit temp — a detached view of the same
  // SSA value — so member promotions recorded inside sections survive a
  // write to the source local (`..f([c = C()])`).
  var target = Variable.of(
    ctx,
    receiverValue.ssa,
    receiverValue.type,
    rep: receiverValue.rep,
    facts: receiverValue.facts,
  );
  // The source binding's epoch before the sections ran — a write inside
  // the cascade keeps the temp's promotions from flowing back to `c`.
  final sourceBinding = receiverValue.binding;
  final sourceEpoch = sourceBinding?.current.writeEpoch;

  // The cascade evaluates to its target. Sections may attach
  // member-promotion facts to the target variable, so the value handed
  // back is the variable the sections actually saw.
  Variable result = target;

  /// Copies the temp's member promotions back onto the source local's
  /// binding when it could not have been reassigned — `c.._f!` leaves
  /// `c._f` promoted, but `c = ...` inside the sections or a write
  /// capture makes the temp's facts unsound for `c`.
  void transferMemberFacts() {
    final members = result.facts.promotedMembers;
    if (sourceBinding == null ||
        sourceBinding.writeCaptured ||
        sourceBinding.current.writeEpoch != sourceEpoch ||
        members == null) {
      return;
    }
    sourceBinding.rebind(
      sourceBinding.current.withFacts(
        sourceBinding.current.facts.copyWith(promotedMembers: members),
      ),
    );
  }

  void compileSections(Variable cascadeTarget) {
    // Cascaded selectors (`..x` anywhere inside a section) read the target
    // from the ambient context. Nested cascades save/restore it.
    final previousCascadeTarget = ctx.cascadeTarget;
    ctx.cascadeTarget = cascadeTarget;
    try {
      for (final s in e.cascadeSections) {
        if (s is MethodInvocation) {
          compileMethodInvocation(ctx, s);
        } else {
          compileExpressionAndDiscardResult(s, ctx);
        }
      }
      result = ctx.cascadeTarget ?? cascadeTarget;
    } finally {
      ctx.cascadeTarget = previousCascadeTarget;
    }
  }

  if (e.isNullAware) {
    // `target?..section` — a null target skips every section.
    macroBranch(
      ctx,
      null,
      elseEdgeUnreachable: () =>
          ctx.soundFlowAnalysis(e) && !target.type.hasNullableRepresentation,
      condition: (ctx) => compileNonNullCondition(ctx, target),
      thenBranch: (ctx, _) {
        // Inside `?..` the target is non-null: sections read members off
        // the narrowed view, and member promotions of an ephemeral target
        // ride on that variable.
        promoteNonNull(ctx, e.target);
        compileSections(target.withType(target.type.withNullable(false)));
        transferMemberFacts();
        return StatementInfo();
      },
      source: e,
    );
  } else {
    compileSections(target);
    transferMemberFacts();
  }
  // `o?..sections` still evaluates to `o` when `o` is null — the result
  // keeps the target's declared type even if sections narrowed it.
  if (e.isNullAware &&
      (!ctx.soundFlowAnalysis(e) || target.type.hasNullableRepresentation)) {
    result = result.withFacts(target.facts);
  }
  return result.withType(target.type);
}
