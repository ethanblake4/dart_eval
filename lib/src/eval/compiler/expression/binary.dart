import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../errors.dart';
import 'expression.dart';

/// Compile a [BinaryExpression] to EVC bytecode
Variable compileBinaryExpression(CompilerContext ctx, BinaryExpression e,
    [TypeRef? boundType]) {
  var L = compileExpression(e.leftOperand, ctx, boundType);
  var R = compileExpression(e.rightOperand, ctx, boundType);

  if (e.operator.type == TokenType.QUESTION_QUESTION) {
    final outType =
        TypeRef.commonBaseType(ctx, {L.type.copyWith(nullable: false), R.type})
            .copyWith(boxed: true);
    var outVar = BuiltinValue().push(ctx).copyWith(type: outType);
    L = L.boxIfNeeded(ctx);
    ctx.pushOp(CopyValue.make(outVar.scopeFrameOffset, L.scopeFrameOffset),
        CopyValue.LEN);
    macroBranch(ctx, null, condition: (_ctx) {
      final $null = BuiltinValue().push(ctx).boxIfNeeded(ctx);
      ctx.pushOp(CheckEq.make(L.scopeFrameOffset, $null.scopeFrameOffset),
          CheckEq.LEN);
      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
      return Variable.alloc(
          ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
    }, thenBranch: (_ctx, rt) {
      R = R.boxIfNeeded(ctx);
      ctx.pushOp(CopyValue.make(outVar.scopeFrameOffset, R.scopeFrameOffset),
          CopyValue.LEN);
      return StatementInfo(-1);
    });

    return outVar;
  }

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
  };

  var method = opMap[e.operator.type] ??
      (throw CompileError('Unknown binary operator ${e.operator.type}'));

  return L.invoke(ctx, method, [R]).result;
}
