import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileParenthesizedExpression(ParenthesizedExpression e, CompilerContext ctx) {
  return compileExpression(e.expression, ctx);
}
