import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/async.dart';

StatementInfo doReturn(
  CompilerContext ctx,
  AlwaysReturnType expectedReturnType,
  Variable? value, {
  bool isAsync = false,
  bool skipClassBoxing = false,
}) {
  if (value == null) {
    if (isAsync) {
      final completer = ctx.lookupLocal('#completer')!;
      ctx.pushOp(ReturnAsync(null, completer.ssa));
    } else {
      ctx.pushOp(Return(null));
    }
  } else {
    if (isAsync) {
      final ta = expectedReturnType.type?.specifiedTypeArgs;
      final expected = (ta?.isEmpty ?? true)
          ? CoreTypes.dynamic.ref(ctx)
          : ta![0];
      var value0 = value.boxIfNeeded(ctx);

      if (!value0.type.isAssignableTo(ctx, expected)) {
        if (value0.type.isAssignableTo(ctx, CoreTypes.future.ref(ctx))) {
          final vta = value0.type.specifiedTypeArgs;
          final vtype = vta.isEmpty ? CoreTypes.dynamic.ref(ctx) : vta[0];
          if (vtype.isAssignableTo(ctx, expected)) {
            final completer = ctx.lookupLocal('#completer')!;
            final result = Variable.ssa(
              ctx,
              Await(ctx.svar('await_result'), completer.ssa, value0.ssa),
              CoreTypes.dynamic.ref(ctx),
            );
            ctx.pushOp(ReturnAsync(result.ssa, completer.ssa));
            return StatementInfo(-1, willAlwaysReturn: true);
          }
        }
        throw CompileError(
          'Cannot return ${value0.type} (expected: $expected)',
        );
      }
      final completer = ctx.lookupLocal('#completer')!;
      ctx.pushOp(ReturnAsync(value0.ssa, completer.ssa));
      return StatementInfo(-1, willAlwaysReturn: true);
    }

    final expected = expectedReturnType.type ?? CoreTypes.dynamic.ref(ctx);
    var value0 = value;
    if (!value0.type.isAssignableTo(ctx, expected)) {
      throw CompileError('Cannot return ${value0.type} (expected: $expected)');
    }
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
    ctx.pushOp(Return(value0.ssa));
  }

  return StatementInfo(-1, willAlwaysReturn: true);
}
