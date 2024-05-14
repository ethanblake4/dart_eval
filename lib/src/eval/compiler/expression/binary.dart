import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';

import '../errors.dart';
import 'expression.dart';

/// Compile a [BinaryExpression] to EVC bytecode
Variable compileBinaryExpression(CompilerContext ctx, BinaryExpression e,
    [TypeRef? boundType]) {
  var L = compileExpression(e.leftOperand, ctx, boundType);

  if (e.operator.type == TokenType.QUESTION_QUESTION) {
    return _compileNullCoalesce(ctx, L, e.rightOperand);
  }

  var R = compileExpression(e.rightOperand, ctx, boundType);

  final opMap = {
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
    TokenType.BAR_BAR: '||',
    TokenType.BAR: '|',
    TokenType.AMPERSAND: '&',
    TokenType.LT_LT: '<<',
    TokenType.GT_GT: '>>',
    TokenType.BANG_EQ: '!=',
    TokenType.CARET: '^',
    TokenType.TILDE_SLASH: '~/'
  };

  var method = opMap[e.operator.type] ??
      (throw CompileError('Unknown binary operator ${e.operator.type}'));
  return L.invoke(ctx, method, [R]).result;
}

Variable _compileNullCoalesce(
    CompilerContext ctx, Variable L, Expression right) {
  late TypeRef rightType;
  var outVar = BuiltinValue().push(ctx);
  L = L.boxIfNeeded(ctx);
  ctx.pushOp(Assign(outVar.ssa, L.ssa));

  macroBranch(ctx, null, condition: (_ctx) {
    return L;
  }, thenBranch: (_ctx, rt) {
    // Short-circuit: we only execute the RHS if the LHS is null
    final R = compileExpression(right, ctx).boxIfNeeded(ctx);
    rightType = R.type;
    ctx.pushOp(Assign(outVar.ssa, R.ssa));
    return StatementInfo(-1);
  }, testNullish: true);

  final outType =
      TypeRef.commonBaseType(ctx, {L.type.copyWith(nullable: false), rightType})
          .copyWith(boxed: true);

  return outVar.copyWith(type: outType);
}
