import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/dot_shorthand.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/null_aware.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';

import '../type.dart';
import '../variable.dart';
import '../invocation/resolver.dart';

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
  return compileIndexReference(e, ctx, value);
}

/// Compile the index once, after resolving its operator's parameter context.
IndexedReference compileIndexReference(
  IndexExpression expression,
  CompilerContext ctx,
  Variable receiver,
) {
  final pin = extensionPinOf(ctx, expression.realTarget, receiver.type);
  final context = CallResolver(ctx).operatorParameterType(
    receiver.type,
    expression.inGetterContext() ? '[]' : '[]=',
    0,
    source: expression,
    extensionPin: pin,
  );
  return IndexedReference(
    receiver,
    compileExpression(expression.index, ctx, context),
    lexicalSuper: expression.realTarget is SuperExpression,
    extensionPin: pin,
  );
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
      (t) => compileIndexReference(e, ctx, t).getValue(ctx, e),
      source: e,
      receiverExpression: e.realTarget,
      narrow: e.question != null,
    );
  }
  return compileIndexExpressionAsReference(e, ctx, bound: bound).getValue(ctx);
}
