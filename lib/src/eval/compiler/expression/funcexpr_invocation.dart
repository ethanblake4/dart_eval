import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/closure.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

/// Compile a [FunctionExpressionInvocation]
Variable compileFunctionExpressionInvocation(
    FunctionExpressionInvocation e, CompilerContext ctx) {
  Reference? target;
  Variable? fallback;

  // Using a reference allows us to potentially optimize to static dispatch, if the exact function
  // is known at compile-time
  if (canReference(e.function)) {
    target = compileExpressionAsReference(e.function, ctx);
  } else {
    fallback = compileExpression(e.function, ctx);
  }

  return invokeClosure(ctx, target, fallback, e.argumentList).result;
}
