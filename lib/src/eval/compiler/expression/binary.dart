import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

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
  TokenType.BANG_EQ: '!=',
  TokenType.CARET: '^',
  TokenType.TILDE_SLASH: '~/'
};

/// Compile a [BinaryExpression] to EVC bytecode
Variable compileBinaryExpression(CompilerContext ctx, BinaryExpression e,
    [TypeRef? boundType]) {
  final method = binaryOpMap[e.operator.type] ??
      (throw CompileError('Unknown binary operator ${e.operator.type}'));
  var L = compileExpression(e.leftOperand, ctx, boundType);

  switch (e.operator.type) {
    case TokenType.AMPERSAND_AMPERSAND:
    case TokenType.BAR_BAR:
    case TokenType.QUESTION_QUESTION:
      return _compileShortCircuit(ctx, L, e.rightOperand, method);
  }

  var R = compileExpression(e.rightOperand, ctx, boundType);

  return L.invoke(ctx, method, [R]).result;
}

Variable _compileShortCircuit(
    CompilerContext ctx, Variable L, Expression right, String operator) {
  late TypeRef rightType;
  var outVar = BuiltinValue().push(ctx);
  L = L.boxIfNeeded(ctx);
  ctx.pushOp(CopyValue.make(outVar.scopeFrameOffset, L.scopeFrameOffset),
      CopyValue.LEN);

  macroBranch(ctx, null, condition: (ctx) {
    final Variable $comparison;
    switch (operator) {
      case '??':
        $comparison = BuiltinValue().push(ctx).boxIfNeeded(ctx);
        break;
      case '&&':
        $comparison = BuiltinValue(boolval: true).push(ctx).boxIfNeeded(ctx);
        break;
      case '||':
        $comparison = BuiltinValue(boolval: false).push(ctx).boxIfNeeded(ctx);
        break;
      default:
        throw CompileError('Unknown short-circuit operator $operator');
    }
    ctx.pushOp(CheckEq.make(L.scopeFrameOffset, $comparison.scopeFrameOffset),
        CheckEq.LEN);
    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    return Variable.alloc(ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
  }, thenBranch: (ctx, rt) {
    // Short-circuit: we only execute the RHS if the LHS is null
    final R = compileExpression(right, ctx).boxIfNeeded(ctx);
    rightType = R.type;
    ctx.pushOp(CopyValue.make(outVar.scopeFrameOffset, R.scopeFrameOffset),
        CopyValue.LEN);
    return StatementInfo(-1);
  });

  final outType = operator == '??'
      ? TypeRef.commonBaseType(
              ctx, {L.type.copyWith(nullable: false), rightType})
          .copyWith(boxed: true)
      : CoreTypes.bool.ref(ctx).copyWith(boxed: true);

  return outVar.copyWith(type: outType);
}
