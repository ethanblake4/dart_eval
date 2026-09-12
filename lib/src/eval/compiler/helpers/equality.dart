import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

Variable checkNotEqual(CompilerContext ctx, Variable L, Variable R) {
  final cond = Variable.ssa(
    ctx,
    DynamicEquals(
      ctx.svar('equal'),
      L.boxIfNeeded(ctx).ssa,
      R.boxIfNeeded(ctx).ssa,
    ),
    CoreTypes.bool.ref(ctx).copyWith(boxed: false),
  );
  return Variable.ssa(
    ctx,
    LogicalNot(ctx.svar('not_equal'), cond.ssa),
    CoreTypes.bool.ref(ctx).copyWith(boxed: false),
  );
}

Variable checkNotNull(CompilerContext ctx, Variable L) {
  final $null = BuiltinValue().push(ctx);
  return checkNotEqual(ctx, L, $null);
}
