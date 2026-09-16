import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/macros/macro.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

StatementInfo macroBranch(
  CompilerContext ctx,
  AlwaysReturnType? expectedReturnType, {
  required MacroVariableClosure condition,
  required MacroStatementClosure thenBranch,
  MacroStatementClosure? elseBranch,
  bool resolveStateToThen = false,
  AstNode? source,
  bool testNullish = false,
}) {
  ctx.beginScope();
  ctx.enterTypeInferenceContext();

  final conditionResult = condition(ctx).unboxIfNeeded(ctx);
  if (!testNullish &&
      !conditionResult.type.isAssignableTo(ctx, CoreTypes.bool.ref(ctx))) {
    throw CompileError("Conditions must have a static type of 'bool'", source);
  }

  final thenBlock = BasicBlock<Operation>([], label: ctx.label('if_true'));
  final elseBlock = BasicBlock<Operation>([], label: ctx.label('if_false'));
  final endBlock = BasicBlock<Operation>([], label: ctx.label('if_end'));
  ctx.pushOp(
    testNullish
        ? JumpIfNonNull(conditionResult.ssa, elseBlock.label!)
        : JumpIfFalse(conditionResult.ssa, elseBlock.label!),
  );
  ctx.flushBlock();
  final branches = ctx.builder.split(thenBlock, elseBlock);
  final initialState = ctx.saveState();

  ctx.builder = branches.block(0);
  ctx.inferTypes();
  ctx.beginScope();
  final thenResult = thenBranch(ctx, expectedReturnType);
  ctx.endScope();
  ctx.uninferTypes();
  if (!thenResult.willAlwaysReturn &&
      !thenResult.willAlwaysThrow &&
      !thenResult.willAlwaysBreak &&
      !ctx.blockEndsControlFlow) {
    ctx.resolveBranchStateDiscontinuity(initialState);
    ctx.pushOp(Jump(endBlock.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, endBlock);
  } else if (ctx.blockCode.isNotEmpty) {
    ctx.flushBlock();
  }
  final thenState = ctx.saveState();
  ctx.restoreState(initialState);

  ctx.builder = branches.block(1);
  ctx.beginScope();
  final elseResult =
      elseBranch?.call(ctx, expectedReturnType) ?? StatementInfo();
  ctx.endScope();
  if (!elseResult.willAlwaysReturn &&
      !elseResult.willAlwaysThrow &&
      !elseResult.willAlwaysBreak &&
      !ctx.blockEndsControlFlow) {
    ctx.resolveBranchStateDiscontinuity(initialState);
    ctx.pushOp(Jump(endBlock.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, endBlock);
  } else if (ctx.blockCode.isNotEmpty) {
    ctx.flushBlock();
  }
  // Select the join without introducing edges from terminated branches.
  ctx.builder = BasicBlockBuilder(ctx.activeGraph, [endBlock], branches);
  ctx.builder.float(endBlock);
  ctx.restoreState(resolveStateToThen ? thenState : initialState);
  ctx.endScope();
  return thenResult | elseResult;
}
