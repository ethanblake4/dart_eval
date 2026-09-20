import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/async.dart';
import 'context.dart';

void setupAsyncFunction(CompilerContext ctx, {TypeRef? returnType}) {
  final future = CoreTypes.future.ref(ctx);
  final runtimeType =
      returnType != null && returnType.hasSameDeclarationAs(future)
      ? returnType
      : future.copyWith(specifiedTypeArgs: [CoreTypes.dynamic.ref(ctx)]);
  ctx.setLocal(
    '#completer',
    Variable.ssa(
      ctx,
      BeginAsync(
        ctx.svar('#completer'),
        runtimeTypeId: runtimeType.runtimeTypeId(ctx),
      ),
      AsyncTypes.completer.ref(ctx),
    ),
  );
}
