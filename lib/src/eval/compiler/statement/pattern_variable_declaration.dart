import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/pattern.dart';

import 'statement.dart';

StatementInfo compilePatternVariableDeclarationStatement(
    PatternVariableDeclarationStatement s, CompilerContext ctx) {
  compilePatternVariableDeclaration(s.declaration, ctx);
  return StatementInfo(-1);
}

void compilePatternVariableDeclaration(
    PatternVariableDeclaration dec, CompilerContext ctx) {
  final bound = patternTypeBound(ctx, dec.pattern, source: dec);
  final result = compileExpression(dec.expression, ctx, bound);
  patternMatchAndBind(ctx, dec.pattern, result,
      patternContext: dec.keyword.keyword == Keyword.FINAL
          ? PatternBindContext.declareFinal
          : PatternBindContext.declare);
}
