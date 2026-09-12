import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';

Variable compileSymbolLiteral(SymbolLiteral l, CompilerContext ctx) {
  var name = l.components.map((t) => t.lexeme).join('.');
  if (name.startsWith('_')) {
    name = name.substring(1);
  }
  final argument = BuiltinValue(stringval: name).push(ctx).boxIfNeeded(ctx);
  return Variable.ssa(
    ctx,
    InvokeExternal(
      ctx.svar('symbol'),
      ctx.bridgeStaticFunctionIndices[ctx
          .libraryMap['dart:core']!]!['Symbol.']!,
      [argument.ssa],
    ),
    CoreTypes.symbol.ref(ctx),
  );
}
