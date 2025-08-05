import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/helpers/pattern.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

StatementInfo compileSwitchStatement(SwitchStatement s, CompilerContext ctx,
    AlwaysReturnType? expectedReturnType) {
  final switchExpr = compileExpression(s.expression, ctx).boxIfNeeded(ctx);

  // Validate switch cases for proper Dart semantics
  _validateSwitchCases(s.members);

  final result = _compileSwitchCases(
      ctx, switchExpr, s.members, 0, expectedReturnType,
      source: s);

  return result;
}

StatementInfo _compileSwitchCases(CompilerContext ctx, Variable switchExpr,
    List<SwitchMember> cases, int index, AlwaysReturnType? expectedReturnType,
    {AstNode? source}) {
  if (index >= cases.length) {
    // No more cases, return empty statement
    return StatementInfo(-1);
  }

  final currentCase = cases[index];

  // Handle default case
  if (currentCase is SwitchDefault) {
    return _executeSwitchBlock(ctx, currentCase.statements, expectedReturnType);
  }

  return macroBranch(
    ctx,
    expectedReturnType,
    condition: (ctx) {
      if (currentCase is SwitchCase) {
        final caseVar = compileExpression(currentCase.expression, ctx);
        return switchExpr.invoke(ctx, '==', [caseVar]).result;
      } else if (currentCase is SwitchPatternCase) {
        final matches = patternMatchAndBind(
            ctx, currentCase.guardedPattern.pattern, switchExpr);
        final guard = currentCase.guardedPattern.whenClause;
        if (guard != null) {
          // If there's a guard, we need to compile it and check if it matches
          final guardExpr = compileExpression(guard.expression, ctx);
          return matches.invoke(ctx, '&&', [guardExpr]).result;
        }
        return matches;
      } else {
        throw CompileError(
            'Unsupported switch case type: ${currentCase.runtimeType}',
            currentCase);
      }
    },
    thenBranch: (ctx, expectedReturnType) {
      // Execute this case and following empty cases (Dart fall-through)
      return _executeMatchingCases(ctx, cases, index, expectedReturnType);
    },
    elseBranch: (ctx, expectedReturnType) {
      // Try next case
      return _compileSwitchCases(
          ctx, switchExpr, cases, index + 1, expectedReturnType);
    },
    source: source,
  );
}

StatementInfo _executeMatchingCases(
    CompilerContext ctx,
    List<SwitchMember> cases,
    int startIndex,
    AlwaysReturnType? expectedReturnType) {
  var willAlwaysReturn = false;
  var willAlwaysThrow = false;
  var position = ctx.out.length;

  // Find the first case with statements starting from startIndex
  int executionIndex = startIndex;

  // Skip through empty cases (proper Dart fall-through)
  while (executionIndex < cases.length &&
      cases[executionIndex].statements.isEmpty) {
    executionIndex++;
  }

  // Execute the case with statements (if found)
  if (executionIndex < cases.length) {
    final member = cases[executionIndex];
    final stmtInfo =
        _executeSwitchBlock(ctx, member.statements, expectedReturnType);
    willAlwaysReturn = stmtInfo.willAlwaysReturn;
    willAlwaysThrow = stmtInfo.willAlwaysThrow;
  }

  return StatementInfo(position,
      willAlwaysReturn: willAlwaysReturn, willAlwaysThrow: willAlwaysThrow);
}

StatementInfo _executeSwitchBlock(CompilerContext ctx,
    List<Statement> statements, AlwaysReturnType? expectedReturnType) {
  var willAlwaysReturn = false;
  var willAlwaysThrow = false;
  final position = ctx.out.length;

  ctx.beginAllocScope();

  for (final stmt in statements) {
    final stmtInfo = compileStatement(stmt, expectedReturnType, ctx);

    if (stmtInfo.willAlwaysThrow) {
      willAlwaysThrow = true;
      break;
    }
    if (stmtInfo.willAlwaysReturn) {
      willAlwaysReturn = true;
      break;
    }
  }

  ctx.endAllocScope(popValues: !willAlwaysThrow && !willAlwaysReturn);

  return StatementInfo(position,
      willAlwaysReturn: willAlwaysReturn, willAlwaysThrow: willAlwaysThrow);
}

void _validateSwitchCases(List<SwitchMember> cases) {
  for (int i = 0; i < cases.length; i++) {
    final currentCase = cases[i];

    // Skip default case - it's always at the end
    if (currentCase is SwitchDefault) continue;

    // If this case has statements, check if it properly terminates
    if (currentCase.statements.isNotEmpty) {
      if (!_caseProperlyTerminates(currentCase.statements)) {
        throw CompileError(
            "The 'case' shouldn't complete normally. Try adding 'break', 'return', or 'throw'.",
            currentCase);
      }
    }
  }
}

bool _caseProperlyTerminates(List<Statement> statements) {
  if (statements.isEmpty) return true; // Empty case is OK

  // Check if any statement in the case would always return/throw
  for (final statement in statements) {
    if (statement is ReturnStatement) {
      return true;
    }
    if (statement is ExpressionStatement &&
        statement.expression is ThrowExpression) {
      return true;
    }
    // Check for switch statements that always return
    if (statement is SwitchStatement) {
      if (_switchAlwaysReturns(statement)) {
        return true;
      }
    }
  }

  final lastStatement = statements.last;

  // Check if last statement is a proper terminator
  return lastStatement is BreakStatement ||
      lastStatement is ReturnStatement ||
      lastStatement is ContinueStatement ||
      (lastStatement is ExpressionStatement &&
          lastStatement.expression is ThrowExpression);
}

bool _switchAlwaysReturns(SwitchStatement switchStmt) {
  // For simplicity, we'll be conservative and only check obvious cases
  // A more sophisticated analysis would check if all possible paths return
  for (final member in switchStmt.members) {
    if (member.statements.isNotEmpty) {
      for (final stmt in member.statements) {
        if (stmt is ReturnStatement) {
          continue; // This case returns
        }
      }
    }
  }
  return false; // Conservative approach - assume it might not always return
}
