import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';

import '../variable.dart';

Reference compileIndexExpressionAsReference(
    IndexExpression e, CompilerContext ctx,
    {Variable? cascadeTarget}) {
  final value = cascadeTarget ?? compileExpression(e.realTarget, ctx);
  final index = compileExpression(e.index, ctx);
  return IndexedReference(value, index);
}

Variable compileIndexExpression(IndexExpression e, CompilerContext ctx,
    {Variable? cascadeTarget}) {
  return compileIndexExpressionAsReference(e, ctx, cascadeTarget: cascadeTarget)
      .getValue(ctx);
}
