import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileAssignmentExpression(
    AssignmentExpression e, CompilerContext ctx) {
  final L = compileExpressionAsReference(e.leftHandSide, ctx);
  final R = compileExpression(e.rightHandSide, ctx);

  if (e.operator.type == TokenType.EQ) {
    return L.setValue(ctx, R);
  } else if (e.operator.type.binaryOperatorOfCompoundAssignment ==
      TokenType.QUESTION_QUESTION) {
    late Variable result;
    macroBranch(ctx, null, condition: (_ctx) {
      return L
          .getValue(_ctx)
          .invoke(ctx, '==', [BuiltinValue().push(_ctx)]).result;
    }, thenBranch: (_ctx, rt) {
      result = L.setValue(ctx, R.boxIfNeeded(ctx));
      return StatementInfo(-1);
    });
    return result;
  } else {
    final method = e.operator.type.binaryOperatorOfCompoundAssignment!.lexeme;
    return L.setValue(ctx, L.getValue(ctx).invoke(ctx, method, [R]).result);
  }
}
