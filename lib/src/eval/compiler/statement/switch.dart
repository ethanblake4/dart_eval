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
    // Handle pattern switch cases using duck typing (more robust across platforms)
    try {
      final dynamic patternCase = currentCase;

      // Try to access guardedPattern property - use duck typing
      try {
        final dynamic guardedPattern = patternCase.guardedPattern;
        if (guardedPattern != null) {
          final dynamic pattern = guardedPattern.pattern;

          if (pattern != null) {
            // Try to access the expression property - works for ConstantPattern
            try {
              final dynamic constantPattern = pattern;
              final Expression? expr = constantPattern.expression;
              if (expr != null) {
                caseExpression = expr;
              } else {
                throw CompileError(
                    'Switch pattern must have a constant expression. Only enum constants and literal values are supported.',
                    currentCase);
              }
            } catch (e) {
              // If we can't access expression, it's not a constant pattern
              throw CompileError(
                  'Unsupported switch pattern type. Only constant patterns (enum values, literals) are supported.',
                  currentCase);
            }
          } else {
            throw CompileError(
                'Could not extract pattern from switch case', currentCase);
          }
        } else {
          throw CompileError(
              'Switch case is missing guardedPattern', currentCase);
        }
      } catch (e) {
        // Fallback: try to treat as legacy case that might have direct expression property
        try {
          final dynamic legacyCase = currentCase;
          final Expression? expr = legacyCase.expression;
          if (expr != null) {
            caseExpression = expr;
          } else {
            throw CompileError(
                'Switch case must have an expression. Case type: ${currentCase.runtimeType}',
                currentCase);
          }
        } catch (fallbackError) {
          // Final error with helpful debugging info
          print("DEBUG: Switch case compilation failed");
          print("DEBUG: Original error: ${e.toString()}");
          print("DEBUG: Fallback error: ${fallbackError.toString()}");
          print("DEBUG: Case type: ${currentCase.runtimeType}");
          throw CompileError(
              'Unsupported switch case format. Only enum constants (e.g., MyEnum.value) and literal values are supported in switch cases.',
              currentCase);
        }
      }
    } catch (e) {
      if (e is CompileError) {
        rethrow;
      }
      // Unexpected error - provide debugging info
      print("DEBUG: Unexpected switch case error: ${e.toString()}");
      print("DEBUG: Case type: ${currentCase.runtimeType}");
      throw CompileError(
          'Failed to process switch case. Only enum constants and literal values are supported.',
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
