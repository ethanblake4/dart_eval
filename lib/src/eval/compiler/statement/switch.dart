import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/helpers/pattern.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/break.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

StatementInfo compileSwitchStatement(
  SwitchStatement s,
  CompilerContext ctx,
  AlwaysReturnType? expectedReturnType,
) {
  final expression = compileExpression(s.expression, ctx);
  // Evaluate once. Cases may change their operand representation without
  // rewriting the source binding or the value inspected by later cases.
  final switchExpr = expression.copyIntoFreshSlot(ctx, 'switch_value');

  final endBlock = BasicBlock<Operation>([], label: ctx.label('switch_end'));
  final initialState = ctx.saveState();
  final breakStates = <ContextSaveState>[];
  ctx.labels.add(
    CompilerLabel(
      (ctx) {
        ctx.resolveBranchStateDiscontinuity(initialState);
        breakStates.add(ctx.saveState());
      },
      exceptionDepth: ctx.exceptionDepth,
      breakTarget: endBlock,
      names: ctx.takePendingLabelNames(),
    ),
  );
  final result = _compileSwitchCases(
    ctx,
    switchExpr,
    s.members,
    0,
    expectedReturnType,
    source: s,
  );

  ctx.labels.removeLast();
  ctx.flushBlock();
  ctx.builder = ctx.builder.then(endBlock);
  final fallthroughState = ctx.saveState();
  ctx.restoreState(initialState);
  ctx.mergeBranchState([fallthroughState, ...breakStates]);
  return result.copyWith(willAlwaysBreak: false);
}

StatementInfo _compileSwitchCases(
  CompilerContext ctx,
  Variable switchExpr,
  List<SwitchMember> cases,
  int index,
  AlwaysReturnType? expectedReturnType, {
  AstNode? source,
}) {
  if (index >= cases.length) {
    // No more cases, return empty statement
    return StatementInfo();
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
      final subject = switchExpr.copyIntoFreshSlot(ctx, 'case_value');
      if (currentCase is SwitchCase) {
        final caseVar = compileExpression(currentCase.expression, ctx);
        _checkPrimitiveEquality(ctx, caseVar, currentCase.expression);
        return subject.invoke(ctx, '==', [caseVar]).result;
      } else if (currentCase is SwitchPatternCase) {
        final matches = patternMatchAndBind(
          ctx,
          currentCase.guardedPattern.pattern,
          subject,
        );
        final guard = currentCase.guardedPattern.whenClause;
        if (guard != null) {
          // If there's a guard, we need to compile it and check if it matches
          final guardExpr = compileExpression(
            guard.expression,
            ctx,
            CoreTypes.bool.ref(ctx),
          );
          return matches.invoke(ctx, '&&', [guardExpr]).result;
        }
        return matches;
      } else {
        throw CompileError(
          'Unsupported switch case type: ${currentCase.runtimeType}',
          currentCase,
        );
      }
    },
    thenBranch: (ctx, expectedReturnType) {
      // Execute this case and following empty cases (Dart fall-through)
      return _executeMatchingCases(ctx, cases, index, expectedReturnType);
    },
    elseBranch: (ctx, expectedReturnType) {
      // Try next case
      return _compileSwitchCases(
        ctx,
        switchExpr,
        cases,
        index + 1,
        expectedReturnType,
      );
    },
    source: source,
  );
}

StatementInfo _executeMatchingCases(
  CompilerContext ctx,
  List<SwitchMember> cases,
  int startIndex,
  AlwaysReturnType? expectedReturnType,
) {
  var willAlwaysReturn = false;
  var willAlwaysThrow = false;
  var willAlwaysBreak = false;

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
    final stmtInfo = _executeSwitchBlock(
      ctx,
      member.statements,
      expectedReturnType,
    );
    willAlwaysReturn = stmtInfo.willAlwaysReturn;
    willAlwaysThrow = stmtInfo.willAlwaysThrow;
    willAlwaysBreak = stmtInfo.willAlwaysBreak;
  }

  return StatementInfo(
    willAlwaysReturn: willAlwaysReturn,
    willAlwaysThrow: willAlwaysThrow,
    willAlwaysBreak: willAlwaysBreak,
  );
}

StatementInfo _executeSwitchBlock(
  CompilerContext ctx,
  List<Statement> statements,
  AlwaysReturnType? expectedReturnType,
) {
  var willAlwaysReturn = false;
  var willAlwaysThrow = false;
  var willAlwaysBreak = false;

  ctx.beginScope();

  for (final stmt in statements) {
    final stmtInfo = compileStatement(stmt, expectedReturnType, ctx);

    if (stmtInfo.willAlwaysBreak) {
      willAlwaysBreak = true;
      break;
    }
    if (stmtInfo.willAlwaysThrow) {
      willAlwaysThrow = true;
      break;
    }
    if (stmtInfo.willAlwaysReturn) {
      willAlwaysReturn = true;
      break;
    }
  }

  ctx.endScope();

  // Dart 3: a non-empty case implicitly breaks — no terminator needed.
  // Emit the jump to the switch's end so the SSA edge matches an explicit
  // `break` exactly.
  if (statements.isNotEmpty &&
      !willAlwaysReturn &&
      !willAlwaysThrow &&
      !willAlwaysBreak &&
      !ctx.blockEndsControlFlow) {
    final label = findJumpLabel(
      ctx,
      null,
      (label) => label.breakTarget != null,
      statements.last,
      kind: 'break',
    );
    jumpToLabel(ctx, label, label.breakTarget!);
    willAlwaysBreak = true;
  }

  return StatementInfo(
    willAlwaysReturn: willAlwaysReturn,
    willAlwaysThrow: willAlwaysThrow,
    willAlwaysBreak: willAlwaysBreak,
  );
}

/// A `case e:` expression must have a primitive `==` — a user-declared
/// `operator ==` on the expression's static type is a compile-time error.
void _checkPrimitiveEquality(
  CompilerContext ctx,
  Variable caseVar,
  AstNode source,
) {
  final t = caseVar.type.resolveTypeChain(ctx);
  if (t.isTypeParameter) return;
  if (ctx.instanceDeclarationsMap[t.file]?[t.name]?['=='] != null) {
    throw CompileError(
      "Case expression '$t' does not have a primitive operator '=='.",
      source,
      ctx.library,
      ctx,
    );
  }
}
