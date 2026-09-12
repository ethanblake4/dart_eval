import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/macro.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

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
  initialization?.call(ctx);
  final initialState = ctx.saveState();
  final header = BasicBlock<Operation>([], label: ctx.label('loop_header'));
  final bodyBlock = BasicBlock<Operation>([], label: ctx.label('loop_body'));
  final exit = BasicBlock<Operation>([], label: ctx.label('loop_exit'));
  final updateBlock = update != null && !updateBeforeBody
      ? BasicBlock<Operation>([], label: ctx.label('loop_update'))
      : null;
  final continueTarget = updateBlock ?? header;
  ctx.flushBlock();
  final parent = ctx.builder;
  ctx.builder = ctx.builder.then(alwaysLoopOnce ? bodyBlock : header);

  if (!alwaysLoopOnce) {
    if (condition != null) {
      final value = condition(ctx).unboxIfNeeded(ctx);
      ctx.pushOp(JumpIfFalse(value.ssa, exit.label!));
      ctx.flushBlock();
      ctx.builder = ctx.builder.split(bodyBlock, exit).block(0);
    } else {
      ctx.builder = ctx.builder.then(bodyBlock);
    }
  }

  ctx.beginAllocScope();
  if (updateBeforeBody) update?.call(ctx);
  final label = CompilerLabel(
    LabelType.loop,
    -1,
    (ctx) {
      ctx.resolveBranchStateDiscontinuity(initialState);
      return -1;
    },
    breakTarget: exit,
    continueTarget: continueTarget,
  );
  ctx.labels.add(label);
  final result = body(ctx, expectedReturnType);
  ctx.labels.removeLast();
  ctx.endAllocScope();
  if (!result.willAlwaysReturn &&
      !result.willAlwaysThrow &&
      !result.willAlwaysBreak &&
      !ctx.blockEndsControlFlow) {
    ctx.resolveBranchStateDiscontinuity(initialState);
    ctx.pushOp(Jump(continueTarget.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, continueTarget);
  } else if (ctx.blockCode.isNotEmpty) {
    ctx.flushBlock();
  }

  // A continue edge can reach the update/condition even if the body never
  // falls through. Emit these blocks independently of the body's exit flags.
  if (updateBlock?.id != null) {
    ctx.restoreState(initialState);
    ctx.builder = BasicBlockBuilder(ctx.activeGraph, [updateBlock!], parent);
    update!.call(ctx);
    ctx.resolveBranchStateDiscontinuity(initialState);
    ctx.pushOp(Jump(header.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, header);
  }
  if (alwaysLoopOnce && header.id != null) {
    ctx.restoreState(initialState);
    ctx.builder = BasicBlockBuilder(ctx.activeGraph, [header], parent);
    if (condition != null) {
      final value = condition(ctx).unboxIfNeeded(ctx);
      ctx.pushOp(JumpIfFalse(value.ssa, exit.label!));
      final tail = ctx.flushBlock();
      ctx.builder.link(tail, exit);
      ctx.builder.link(tail, bodyBlock);
    } else {
      ctx.pushOp(Jump(bodyBlock.label!));
      final tail = ctx.flushBlock();
      ctx.builder.link(tail, bodyBlock);
    }
  }

  ctx.builder.float(exit);
  ctx.builder = BasicBlockBuilder(ctx.activeGraph, [exit], parent);
  ctx.restoreState(initialState);
  after?.call(ctx);
  ctx.endAllocScope();
  return alwaysLoopOnce
      ? result.copyWith(willAlwaysBreak: false)
      : StatementInfo(result.position);
}
