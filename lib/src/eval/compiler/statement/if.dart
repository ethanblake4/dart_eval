import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/helpers/pattern.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';

StatementInfo compileIfStatement(
  IfStatement s,
  CompilerContext ctx,
  AlwaysReturnType? expectedReturnType,
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
  AlwaysReturnType? expectedReturnType,
) {
  final elseStatement = s.elseStatement;
  final subject = compileExpression(s.expression, ctx);
  final caseValue = Variable.ssa(
    ctx,
    Assign(ctx.svar('case_value'), subject.ssa),
    subject.type,
  );
  return macroBranch(
    ctx,
    expectedReturnType,
    condition: (ctx) {
      var matches = patternMatchAndBind(
        ctx,
        caseClause.guardedPattern.pattern,
        caseValue,
      );
      final guard = caseClause.guardedPattern.whenClause;
      if (guard != null) {
        final guardExpr = compileExpression(guard.expression, ctx);
        matches = matches.invoke(ctx, '&&', [guardExpr]).result;
      }
      return matches;
    },
    thenBranch: (ctx, expectedReturnType) =>
        compileStatement(s.thenStatement, expectedReturnType, ctx),
    elseBranch: elseStatement == null
        ? null
        : (ctx, expectedReturnType) =>
              compileStatement(elseStatement, expectedReturnType, ctx),
    source: s,
  );
}
