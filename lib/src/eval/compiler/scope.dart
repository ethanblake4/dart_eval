import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/async.dart';
import 'context.dart';

void setupAsyncFunction(CompilerContext ctx) {
  ctx.setLocal(
    '#completer',
    Variable.ssa(
      ctx,
      BeginAsync(ctx.svar('#completer')),
      AsyncTypes.completer.ref(ctx),
    ),
  );
}
