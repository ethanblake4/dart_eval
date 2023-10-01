import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/macro.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

StatementInfo macroBranch(CompilerContext ctx, AlwaysReturnType? expectedReturnType,
    {required MacroVariableClosure condition,
    required MacroStatementClosure thenBranch,
    MacroStatementClosure? elseBranch}) {
  ctx.beginAllocScope();
  final conditionResult = condition(ctx).unboxIfNeeded(ctx);

  final rewriteCond = JumpIfFalse.make(conditionResult.scopeFrameOffset, -1);
  final rewritePos = ctx.pushOp(rewriteCond, JumpIfFalse.LEN);

  final _initialState = ctx.saveState();

  ctx.beginAllocScope();
  final thenResult = thenBranch(ctx, expectedReturnType);
  ctx.endAllocScope();

  ctx.resolveBranchStateDiscontinuity(_initialState);

  int? rewriteOut;
  if (elseBranch != null) {
    rewriteOut = ctx.pushOp(JumpConstant.make(-1), JumpConstant.LEN);
  }

  ctx.rewriteOp(rewritePos, JumpIfFalse.make(conditionResult.scopeFrameOffset, ctx.out.length), 0);

  if (elseBranch != null) {
    ctx.beginAllocScope();
    final elseResult = elseBranch(ctx, expectedReturnType);
    ctx.endAllocScope();
    ctx.resolveBranchStateDiscontinuity(_initialState);
    ctx.rewriteOp(rewriteOut!, JumpConstant.make(ctx.out.length), 0);
    ctx.endAllocScope();
    return thenResult | elseResult;
  }

  ctx.endAllocScope();

  return thenResult | StatementInfo(thenResult.position, willAlwaysThrow: false, willAlwaysReturn: false);
}
