import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';

import '../errors.dart';
import 'expression.dart';

final binaryOpMap = {
  TokenType.PLUS: '+',
  TokenType.MINUS: '-',
  TokenType.SLASH: '/',
  TokenType.STAR: '*',
  TokenType.LT: '<',
  TokenType.GT: '>',
  TokenType.LT_EQ: '<=',
  TokenType.GT_EQ: '>=',
  TokenType.PERCENT: '%',
  TokenType.EQ_EQ: '==',
  TokenType.AMPERSAND_AMPERSAND: '&&',
  TokenType.QUESTION_QUESTION: '??',
  TokenType.BAR_BAR: '||',
  TokenType.BAR: '|',
  TokenType.AMPERSAND: '&',
  TokenType.LT_LT: '<<',
  TokenType.GT_GT: '>>',
  TokenType.GT_GT_GT: '>>>',
  TokenType.BANG_EQ: '!=',
  TokenType.CARET: '^',
  TokenType.TILDE_SLASH: '~/',
};

/// Compile a [BinaryExpression] to EVC bytecode
Variable compileBinaryExpression(
  CompilerContext ctx,
  BinaryExpression e, [
  TypeRef? boundType,
]) {
  final method =
      binaryOpMap[e.operator.type] ??
      (throw CompileError('Unknown binary operator ${e.operator.type}'));
  var L = compileExpression(e.leftOperand, ctx, boundType);

  switch (e.operator.type) {
    case TokenType.AMPERSAND_AMPERSAND:
    case TokenType.BAR_BAR:
    case TokenType.QUESTION_QUESTION:
      return _compileShortCircuit(
        ctx,
        L,
        e.leftOperand,
        e.rightOperand,
        method,
      );
  }

  // Evaluating the right operand can assign or change the representation of a
  // local used by the left operand. Preserve its already evaluated value.
  L = Variable.ssa(ctx, Assign(ctx.svar('binary_left'), L.ssa), L.type);
  var R = compileExpression(e.rightOperand, ctx, boundType);

  return L.invoke(ctx, method, [R]).result;
}

Variable _compileShortCircuit(
  CompilerContext ctx,
  Variable L,
  Expression left,
  Expression right,
  String operator,
) {
  late TypeRef rightType;
  var outVar = BuiltinValue().push(ctx);
  L = L.boxIfNeeded(ctx);
  ctx.pushOp(Assign(outVar.ssa, L.ssa));

  macroBranch(
    ctx,
    null,
    condition: (ctx) {
      if (operator == '??') {
        return Variable.ssa(
          ctx,
          IsNull(ctx.svar('short_circuit_test'), L.ssa),
          CoreTypes.bool.ref(ctx).copyWith(boxed: false),
        );
      }
      final value = convertForAssignment(
        ctx,
        L,
        CoreTypes.bool.ref(ctx),
        representation: MachineRepresentation.boolean,
        source: right,
        description: 'Operands of $operator must be boolean',
      );
      if (operator == '&&') return value;
      return Variable.ssa(
        ctx,
        LogicalNot(ctx.svar('short_circuit_test'), value.ssa),
        value.type,
      );
    },
    thenBranch: (ctx, rt) {
      // Short-circuit: we only execute the RHS if the LHS is null
      if (operator == '&&' || operator == '||') {
        applyConditionPromotions(ctx, left, operator == '&&');
      }
      var R = compileExpression(right, ctx);
      if (operator != '??') {
        R = convertForAssignment(
          ctx,
          R,
          CoreTypes.bool.ref(ctx),
          representation: MachineRepresentation.object,
          source: right,
          description: 'Operands of $operator must be boolean',
        );
      } else {
        R = R.boxIfNeeded(ctx);
      }
      rightType = R.type;
      ctx.pushOp(Assign(outVar.ssa, R.ssa));
      return StatementInfo();
    },
  );

  final outType = operator == '??'
      ? TypeRef.commonBaseType(ctx, {
          L.type.copyWith(nullable: false),
          rightType,
        }).copyWith(boxed: true)
      : CoreTypes.bool.ref(ctx).copyWith(boxed: true);

  return outVar.copyWith(type: outType);
}
