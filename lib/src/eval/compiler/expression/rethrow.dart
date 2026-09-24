import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileRethrowExpression(CompilerContext ctx, RethrowExpression e) {
  final result = Variable.never(ctx);
  ctx.pushOp(Rethrow(ctx.caughtExceptionTargets.last));
  return result;
}
