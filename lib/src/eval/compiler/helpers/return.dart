import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/async.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

StatementInfo doReturn(
    CompilerContext ctx, AlwaysReturnType expectedReturnType, Variable? value,
    {bool isAsync = false}) {
  if (value == null) {
    if (isAsync) {
      final _completer = ctx.lookupLocal('#completer')!;
      ctx.pushOp(ReturnAsync(null, _completer.ssa));
    } else {
      ctx.pushOp(Return(null));
    }
  } else {
    if (isAsync) {
      final ta = expectedReturnType.type?.specifiedTypeArgs;
      final expected =
          (ta?.isEmpty ?? true) ? CoreTypes.dynamic.ref(ctx) : ta![0];
      var _value = value.boxIfNeeded(ctx);

      if (!_value.type.isAssignableTo(ctx, expected)) {
        if (_value.type.isAssignableTo(ctx, CoreTypes.future.ref(ctx))) {
          final vta = _value.type.specifiedTypeArgs;
          final vtype = vta.isEmpty ? CoreTypes.dynamic.ref(ctx) : vta[0];
          if (vtype.isAssignableTo(ctx, expected)) {
            final _completer = ctx.lookupLocal('#completer')!;
            final result = Variable.ssa(
                ctx,
                Await(ctx.svar('async_result'), _completer.ssa, _value.ssa),
                expected);
            ctx.pushOp(ReturnAsync(result.ssa, _completer.ssa));
            return StatementInfo(-1, willAlwaysReturn: true);
          }
        }
        throw CompileError(
            'Cannot return ${_value.type} (expected: $expected)');
      }
      final _completer = ctx.lookupLocal('#completer')!;
      ctx.pushOp(ReturnAsync(_value.ssa, _completer.ssa));
      return StatementInfo(-1, willAlwaysReturn: true);
    }

    final expected = expectedReturnType.type ?? CoreTypes.dynamic.ref(ctx);
    var _value = value;
    if (!_value.type.isAssignableTo(ctx, expected)) {
      throw CompileError('Cannot return ${_value.type} (expected: $expected)');
    }
    if (expected.isUnboxedAcrossFunctionBoundaries &&
        ctx.currentClass == null) {
      _value = _value.unboxIfNeeded(ctx);
    } else {
      _value = _value.boxIfNeeded(ctx);
    }
    ctx.pushOp(Return(value.ssa));
  }

  return StatementInfo(-1, willAlwaysReturn: true);
}
