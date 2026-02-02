import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

Variable compileSymbolLiteral(SymbolLiteral l, CompilerContext ctx) {
  var name = l.components.map((t) => t.lexeme).join('.');
  if (name.startsWith('_')) {
    name = name.substring(1);
  }
  BuiltinValue(stringval: name).push(ctx).pushArg(ctx);
  ctx.pushOp(
    InvokeExternal.make(
      ctx.bridgeStaticFunctionIndices[ctx
          .libraryMap['dart:core']!]!['Symbol.']!,
    ),
    InvokeExternal.LEN,
  );
  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  return Variable.alloc(ctx, CoreTypes.symbol.ref(ctx));
}
