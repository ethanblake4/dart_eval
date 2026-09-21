import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

Variable compileThrowExpression(CompilerContext ctx, ThrowExpression e) {
  final V = compileExpression(e.expression, ctx);
  // Give the Never-typed result a (dead) slot so argument lists and other
  // consumers that blindly read `.ssa` keep working; the throw dominates
  // so the value is never actually used.
  final dead = ctx.svar('never');
  ctx.pushOp(LoadNull(dead));
  // A nested throw already terminated the block; emitting a second Throw
  // lands it in detached dead code.
  if (V.type != CoreTypes.never.ref(ctx)) {
    ctx.pushOp(Throw(V.boxIfNeeded(ctx).ssa));
  }
  return Variable.of(ctx, dead, CoreTypes.never.ref(ctx));
}
