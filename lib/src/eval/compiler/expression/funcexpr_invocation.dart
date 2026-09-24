import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/null_aware.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import '../invocation/call.dart';
import '../invocation/resolver.dart';

/// Compile a [FunctionExpressionInvocation]
Variable compileFunctionExpressionInvocation(
  FunctionExpressionInvocation e,
  CompilerContext ctx,
  TypeRef? bound,
) {
  Variable invoke(Variable fn) => CallResolver(ctx).invokeValue(
    CallSite(
      shape: CallShape.fromArgumentList(
        e.argumentList,
        e.typeArguments?.arguments.toList(),
      ),
      source: e,
      context: bound,
    ),
    callee: fn,
  );

  // `f?.(args)` — a callee on a null-shorted chain (`a?.fn()(args)`) nulls
  // the whole expression; the arguments are not evaluated.
  if (isNullShorted(e.function)) {
    final fn = compileExpression(e.function, ctx);
    return emitNullGuard(ctx, fn, invoke, source: e);
  }

  // Preserve the reference's static type when invoking a named function value.
  if (canReference(e.function)) {
    return CallResolver(ctx).invokeValue(
      CallSite(
        shape: CallShape.fromArgumentList(
          e.argumentList,
          e.typeArguments?.arguments.toList(),
        ),
        source: e,
        context: bound,
      ),
      ref: compileExpressionAsReference(e.function, ctx),
    );
  }
  return invoke(compileExpression(e.function, ctx));
}
