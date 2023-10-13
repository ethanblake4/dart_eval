import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/source_node_wrapper.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileStringInterpolation(
    CompilerContext ctx, StringInterpolation str) {
  Variable? build;
  for (final element in str.elements) {
    if (element is InterpolationString) {
      final _el = BuiltinValue(stringval: element.value).push(ctx);
      build = build == null ? _el : build.invoke(ctx, '+', [_el]).result;
    } else if (element is InterpolationExpression) {
      final V = compileExpression(element.expression, ctx);
      Variable Vstr;
      if (V.type == CoreTypes.string.ref(ctx)) {
        Vstr = V;
      } else {
        Vstr = V.invoke(ctx, 'toString', []).result;
      }
      build = build == null ? Vstr : build.invoke(ctx, '+', [Vstr]).result;
    }
  }

  return build!;
}
