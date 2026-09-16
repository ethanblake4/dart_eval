import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/ir/exception.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import '../context.dart';
import '../errors.dart';
import '../statement/statement.dart';
import '../type.dart';
import '../variable.dart';

/// Returning a Future adopts it after finally. An explicit source `await`
/// remains an Await operation and therefore observes errors before finally.
StatementInfo doAsyncReturn(
  CompilerContext ctx,
  AlwaysReturnType expectedReturnType,
  Variable? value,
) {
  final completer = ctx.lookupLocal('#completer')!.ssa;
  final boxed = value?.boxIfNeeded(ctx);
  if (boxed != null) {
    final arguments = expectedReturnType.type?.specifiedTypeArgs;
    final expected = arguments == null || arguments.isEmpty
        ? CoreTypes.dynamic.ref(ctx)
        : arguments.first;
    var compatible = boxed.type.isAssignableTo(ctx, expected);
    if (!compatible &&
        boxed.type.isAssignableTo(ctx, CoreTypes.future.ref(ctx))) {
      final arguments = boxed.type.specifiedTypeArgs;
      final payload = arguments.isEmpty
          ? CoreTypes.dynamic.ref(ctx)
          : arguments.first;
      compatible = payload.isAssignableTo(ctx, expected);
    }
    if (!compatible) {
      throw CompileError('Cannot return ${boxed.type} (expected: $expected)');
    }
  }
  if (ctx.exceptionDepth == 0) {
    ctx.pushOp(ReturnAsync(boxed?.ssa, completer));
  } else {
    final slot = boxed == null
        ? null
        : ExceptionSlot(
            ctx.svar('async_return').name,
            MachineRepresentation.object,
          );
    final result = slot == null ? null : ctx.svar('async_return_value');
    final continuation = BasicBlock<Operation>([
      if (slot != null) LoadExceptionSlot(result!, slot),
      ReturnAsync(result, completer),
    ], label: ctx.label('async_return_completion'));
    if (slot != null) ctx.pushOp(StoreExceptionSlot(slot, boxed!.ssa));
    ctx.pushOp(CompleteJump(continuation.label!, 0));
    final tail = ctx.flushBlock();
    ctx.builder.float(continuation);
    ctx.builder.link(tail, continuation);
  }
  return StatementInfo(willAlwaysReturn: true);
}
