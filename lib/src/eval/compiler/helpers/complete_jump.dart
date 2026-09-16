import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/ir/exception.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

void completeJump(
  CompilerContext ctx,
  BasicBlock<Operation> target,
  int targetDepth,
) {
  final trampoline = BasicBlock<Operation>([
    for (final scope in ctx.locals)
      for (final binding in scope.values)
        if (binding.captureCellSlot case final slot?)
          LoadExceptionSlot(binding.captureCell!, slot)
        else if (binding.exceptionSlot case final slot?)
          LoadExceptionSlot(binding.ssa, slot),
    Jump(target.label!),
  ], label: ctx.label('jump_completion'));
  ctx.pushOp(CompleteJump(trampoline.label!, targetDepth));
  final tail = ctx.flushBlock();
  ctx.builder.float(trampoline);
  ctx.builder.link(tail, trampoline);
  ctx.builder.link(trampoline, target);
}
