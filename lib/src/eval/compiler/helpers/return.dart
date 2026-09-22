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

/// Marks the current block as unreachable past this point — used when an
/// expression's value is Never-typed. When the expression already emitted a
/// terminator (`throw`) the block is closed and nothing more is needed; when
/// it merely carries the Never type (a call or getter declared `Never`) its
/// own ops ran but left the block open, so an unreachable Return is emitted
/// to keep the block properly terminated.
StatementInfo markNeverTerminates(CompilerContext ctx) {
  if (!ctx.blockEndsControlFlow) {
    ctx.pushOp(Return(null));
  }
  return StatementInfo(willAlwaysThrow: true);
}

StatementInfo doReturn(
  CompilerContext ctx,
  AlwaysReturnType expectedReturnType,
  Variable? value, {
  bool isAsync = false,
  bool skipClassBoxing = false,
}) {
  // A Never-typed value cannot produce a result — return it anyway so a
  // `=> f()` where `f` returns `Never` still terminates the block.
  if (value != null && value.type == CoreTypes.never.ref(ctx)) {
    if (!ctx.blockEndsControlFlow) {
      final isVoid =
          expectedReturnType.type == CoreTypes.voidType.ref(ctx);
      ctx.pushOp(
        Return(isVoid ? null : value.boxIfNeeded(ctx).ssa),
      );
    }
    return StatementInfo(willAlwaysThrow: true);
  }
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
    // Closures declare an `object` result slot in their function signature,
    // so their returns stay boxed even when the type could travel unboxed.
    final unboxedResult =
        expected.isUnboxedAcrossFunctionBoundaries &&
        ctx.closureDepth == 0 &&
        ((ctx.currentClass == null && ctx.currentExtension == null) ||
            skipClassBoxing);
    value0 = convertForAssignment(
      ctx,
      value0,
      expected,
      representation: unboxedResult
          ? representationForType(expected.copyWith(boxed: false))
          : MachineRepresentation.object,
      description: 'Cannot return ${value0.type} (expected: $expected)',
    );
    if (unboxedResult) {
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
