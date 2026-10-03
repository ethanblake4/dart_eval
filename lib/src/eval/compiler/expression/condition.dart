import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

import 'expression.dart';
import '../helpers/assigned_locals.dart';

/// Compile a condition to its destinations without constructing a boolean join.
///
/// The returned record carries the [BasicBlockBuilder] for the `whenTrue` /
/// `whenFalse` entries plus each edge's static reachability — `false` means
/// the condition provably never routes there (a constant or a statically
/// folded type test), so a branch over it must not join that edge's flow
/// state even though the dead arm still compiles.
(BasicBlockBuilder, bool, bool) compileCondition(
  Expression expression,
  CompilerContext ctx,
  BasicBlock<Operation> whenTrue,
  BasicBlock<Operation> whenFalse,
) {
  final parent = ctx.builder;
  final initialState = ctx.saveState();
  recordConditionPromotions(ctx, expression, true);
  final assigned = assignedLocalNames([expression]);
  final assignedTrueTypes = <String, Set<TypeRef>>{};

  (bool, bool) emit(
    Expression expression,
    BasicBlock<Operation> yes,
    BasicBlock<Operation> no,
    List<(Expression, bool)> promotions, {
    bool reachable = true,
  }) {
    if (expression is ParenthesizedExpression) {
      return emit(
        expression.expression,
        yes,
        no,
        promotions,
        reachable: reachable,
      );
    }
    if (expression is PrefixExpression && expression.operator.lexeme == '!') {
      final (yesReachable, noReachable) = emit(
        expression.operand,
        no,
        yes,
        promotions,
        reachable: reachable,
      );
      return (noReachable, yesReachable);
    }
    if (expression is BinaryExpression &&
        (expression.operator.lexeme == '&&' ||
            expression.operator.lexeme == '||')) {
      final right = BasicBlock<Operation>(
        [],
        label: ctx.label('condition_rhs'),
      );
      final isAnd = expression.operator.lexeme == '&&';
      final (ly, ln) = isAnd
          ? emit(
              expression.leftOperand,
              right,
              no,
              promotions,
              reachable: reachable,
            )
          : emit(
              expression.leftOperand,
              yes,
              right,
              promotions,
              reachable: reachable,
            );
      ctx.builder = BasicBlockBuilder(ctx.activeGraph, [right], parent);
      final (ry, rn) = emit(expression.rightOperand, yes, no, [
        ...promotions,
        (expression.leftOperand, isAnd),
      ], reachable: reachable && (isAnd ? ly : ln));
      // `a && b` reaches yes only through the rhs; `no` sees either short-
      // circuit. `a || b` reaches no only through the rhs; yes sees either.
      return isAnd ? (ry, ln || rn) : (ly || ry, rn);
    }
    // Later operands can overwrite the value an earlier type test proved.
    for (var i = 0; i < promotions.length; i++) {
      final (condition, outcome) = promotions[i];
      applyConditionPromotions(
        ctx,
        condition,
        outcome,
        excluded: assignedLocalNames(
          promotions.skip(i + 1).map((edge) => edge.$1),
        ),
      );
    }
    // Individual tests may promote on only one short-circuit edge. Do not
    // leak their expression-local inference into the enclosing condition.
    // The bool context also resolves `.m()` shorthand in condition position.
    ctx.enterTypeInferenceContext();
    // A pattern guard's split point can follow an already throwing scrutinee.
    // Only termination caused by this condition removes its outcomes.
    final wasTerminated = ctx.flowTerminated;
    final compiledValue = compileExpression(
      expression,
      ctx,
      CoreTypes.bool.ref(ctx),
    );
    ctx.typeInferenceSaveStates.removeLast();
    if (compiledValue.type.isSpec(CoreTypes.never) ||
        !wasTerminated && ctx.flowTerminated) {
      ctx.flushBlock();
      return (false, false);
    }
    enforceConditionType(ctx, compiledValue, expression);
    final value = convertForAssignment(
      ctx,
      compiledValue,
      CoreTypes.bool.ref(ctx),
      representation: MachineRepresentation.boolean,
      source: expression,
      description: "Conditions must have a static type of 'bool'",
    );
    // Every exit sees the same local representations, including a path that
    // skips RHS assignments or calls. The SSA pass still joins their values.
    ctx.resolveBranchStateDiscontinuity(initialState);
    final leafState = ctx.saveState();
    // Before sound flow analysis, folded type tests still contribute both
    // flow edges. Never tests have always made one edge unreachable.
    final staticOutcome =
        expression is IsExpression &&
            !ctx.soundFlowAnalysis(expression) &&
            !TypeRef.fromAnnotation(ctx, ctx.library, expression.type).isBottom
        ? null
        : compiledValue.facts.constBool;
    for (final (destination, outcome) in [(yes, true), (no, false)]) {
      if (reachable &&
          identical(destination, whenTrue) &&
          staticOutcome != !outcome &&
          assigned.isNotEmpty) {
        // A write on this edge can establish a new promotion. The saved
        // enclosing condition predates the write, so retain its successful
        // edge type rather than restoring the old type in the body.
        applyConditionPromotions(ctx, expression, outcome);
        for (final name in assigned) {
          final binding = ctx.lookupBinding(name);
          if (binding != null) {
            assignedTrueTypes
                .putIfAbsent(name, () => <TypeRef>{})
                .add(binding.current.type);
          }
        }
        ctx.restoreState(leafState);
      }
    }
    ctx.pushOp(JumpIfFalse(value.ssa, no.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, yes);
    ctx.builder.link(tail, no);
    ctx.restoreState(initialState);
    ctx.mergeBranchState([leafState]);
    // A statically-folded leaf still links both edges (the builder requires
    // them); the reachability flags tell the join to drop the dead arm's
    // flow state.
    return (
      reachable && staticOutcome != false,
      reachable && staticOutcome != true,
    );
  }

  final (yesReachable, noReachable) = emit(
    expression,
    whenTrue,
    whenFalse,
    const [],
  );
  for (final entry in assignedTrueTypes.entries) {
    final binding = ctx.lookupBinding(entry.key);
    if (binding == null) continue;
    final saved =
        ctx.typeInferenceSaveStates.last.locals[binding.frameIndex][entry.key];
    saved?.promote(TypeRef.commonBaseType(ctx, entry.value));
  }
  return (
    BasicBlockBuilder(ctx.activeGraph, [whenTrue, whenFalse], parent),
    yesReachable,
    noReachable,
  );
}

/// Conditions must have a static type of `bool` or `dynamic`. A runtime
/// check is only permitted for `dynamic`; anything else (including
/// `bool?`) is a compile-time error.
void enforceConditionType(
  CompilerContext ctx,
  Variable value,
  AstNode? source,
) {
  final conversion = value.type.assignmentConversionTo(
    ctx,
    CoreTypes.bool.ref(ctx),
  );
  if (conversion == AssignmentConversion.invalid ||
      (conversion == AssignmentConversion.runtimeCheck &&
          !value.type.isSpec(CoreTypes.dynamic))) {
    throw CompileError("Conditions must have a static type of 'bool'", source);
  }
}
