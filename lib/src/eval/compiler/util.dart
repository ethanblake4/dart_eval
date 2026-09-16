import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

class Pair<T, T2> {
  Pair(this.first, this.second);

  T first;
  T2 second;
}

void asyncComplete(CompilerContext ctx, SSA? value) {
  ctx.pushOp(ReturnAsync(value, ctx.lookupLocal('#completer')!.ssa));
}
