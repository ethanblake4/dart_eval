import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/literal.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileAdjacentStrings(CompilerContext ctx, AdjacentStrings str) {
  if (str.strings.every((element) => element is SimpleStringLiteral)) {
    final el = BuiltinValue(
      stringval: str.strings
          .map((e) => (e as SimpleStringLiteral).stringValue)
          .join(''),
    ).push(ctx);
    return el;
  }

  Variable? build;
  for (final string in str.strings) {
    final V = parseLiteral(string, ctx);
    // An interpolation element that throws produces no value.
    if (V.type.isSpec(CoreTypes.never)) {
      continue;
    }
    Variable vStr;
    if (V.type.isSpec(CoreTypes.string)) {
      vStr = V;
    } else {
      vStr = V.invoke(ctx, 'toString', []).result;
    }
    build = build == null ? vStr : build.invoke(ctx, '+', [vStr]).result;
  }

  if (build == null) {
    return Variable(CoreTypes.never.ref(ctx));
  }
  return build;
}
