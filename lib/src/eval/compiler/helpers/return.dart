import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

StatementInfo doReturn(
    CompilerContext ctx, AlwaysReturnType expectedReturnType, Variable? value,
    {bool isAsync = false}) {
  if (value == null) {
    if (isAsync) {
      final completer = ctx.lookupLocal('#completer')!;
      ctx.pushOp(ReturnAsync.make(-1, completer.scopeFrameOffset), Return.LEN);
    } else {
      ctx.pushOp(Return.make(-1), Return.LEN);
    }
  } else {
    if (isAsync) {
      final ta = expectedReturnType.type?.specifiedTypeArgs;
      final expected =
          (ta?.isEmpty ?? true) ? CoreTypes.dynamic.ref(ctx) : ta![0];
      var value0 = value.boxIfNeeded(ctx);

      if (!value0.type.isAssignableTo(ctx, expected)) {
        if (value0.type.isAssignableTo(ctx, CoreTypes.future.ref(ctx))) {
          final vta = value0.type.specifiedTypeArgs;
          final vtype = vta.isEmpty ? CoreTypes.dynamic.ref(ctx) : vta[0];
          if (vtype.isAssignableTo(ctx, expected)) {
            final completer = ctx.lookupLocal('#completer')!;
            final awaitOp =
                Await.make(completer.scopeFrameOffset, value0.scopeFrameOffset);
            ctx.pushOp(awaitOp, Await.LEN);
            ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
            final result = Variable.alloc(ctx, CoreTypes.dynamic.ref(ctx));
            ctx.pushOp(
                ReturnAsync.make(
                    result.scopeFrameOffset, completer.scopeFrameOffset),
                ReturnAsync.LEN);
            return StatementInfo(-1, willAlwaysReturn: true);
          }
        }
        throw CompileError(
            'Cannot return ${value0.type} (expected: $expected)');
      }
      final completer = ctx.lookupLocal('#completer')!;
      ctx.pushOp(
          ReturnAsync.make(value0.scopeFrameOffset, completer.scopeFrameOffset),
          ReturnAsync.LEN);
      return StatementInfo(-1, willAlwaysReturn: true);
    }

    final expected = expectedReturnType.type ?? CoreTypes.dynamic.ref(ctx);
    var value0 = value;
    if (!value0.type.isAssignableTo(ctx, expected)) {
      throw CompileError('Cannot return ${value0.type} (expected: $expected)');
    }
    if (expected.isUnboxedAcrossFunctionBoundaries &&
        ctx.currentClass == null) {
      value0 = value0.unboxIfNeeded(ctx);
    } else {
      value0 = value0.boxIfNeeded(ctx);
    }
    ctx.pushOp(Return.make(value.scopeFrameOffset), Return.LEN);
  }

  return StatementInfo(-1, willAlwaysReturn: true);
}
