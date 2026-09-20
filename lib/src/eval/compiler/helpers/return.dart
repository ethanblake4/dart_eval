import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'async.dart';
import 'package:dart_eval/src/eval/ir/exception.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart'
    show MachineRepresentation, representationForType;

StatementInfo doReturn(
  CompilerContext ctx,
  AlwaysReturnType expectedReturnType,
  Variable? value, {
  bool isAsync = false,
  bool skipClassBoxing = false,
}) {
  if (isAsync) return doAsyncReturn(ctx, expectedReturnType, value);
  if (expectedReturnType.type == CoreTypes.voidType.ref(ctx)) value = null;
  if (value == null) {
    if (ctx.exceptionDepth > 0) {
      final continuation = BasicBlock<Operation>([
        Return(null),
      ], label: ctx.label('return_completion'));
      ctx.pushOp(CompleteJump(continuation.label!, 0));
      final tail = ctx.flushBlock();
      ctx.builder.float(continuation);
      ctx.builder.link(tail, continuation);
    } else {
      ctx.pushOp(Return(null));
    }
  } else {
    final expected = expectedReturnType.type ?? CoreTypes.dynamic.ref(ctx);
    var value0 = value;
    final unboxedResult =
        expected.isUnboxedAcrossFunctionBoundaries &&
        (ctx.currentClass == null || skipClassBoxing);
    value0 = convertForAssignment(
      ctx,
      value0,
      expected,
      representation: unboxedResult
          ? representationForType(expected.copyWith(boxed: false))
          : MachineRepresentation.object,
      description: 'Cannot return ${value0.type} (expected: $expected)',
    );
    if (expected.isUnboxedAcrossFunctionBoundaries &&
        // Return types must be boxed when returning from instance methods, even if
        // the return type can be unboxed across function boundaries, because
        // the method may be called in a dynamic context where we have no information
        // about the expected return type.
        // We skip this if the skipClassBoxing flag is set, which is used
        // for operators as they can be statically guaranteed to return an unboxed type.
        (ctx.currentClass == null || skipClassBoxing)) {
      value0 = value0.unboxIfNeeded(ctx);
    } else {
      value0 = value0.boxIfNeeded(ctx);
    }
    if (ctx.exceptionDepth == 0) {
      ctx.pushOp(Return(value0.ssa));
    } else {
      final slot = ExceptionSlot(
        ctx.svar('completion_slot').name,
        ctx.functionSignatures[ctx.currentFunctionId]?.result ??
            representationForType(value0.type),
      );
      final continuation = BasicBlock<Operation>([
        LoadExceptionSlot(ctx.svar('completion_value'), slot),
      ], label: ctx.label('return_completion'));
      final loaded = continuation.code.single.writesTo!;
      continuation.code.add(Return(loaded));
      ctx.pushOp(StoreExceptionSlot(slot, value0.ssa));
      ctx.pushOp(CompleteJump(continuation.label!, 0));
      final tail = ctx.flushBlock();
      ctx.builder.float(continuation);
      ctx.builder.link(tail, continuation);
    }
  }

  return StatementInfo(willAlwaysReturn: true);
}
