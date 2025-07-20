import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/macros/macro.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

StatementInfo macroBranch(
    CompilerContext ctx, AlwaysReturnType? expectedReturnType,
    {required MacroVariableClosure condition,
    required MacroStatementClosure thenBranch,
    MacroStatementClosure? elseBranch,
    bool resolveStateToThen = false,
    AstNode? source}) {
  ctx.beginAllocScope();
  ctx.enterTypeInferenceContext();

  final conditionResult = condition(ctx).unboxIfNeeded(ctx);
  if (!conditionResult.type.isAssignableTo(ctx, CoreTypes.bool.ref(ctx))) {
    throw CompileError("Conditions must have a static type of 'bool'", source);
  }

  final rewriteCond = JumpIfFalse.make(conditionResult.scopeFrameOffset, -1);
  final rewritePos = ctx.pushOp(rewriteCond, JumpIfFalse.LEN);

  var initialState = ctx.saveState();

  ctx.inferTypes();
  ctx.beginAllocScope();
  final label = CompilerLabel(LabelType.branch, -1, (ctx) {
    ctx.endAllocScopeQuiet();
    if (!resolveStateToThen) {
      //_ctx.resolveBranchStateDiscontinuity(_initialState);
    }
    //_ctx.endAllocScopeQuiet();
    return -1;
  });
  ctx.labels.add(label);
  final thenResult = thenBranch(ctx, expectedReturnType);
  ctx.labels.removeLast();
  ctx.endAllocScope();
  ctx.uninferTypes();

  if (!resolveStateToThen) {
    ctx.resolveBranchStateDiscontinuity(initialState);
  } else {
    initialState = ctx.saveState();
  }

  int? rewriteOut;
  if (elseBranch != null) {
    rewriteOut = ctx.pushOp(JumpConstant.make(-1), JumpConstant.LEN);
  }

  ctx.rewriteOp(rewritePos,
      JumpIfFalse.make(conditionResult.scopeFrameOffset, ctx.out.length), 0);

  if (elseBranch != null) {
    ctx.beginAllocScope();
    final label = CompilerLabel(LabelType.branch, -1, (ctx) {
      ctx.endAllocScope();
      ctx.resolveBranchStateDiscontinuity(initialState);
      ctx.endAllocScope();
      return -1;
    });
    ctx.labels.add(label);
    final elseResult = elseBranch(ctx, expectedReturnType);
    ctx.labels.removeLast();
    ctx.endAllocScope();
    ctx.resolveBranchStateDiscontinuity(initialState);
    ctx.rewriteOp(rewriteOut!, JumpConstant.make(ctx.out.length), 0);
    ctx.endAllocScope();
    return thenResult | elseResult;
  }

  ctx.endAllocScope();

  return thenResult |
      StatementInfo(thenResult.position,
          willAlwaysThrow: false, willAlwaysReturn: false);
}
