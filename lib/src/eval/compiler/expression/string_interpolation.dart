import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileStringInterpolation(
  CompilerContext ctx,
  StringInterpolation str,
) {
  Variable? build;
  for (final element in str.elements) {
    if (element is InterpolationString) {
      final sval = element.value;
      if (sval.isNotEmpty) {
        final el = BuiltinValue(stringval: element.value).push(ctx);
        build = build == null ? el : build.invoke(ctx, '+', [el]).result;
      }
    } else if (element is InterpolationExpression) {
      final V = compileExpression(element.expression, ctx);
      // A `throw` inside an interpolation produces no value; the throw
      // already dominates control flow so nothing further is emitted.
      if (V.type == CoreTypes.never.ref(ctx)) {
        continue;
      }
      Variable vStr;
      if (V.type == CoreTypes.string.ref(ctx)) {
        vStr = V;
      } else {
        vStr = V.invoke(ctx, 'toString', []).result;
      }
      build = build == null ? vStr : build.invoke(ctx, '+', [vStr]).result;
    }
  }

  if (build == null) {
    // Only reachable when every element threw.
    return Variable(CoreTypes.never.ref(ctx));
  }
  return build;
}
