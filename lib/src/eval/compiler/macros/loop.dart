import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/macro.dart';
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
  /// Make a save-state of the box/unbox status of all locals
  final save = ctx.saveState();

  /// Create a nonlinear access context (all new variables will be unboxed)
  ctx.beginAllocScope(requireNonlinearAccess: true);

  if (initialization != null) {
    initialization(ctx);
  }

  JumpIfFalse? rewriteCond;
  int? rewritePos;
  Variable? conditionResult;
  var loopStart = ctx.out.length;

  ctx.beginAllocScope(requireNonlinearAccess: true);

  if (!alwaysLoopOnce && condition != null) {
    conditionResult = condition(ctx).unboxIfNeeded(ctx);
    rewriteCond = JumpIfFalse.make(conditionResult.scopeFrameOffset, -1);
    rewritePos = ctx.pushOp(rewriteCond, JumpIfFalse.LEN);
  }

  var pops = ctx.peekAllocPops();

  if (update != null && updateBeforeBody) {
    update(ctx);
  }

  final statementResult = body(ctx, expectedReturnType);
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

    /// Re-unbox any variables declared in the loop or initializer
    /// that were boxed in the loop body
    ctx.resolveNonlinearity(2);
    ctx.endAllocScope();

    /// Box/unbox variables that were declared outside the loop and changed in
    /// the loop body to match the save state
    ctx.resolveBranchStateDiscontinuity(save);

    ctx.pushOp(JumpConstant.make(loopStart), JumpConstant.LEN);
  } else {
    pops = 0;
  }

  if (rewritePos != null) {
    ctx.rewriteOp(rewritePos, JumpIfFalse.make(conditionResult!.scopeFrameOffset, ctx.out.length), 0);
  }

  if (after != null) {
    after(ctx);
  }

  ctx.endAllocScope(popAdjust: pops);

  return statementResult;
}
