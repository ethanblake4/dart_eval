import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/ir/exception.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/async.dart';
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
  TypeRef expectedReturnType,
  Variable? value,
) {
  final completer = ctx.lookupLocal('#completer')!.ssa;
  final boxed = value?.boxIfNeeded(ctx);
  if (boxed != null) {
    final arguments = expectedReturnType.typeArguments;
    final expected = arguments.isEmpty
        ? CoreTypes.dynamic.ref(ctx)
        : arguments.first;
    var compatible = boxed.type.isAssignableTo(ctx, expected);
    if (!compatible &&
        boxed.type.isAssignableTo(ctx, CoreTypes.future.ref(ctx))) {
      final arguments = boxed.type.typeArguments;
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

/// Builds the preamble for an `async` function body: creates the completer,
/// wraps the body in a catch handler that completes with error, and completes
/// with `null` if the body falls off the end.
void setupAsyncFunction(CompilerContext ctx, {TypeRef? returnType}) {
  final future = CoreTypes.future.ref(ctx);
  final runtimeType = returnType != null && sameDeclaration(returnType, future)
      ? returnType
      : future.copyWith(arguments: [CoreTypes.dynamic.ref(ctx)]);
  ctx.setLocal(
    '#completer',
    Variable.ssa(
      ctx,
      BeginAsync(
        ctx.svar('#completer'),
        runtimeTypeId: ctx.runtimeTypes.idOf(runtimeType),
      ),
      AsyncTypes.completer.ref(ctx),
    ),
  );
}

/// Call `Completer.complete` for an async function at the end of its body.
void asyncComplete(CompilerContext ctx, SSA? value) {
  ctx.pushOp(ReturnAsync(value, ctx.lookupLocal('#completer')!.ssa));
}
