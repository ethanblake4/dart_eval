import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

StatementInfo compileIfStatement(
    IfStatement s, CompilerContext ctx, AlwaysReturnType? expectedReturnType) {
  final elseStatement = s.elseStatement;
  return macroBranch(
    ctx,
    expectedReturnType,
    condition: (_ctx) => compileExpression(s.expression, _ctx),
    thenBranch: (_ctx, expectedReturnType) =>
        compileStatement(s.thenStatement, expectedReturnType, _ctx),
    elseBranch: elseStatement == null
        ? null
        : (_ctx, expectedReturnType) =>
            compileStatement(elseStatement, expectedReturnType, _ctx),
  );
}
