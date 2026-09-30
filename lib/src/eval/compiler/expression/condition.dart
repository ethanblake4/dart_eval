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
    final compiledValue = compileExpression(
      expression,
      ctx,
      CoreTypes.bool.ref(ctx),
    );
    ctx.typeInferenceSaveStates.removeLast();
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
    ctx.pushOp(JumpIfFalse(value.ssa, no.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, yes);
    ctx.builder.link(tail, no);
    ctx.restoreState(initialState);
    ctx.mergeBranchState([leafState]);
    // A statically-folded leaf still links both edges (the builder requires
    // them); the reachability flags tell the join to drop the dead arm's
    // flow state.
    // Before sound flow analysis, a type test's statically known result
    // still contributes both branches to the flow join. Keep the folded
    // runtime value without applying the newer reachability rule. Tests
    // against Never have always made the matching branch unreachable.
    final staticOutcome =
        expression is IsExpression &&
            !ctx.soundFlowAnalysis(expression) &&
            !TypeRef.fromAnnotation(
              ctx,
              ctx.library,
              expression.type,
            ).isSpec(CoreTypes.never)
        ? null
        : compiledValue.facts.constBool;
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
