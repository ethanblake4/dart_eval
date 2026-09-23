import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/const.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import '../invocation/resolver.dart';

Variable compileStringInterpolation(
  CompilerContext ctx,
  StringInterpolation str,
) {
  Variable? build;
  var allConst = true;
  for (final element in str.elements) {
    if (element is InterpolationString) {
      final sval = element.value;
      if (sval.isNotEmpty) {
        final el = BuiltinValue(stringval: element.value).push(ctx);
        build = build == null ? el : CallResolver(ctx).invokeOperator(build, '+', [el]).result;
      }
    } else if (element is InterpolationExpression) {
      final V = compileExpression(element.expression, ctx);
      // A `throw` inside an interpolation produces no value; the throw
      // already dominates control flow so nothing further is emitted.
      if (V.type.isSpec(CoreTypes.never)) {
        continue;
      }
      if (!V.isConst) allConst = false;
      Variable vStr;
      if (V.type.isSpec(CoreTypes.string)) {
        vStr = V;
      } else {
        vStr = CallResolver(ctx).invokeOperator(V, 'toString', []).result;
      }
      build = build == null ? vStr : CallResolver(ctx).invokeOperator(build, '+', [vStr]).result;
    }
  }

  if (build == null) {
    // Only reachable when every element threw.
    return Variable(CoreTypes.never.ref(ctx));
  }
  // An interpolation in a const context — or one whose interpolated
  // values are all consts — is itself constant and canonicalized.
  if (str.inConstantContext || allConst) {
    final boxed = build.boxIfNeeded(ctx);
    return internConst(ctx, boxed, boxed.type);
  }
  return build;
}
