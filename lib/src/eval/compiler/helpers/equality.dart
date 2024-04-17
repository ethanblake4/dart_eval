import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

Variable checkNotEqual(CompilerContext ctx, Variable L, Variable R) {
  ctx.pushOp(CheckEq.make(L.scopeFrameOffset, R.scopeFrameOffset), CheckEq.LEN);
  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  final cond = Variable.alloc(ctx, CoreTypes.bool.ref(ctx));
  ctx.pushOp(LogicalNot.make(cond.scopeFrameOffset), LogicalNot.LEN);
  return Variable.alloc(ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
}

Variable checkNotNull(CompilerContext ctx, Variable L) {
  final $null = BuiltinValue().push(ctx);
  return checkNotEqual(ctx, L, $null);
}
