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
      final _completer = ctx.lookupLocal('#completer')!;
      ctx.pushOp(ReturnAsync.make(-1, _completer.scopeFrameOffset), Return.LEN);
    } else {
      ctx.pushOp(Return.make(-1), Return.LEN);
    }
  } else {
    if (isAsync) {
      final ta = expectedReturnType.type?.specifiedTypeArgs;
      final expected = (ta?.isEmpty ?? true) ? EvalTypes.dynamicType : ta![0];
      var _value = value.boxIfNeeded(ctx);

      if (!_value.type.isAssignableTo(ctx, expected)) {
        if (_value.type
            .isAssignableTo(ctx, TypeRef.stdlib(ctx, 'dart:core', 'Future'))) {
          final vta = _value.type.specifiedTypeArgs;
          final vtype = vta.isEmpty ? EvalTypes.dynamicType : vta[0];
          if (vtype.isAssignableTo(ctx, expected)) {
            final _completer = ctx.lookupLocal('#completer')!;
            final awaitOp = Await.make(
                _completer.scopeFrameOffset, _value.scopeFrameOffset);
            ctx.pushOp(awaitOp, Await.LEN);
            ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
            final result = Variable.alloc(ctx, EvalTypes.dynamicType);
            ctx.pushOp(
                ReturnAsync.make(
                    result.scopeFrameOffset, _completer.scopeFrameOffset),
                ReturnAsync.LEN);
            return StatementInfo(-1, willAlwaysReturn: true);
          }
        }
        throw CompileError(
            'Cannot return ${_value.type} (expected: $expected)');
      }
      final _completer = ctx.lookupLocal('#completer')!;
      ctx.pushOp(
          ReturnAsync.make(
              _value.scopeFrameOffset, _completer.scopeFrameOffset),
          ReturnAsync.LEN);
      return StatementInfo(-1, willAlwaysReturn: true);
    }

    final expected = expectedReturnType.type ?? EvalTypes.dynamicType;
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
    ctx.pushOp(Return.make(value.scopeFrameOffset), Return.LEN);
  }

  return StatementInfo(-1, willAlwaysReturn: true);
}
