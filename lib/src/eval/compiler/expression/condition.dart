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

/// Compile a condition to its destinations without constructing a boolean join.
BasicBlockBuilder compileCondition(
  Expression expression,
  CompilerContext ctx,
  BasicBlock<Operation> whenTrue,
  BasicBlock<Operation> whenFalse,
) {
  final parent = ctx.builder;
  final initialState = ctx.saveState();
  final lowerLogical = !_containsTypeTest(expression);
  recordConditionPromotions(ctx, expression, true);

  void emit(
    Expression expression,
    BasicBlock<Operation> yes,
    BasicBlock<Operation> no,
  ) {
    if (expression is ParenthesizedExpression) {
      emit(expression.expression, yes, no);
      return;
    }
    // Type-test promotion is managed by the expression compiler's nested
    // inference contexts. Keep that path until promotion itself is edge-aware.
    if (lowerLogical) {
      if (expression is PrefixExpression && expression.operator.lexeme == '!') {
        emit(expression.operand, no, yes);
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
          emit(expression.leftOperand, right, no);
        } else {
          emit(expression.leftOperand, yes, right);
        }
        ctx.builder = BasicBlockBuilder(ctx.activeGraph, [right], parent);
        emit(expression.rightOperand, yes, no);
        return;
      }
    }
    final compiledValue = compileExpression(expression, ctx);
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
    ctx.pushOp(JumpIfFalse(value.ssa, no.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, yes);
    ctx.builder.link(tail, no);
    ctx.restoreState(initialState);
  }

  emit(expression, whenTrue, whenFalse);
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
  final conversion = value.type
      .resolveTypeChain(ctx)
      .assignmentConversionTo(ctx, CoreTypes.bool.ref(ctx));
  if (conversion == AssignmentConversion.invalid ||
      (conversion == AssignmentConversion.runtimeCheck &&
          value.type != CoreTypes.dynamic.ref(ctx))) {
    throw CompileError(
      "Conditions must have a static type of 'bool'",
      source,
    );
  }
}

bool _containsTypeTest(AstNode node) =>
    node is IsExpression ||
    node.childEntities.whereType<AstNode>().any(_containsTypeTest);
