import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

StatementInfo compileSwitchStatement(SwitchStatement s, CompilerContext ctx,
    AlwaysReturnType? expectedReturnType) {
  final switchExpr = compileExpression(s.expression, ctx).boxIfNeeded(ctx);

  // Validate switch cases for proper Dart semantics
  _validateSwitchCases(s.members);

  // Create a switch label for break statements
  final switchLabel = CompilerLabel(LabelType.branch, ctx.out.length, (_ctx) {
    return -1;
  });

  ctx.labels.add(switchLabel);
  final result = _compileSwitchCases(
      ctx, switchExpr, s.members, 0, expectedReturnType,
      source: s);
  ctx.labels.removeLast();

  // Resolve any break statements that jumped to this switch
  ctx.resolveLabel(switchLabel);

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

  // Handle regular case - support both SwitchCase and SwitchPatternCase
  Expression? caseExpression;
  if (currentCase is SwitchCase) {
    caseExpression = currentCase.expression;
  } else {
    // Handle Dart 3.0+ pattern switch cases
    try {
      final dynamic patternCase = currentCase;
      final dynamic guardedPattern = patternCase.guardedPattern;
      final dynamic pattern = guardedPattern?.pattern;

      if (pattern != null) {
        final patternType = pattern.runtimeType.toString();

        // Handle ConstantPattern (literal values)
        if (patternType.contains('ConstantPattern')) {
          final dynamic constantPattern = pattern;
          caseExpression = constantPattern.expression;
        }
        // Handle PropertyAccess patterns (like EnumName.value)
        else if (patternType.contains('PropertyAccess') ||
            patternType.contains('PrefixedIdentifier') ||
            patternType.contains('Identifier')) {
          // For enum values and other constant expressions
          caseExpression = pattern;
        }
        // Handle other constant-like patterns
        else if (patternType.contains('Literal') ||
            patternType.contains('Simple')) {
          // Try to extract expression if it exists
          try {
            final dynamic expressionPattern = pattern;
            if (expressionPattern.expression != null) {
              caseExpression = expressionPattern.expression;
            } else {
              caseExpression = pattern;
            }
          } catch (e) {
            caseExpression = pattern;
          }
        } else {
          throw CompileError(
              'Unsupported switch pattern type: $patternType. Only constant patterns are supported.',
              currentCase);
        }
      } else {
        throw CompileError(
            'Unsupported switch pattern type. Only constant patterns are supported.',
            currentCase);
      }
    } catch (e) {
      if (e is CompileError) rethrow;
      print("ERROR: $e");
      throw CompileError(
          'Unsupported switch case type: ${currentCase.runtimeType}',
          currentCase);
    }
  }

  if (caseExpression == null) {
    throw CompileError(
        'Could not extract expression from switch case', currentCase);
  }

  return macroBranch(
    ctx,
    expectedReturnType,
    condition: (_ctx) {
      final caseExpr =
          compileExpression(caseExpression!, _ctx).boxIfNeeded(_ctx);
      return switchExpr.invoke(_ctx, '==', [caseExpr]).result;
    },
    thenBranch: (_ctx, _expectedReturnType) {
      // Execute this case and following empty cases (Dart fall-through)
      return _executeMatchingCases(_ctx, cases, index, _expectedReturnType);
    },
    elseBranch: (_ctx, _expectedReturnType) {
      // Try next case
      return _compileSwitchCases(
          _ctx, switchExpr, cases, index + 1, _expectedReturnType);
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
