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
}) {
  ctx.beginAllocScope(requireNonlinearAccess: true);

  if (initialization != null) {
    initialization(ctx);
  }

  JumpIfFalse? rewriteCond;
  int? rewritePos;
  Variable? conditionResult;
  final loopStart = ctx.out.length;

  ctx.beginAllocScope(requireNonlinearAccess: true);

  if (!alwaysLoopOnce && condition != null) {
    conditionResult = condition(ctx).unboxIfNeeded(ctx);
    rewriteCond = JumpIfFalse.make(conditionResult.scopeFrameOffset, -1);
    rewritePos = ctx.pushOp(rewriteCond, JumpIfFalse.LEN);
  }

  var pops = ctx.peekAllocPops();

  final statementResult = body(ctx, expectedReturnType);
  if (!(statementResult.willAlwaysThrow || statementResult.willAlwaysReturn)) {
    if (update != null) {
      update(ctx);
    }
    ctx.resolveNonlinearity(2);
    ctx.endAllocScope();

    if (alwaysLoopOnce && condition != null) {
      conditionResult = condition(ctx).unboxIfNeeded(ctx);
      rewriteCond = JumpIfFalse.make(conditionResult.scopeFrameOffset, -1);
      rewritePos = ctx.pushOp(rewriteCond, JumpIfFalse.LEN);
    }

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
