import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

import '../reference.dart';

Variable compileAssignmentExpression(AssignmentExpression e, CompilerContext ctx) {
  return compileAssignmentExpressionAsReference(e, ctx).getValue(ctx);
}

Reference compileAssignmentExpressionAsReference(AssignmentExpression e, CompilerContext ctx) {
  final L = compileExpressionAsReference(e.leftHandSide, ctx);
  final R = compileExpression(e.rightHandSide, ctx);

  if (e.operator.type == TokenType.EQ) {
    final Ltype = L.resolveType(ctx).resolveTypeChain(ctx);
    if (!R.type.resolveTypeChain(ctx).isAssignableTo(ctx, Ltype)) {
      throw CompileError('Syntax error: cannot assign value of type ${R.type} to $Ltype');
    }
    L.setValue(ctx, R);
  } else {
    final opMap = {TokenType.PLUS_EQ: '+', TokenType.MINUS_EQ: '-'};
    final method = opMap[e.operator.type]!;
    L.setValue(ctx, L.getValue(ctx).invoke(ctx, method, [R]).result);
  }
  return L;
}
