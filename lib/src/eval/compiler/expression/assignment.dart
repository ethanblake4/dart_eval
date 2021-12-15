import 'package:analyzer/dart/ast/ast.dart';
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

  final Ltype = L.resolveType(ctx);
  if (!R.type.isAssignableTo(Ltype)) {
    throw CompileError('Syntax error: cannot assign value of type ${R.type} to $Ltype');
  }
  L.setValue(ctx, R);
  return L;
}