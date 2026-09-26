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
BasicBlockBuilder compileCondition(
  Expression expression,
  CompilerContext ctx,
  BasicBlock<Operation> whenTrue,
  BasicBlock<Operation> whenFalse,
) {
  final parent = ctx.builder;
  final initialState = ctx.saveState();
  recordConditionPromotions(ctx, expression, true);

  void emit(
    Expression expression,
    BasicBlock<Operation> yes,
    BasicBlock<Operation> no,
    List<(Expression, bool)> promotions,
  ) {
    if (expression is ParenthesizedExpression) {
      emit(expression.expression, yes, no, promotions);
      return;
    }
    if (expression is PrefixExpression && expression.operator.lexeme == '!') {
      emit(expression.operand, no, yes, promotions);
      return;
    }
    if (expression is BinaryExpression &&
        (expression.operator.lexeme == '&&' ||
            expression.operator.lexeme == '||')) {
      final right = BasicBlock<Operation>(
        [],
        label: ctx.label('condition_rhs'),
      );
      if (expression.operator.lexeme == '&&') {
        emit(expression.leftOperand, right, no, promotions);
      } else {
        emit(expression.leftOperand, yes, right, promotions);
      }
      ctx.builder = BasicBlockBuilder(ctx.activeGraph, [right], parent);
      emit(expression.rightOperand, yes, no, [
        ...promotions,
        (expression.leftOperand, expression.operator.lexeme == '&&'),
      ]);
      return;
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
  }

  emit(expression, whenTrue, whenFalse, const []);
  return BasicBlockBuilder(ctx.activeGraph, [whenTrue, whenFalse], parent);
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
