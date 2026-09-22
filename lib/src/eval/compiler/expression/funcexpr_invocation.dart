import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/null_aware.dart';
import 'package:dart_eval/src/eval/compiler/helpers/closure.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

/// Compile a [FunctionExpressionInvocation]
Variable compileFunctionExpressionInvocation(
  FunctionExpressionInvocation e,
  CompilerContext ctx,
) {
  Variable invoke(Variable fn) => invokeClosure(
    ctx,
    null,
    fn,
    e.argumentList,
    typeArguments: e.typeArguments?.arguments.toList(),
  ).result;

  // `f?.(args)` — a callee on a null-shorted chain (`a?.fn()(args)`) nulls
  // the whole expression; the arguments are not evaluated.
  if (isNullShorted(e.function)) {
    final fn = compileExpression(e.function, ctx);
    return emitNullGuard(ctx, fn, invoke, source: e);
  }

  // Using a reference allows us to potentially optimize to static dispatch, if the exact function
  // is known at compile-time
  if (canReference(e.function)) {
    return invokeClosure(
      ctx,
      compileExpressionAsReference(e.function, ctx),
      null,
      e.argumentList,
      typeArguments: e.typeArguments?.arguments.toList(),
    ).result;
  }
  return invoke(compileExpression(e.function, ctx));
}
