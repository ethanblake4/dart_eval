import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

Variable compileRethrowExpression(CompilerContext ctx, RethrowExpression e) {
  ctx.pushOp(Throw.make(ctx.caughtExceptions.last.scopeFrameOffset), Throw.LEN);
  return Variable(-1, CoreTypes.never.ref(ctx));
}
