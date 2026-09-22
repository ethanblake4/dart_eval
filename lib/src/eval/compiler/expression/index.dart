import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/dot_shorthand.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/null_aware.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';

import '../type.dart';
import '../variable.dart';

Reference compileIndexExpressionAsReference(
  IndexExpression e,
  CompilerContext ctx, {
  TypeRef? bound,
}) {
  final value = e.isCascaded
      ? ctx.cascadeTarget!
      : compileExpression(
          e.realTarget,
          ctx,
          containsLeadingShorthand(e.realTarget) ? bound : null,
        );
  final index = compileExpression(e.index, ctx);
  return IndexedReference(value, index);
}

Variable compileIndexExpression(
  IndexExpression e,
  CompilerContext ctx, [
  TypeRef? bound,
]) {
  // `e1?[e2]` and continuations on a null-shorted chain (`a?.b[0]`): a null
  // target nulls the whole expression — the index is compiled inside the
  // non-null branch so it is not evaluated when the target is null.
  if (isNullShortedSelector(e)) {
    final target = e.isCascaded
        ? ctx.cascadeTarget!
        : compileExpression(
            e.realTarget,
            ctx,
            containsLeadingShorthand(e.realTarget) ? bound : null,
          );
    return emitNullGuard(
      ctx,
      target,
      (t) => IndexedReference(
        t,
        compileExpression(e.index, ctx),
      ).getValue(ctx, e),
      source: e,
    );
  }
  return compileIndexExpressionAsReference(
    e,
    ctx,
    bound: bound,
  ).getValue(ctx);
}
