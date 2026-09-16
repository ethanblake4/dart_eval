import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

Variable compileRethrowExpression(CompilerContext ctx, RethrowExpression e) {
  ctx.pushOp(Rethrow(ctx.caughtExceptionTargets.last));
  return Variable(CoreTypes.never.ref(ctx));
}
