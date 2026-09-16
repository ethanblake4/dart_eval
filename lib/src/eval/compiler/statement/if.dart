import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

StatementInfo compileIfStatement(
  IfStatement s,
  CompilerContext ctx,
  AlwaysReturnType? expectedReturnType,
) {
  final elseStatement = s.elseStatement;
  return macroBranch(
    ctx,
    expectedReturnType,
    conditionExpression: s.expression,
    thenBranch: (ctx, expectedReturnType) =>
        compileStatement(s.thenStatement, expectedReturnType, ctx),
    elseBranch: elseStatement == null
        ? null
        : (ctx, expectedReturnType) =>
              compileStatement(elseStatement, expectedReturnType, ctx),
    source: s,
  );
}
