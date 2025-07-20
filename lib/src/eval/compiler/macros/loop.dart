import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/macro.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

StatementInfo macroLoop(
  CompilerContext ctx,
  AlwaysReturnType? expectedReturnType, {
  required MacroStatementClosure body,
  MacroClosure? initialization,
  MacroVariableClosure? condition,
  MacroClosure? update,
  MacroClosure? after,
  bool alwaysLoopOnce = false,
  bool updateBeforeBody = false,
}) {
  ctx.beginAllocScope();

  if (initialization != null) {
    initialization(ctx);
  }

  /// Make a save-state of the box/unbox status of all locals
  final save = ctx.saveState();

  JumpIfFalse? rewriteCond;
  int? rewritePos;
  Variable? conditionResult;
  ContextSaveState? conditionSaveState;
  var loopStart = ctx.out.length;

  ctx.beginAllocScope();

  if (!alwaysLoopOnce && condition != null) {
    conditionResult = condition(ctx).unboxIfNeeded(ctx);
    conditionSaveState = ctx.saveState();
    rewriteCond = JumpIfFalse.make(conditionResult.scopeFrameOffset, -1);
    rewritePos = ctx.pushOp(rewriteCond, JumpIfFalse.LEN);
  }

  var pops = ctx.peekAllocPops();

  if (update != null && updateBeforeBody) {
    update(ctx);
  }

  final label = CompilerLabel(LabelType.loop, loopStart, (ctx) {
    ctx.endAllocScopeQuiet();

    /// Box/unbox variables that were declared outside the loop and changed in
    /// the loop body to match the save state
    ctx.resolveBranchStateDiscontinuity(save);

    if (conditionSaveState != null) {
      ctx.restoreBoxingState(conditionSaveState);
      ctx.resolveBranchStateDiscontinuity(save);
    }

    ctx.endAllocScopeQuiet();
    final result = ctx.pushOp(JumpConstant.make(-1), JumpConstant.LEN);
    return result;
  });

  ctx.labels.add(label);
  final statementResult = body(ctx, expectedReturnType);
  ctx.labels.removeLast();

  if (!(statementResult.willAlwaysThrow || statementResult.willAlwaysReturn)) {
    if (update != null && !updateBeforeBody) {
      update(ctx);
    }

    /// For do-while type loops, execute the condition check after the body
    if (alwaysLoopOnce && condition != null) {
      conditionResult = condition(ctx).unboxIfNeeded(ctx);
      rewriteCond = JumpIfFalse.make(conditionResult.scopeFrameOffset, -1);
      rewritePos = ctx.pushOp(rewriteCond, JumpIfFalse.LEN);
    }

    ctx.endAllocScope();

    /// Box/unbox variables that were declared outside the loop and changed in
    /// the loop body to match the save state
    ctx.resolveBranchStateDiscontinuity(save);

    ctx.pushOp(JumpConstant.make(loopStart), JumpConstant.LEN);
  } else {
    pops = 0;
  }

  if (rewritePos != null) {
    ctx.rewriteOp(rewritePos,
        JumpIfFalse.make(conditionResult!.scopeFrameOffset, ctx.out.length), 0);
  }

  if (conditionSaveState != null) {
    ctx.restoreBoxingState(conditionSaveState);
    ctx.resolveBranchStateDiscontinuity(save);
  }

  if (after != null) {
    after(ctx);
  }

  ctx.endAllocScope(popAdjust: pops);
  ctx.resolveLabel(label);

  return statementResult;
}
