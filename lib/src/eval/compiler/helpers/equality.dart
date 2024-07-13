import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';

Variable checkNotEqual(CompilerContext ctx, Variable L, Variable R) {
  final cond = Variable.ssa(
      ctx,
      DynamicEquals(ctx.svar('eq_result'), L.ssa, R.ssa),
      CoreTypes.bool.ref(ctx));
  return Variable.ssa(ctx, LogicalNot(cond.ssa, cond.ssa),
      CoreTypes.bool.ref(ctx).copyWith(boxed: false));
}

Variable checkNotNull(CompilerContext ctx, Variable L) {
  final $null = BuiltinValue().push(ctx);
  return checkNotEqual(ctx, L, $null);
}
