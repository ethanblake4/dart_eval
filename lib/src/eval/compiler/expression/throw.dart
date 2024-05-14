import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

Variable compileThrowExpression(CompilerContext ctx, ThrowExpression e) {
  final V = compileExpression(e.expression, ctx).boxIfNeeded(ctx);
  ctx.pushOp(Throw.make(V.scopeFrameOffset), Throw.LEN);
  return Variable(-1, CoreTypes.never.ref(ctx));
}
