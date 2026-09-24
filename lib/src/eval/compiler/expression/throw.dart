import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileThrowExpression(CompilerContext ctx, ThrowExpression e) {
  final V = compileExpression(e.expression, ctx);
  // Give the Never-typed result a (dead) slot so argument lists and other
  // consumers that blindly read `.ssa` keep working; the throw dominates
  // so the value is never actually used.
  final result = Variable.never(ctx);
  // A nested throw already terminated the block; emitting a second Throw
  // lands it in detached dead code.
  if (!V.type.isSpec(CoreTypes.never)) {
    ctx.pushOp(Throw(V.boxIfNeeded(ctx).ssa));
  }
  return result;
}
