import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileAssignmentExpression(
    AssignmentExpression e, CompilerContext ctx) {
  final L = compileExpressionAsReference(e.leftHandSide, ctx);
  final R =
      compileExpression(e.rightHandSide, ctx, L.resolveType(ctx, forSet: true));

  if (e.operator.type == TokenType.EQ) {
    final set =
        R.type != L.resolveType(ctx, forSet: true) ? R.boxIfNeeded(ctx) : R;
    return L.setValue(ctx, set);
  } else if (e.operator.type.binaryOperatorOfCompoundAssignment ==
      TokenType.QUESTION_QUESTION) {
    late Variable result;
    macroBranch(ctx, null, condition: (ctx) {
      return L
          .getValue(ctx)
          .invoke(ctx, '==', [BuiltinValue().push(ctx)]).result;
    }, thenBranch: (ctx, rt) {
      result = L.setValue(ctx, R.boxIfNeeded(ctx));
      return StatementInfo(-1);
    });
    return result;
  } else {
    final method = e.operator.type.binaryOperatorOfCompoundAssignment!.lexeme;
    final V = L.getValue(ctx);
    final res = V.invoke(ctx, method, [R]).result;
    final set = res.type != L.resolveType(ctx, forSet: true)
        ? res.boxIfNeeded(ctx)
        : res;
    return L.setValue(ctx, set);
  }
}
