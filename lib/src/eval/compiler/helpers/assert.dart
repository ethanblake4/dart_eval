import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

void doAssert(CompilerContext ctx, Variable condition, Variable message) {
  ctx.pushOp(Assert(condition.ssa, message.ssa));
}
