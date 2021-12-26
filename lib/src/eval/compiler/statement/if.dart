import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

StatementInfo compileIfStatement(IfStatement s, CompilerContext ctx, AlwaysReturnType? expectedReturnType) {
  ctx.beginAllocScope();

  final conditionResult = compileExpression(s.condition, ctx).unboxIfNeeded(ctx);

  final rewriteCond = JumpIfFalse.make(conditionResult.scopeFrameOffset, -1);
  final rewritePos = ctx.pushOp(rewriteCond, JumpIfFalse.LEN);

  final elseStatement = s.elseStatement;

  final _initialState = ctx.saveStateForBranch();
  ctx.beginAllocScope();

  final thenResult = compileStatement(s.thenStatement, expectedReturnType, ctx);

  ctx.endAllocScope();

  ctx.resolveBranchStateDiscontinuity(_initialState);

  int? rewriteOut;
  if (elseStatement != null) {
    rewriteOut = ctx.pushOp(JumpConstant.make(-1), JumpConstant.LEN);
  }

  ctx.rewriteOp(rewritePos, JumpIfFalse.make(conditionResult.scopeFrameOffset, ctx.out.length), 0);



  if (elseStatement != null) {
    ctx.restoreStateForBranch(_initialState);
    ctx.beginAllocScope();
    final elseResult = compileStatement(elseStatement, expectedReturnType, ctx);
    ctx.rewriteOp(rewriteOut!, JumpConstant.make(ctx.out.length), 0);
    ctx.endAllocScope();
    ctx.resolveBranchStateDiscontinuity(_initialState);
    ctx.restoreStateForBranch(_initialState);
    ctx.endAllocScope();
    return thenResult | elseResult;
  }

  ctx.endAllocScope();
  ctx.restoreStateForBranch(_initialState);
  return thenResult;
}