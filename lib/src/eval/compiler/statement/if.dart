import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/pattern_condition.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

StatementInfo compileIfStatement(
  IfStatement s,
  CompilerContext ctx,
  TypeRef? expectedReturnType,
) {
  final caseClause = s.caseClause;
  final elseStatement = s.elseStatement;
  if (caseClause != null) {
    return _compileIfCaseStatement(s, caseClause, ctx, expectedReturnType);
  }
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

StatementInfo _compileIfCaseStatement(
  IfStatement s,
  CaseClause caseClause,
  CompilerContext ctx,
  TypeRef? expectedReturnType,
) {
  final elseStatement = s.elseStatement;
  final subject = compileExpression(s.expression, ctx);
  final caseValue = subject.copyIntoFreshSlot(ctx, 'case_value');
  return macroBranch(
    ctx,
    expectedReturnType,
    conditionGraph: (ctx, yes, no) => compilePatternCondition(
      ctx,
      caseClause.guardedPattern,
      caseValue,
      yes,
      no,
      source: s.expression,
    ),
    thenBranch: (ctx, expectedReturnType) =>
        compileStatement(s.thenStatement, expectedReturnType, ctx),
    elseBranch: elseStatement == null
        ? null
        : (ctx, expectedReturnType) =>
              compileStatement(elseStatement, expectedReturnType, ctx),
    source: s,
  );
}
