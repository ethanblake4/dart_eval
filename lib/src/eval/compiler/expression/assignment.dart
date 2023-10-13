import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/source_node_wrapper.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

import '../reference.dart';

Variable compileAssignmentExpression(
    AssignmentExpression e, CompilerContext ctx) {
  return compileAssignmentExpressionAsReference(e, ctx).getValue(ctx);
}

Reference compileAssignmentExpressionAsReference(
    AssignmentExpression e, CompilerContext ctx) {
  final L = compileExpressionAsReference(e.leftHandSide, ctx);
  final R = compileExpression(e.rightHandSide, ctx);

  if (e.operator.type == TokenType.EQ) {
    final Ltype = L.resolveType(ctx).resolveTypeChain(ctx);
    if (!R.type.resolveTypeChain(ctx).isAssignableTo(ctx, Ltype)) {
      throw CompileError(
          'Syntax error: cannot assign value of type ${R.type} to $Ltype');
    }
    L.setValue(ctx, R);
  } else if (e.operator.type.binaryOperatorOfCompoundAssignment ==
      TokenType.QUESTION_QUESTION) {
    macroBranch(ctx, null, condition: (_ctx) {
      return L
          .getValue(_ctx)
          .invoke(ctx, '==', [BuiltinValue().push(_ctx)]).result;
    }, thenBranch: (_ctx, rt) {
      L.setValue(ctx, R.boxIfNeeded(ctx));
      return StatementInfo(-1);
    });
  } else {
    final method = e.operator.type.binaryOperatorOfCompoundAssignment!.lexeme;
    L.setValue(ctx, L.getValue(ctx).invoke(ctx, method, [R]).result);
  }
  return L;
}
