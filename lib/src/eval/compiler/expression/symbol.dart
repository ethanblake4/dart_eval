import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import '../helpers/const.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';

Variable compileSymbolLiteral(SymbolLiteral l, CompilerContext ctx) {
  final name = l.components.map((t) => t.lexeme).join('.');
  final isPrivate = name.startsWith('_');
  final argument = BuiltinValue(stringval: name).push(ctx).boxIfNeeded(ctx);
  final library = isPrivate
      ? BuiltinValue(
          stringval: ctx.libraryUri(ctx.library),
        ).push(ctx).boxIfNeeded(ctx)
      : null;
  final value = Variable.ssa(
    ctx,
    InvokeExternal(
      ctx.svar('symbol'),
      ctx.bridgeStaticFunctionIndices[ctx.libraryMap['dart:core']!]![isPrivate
          ? '_privateSymbolLiteral'
          : 'Symbol.']!,
      [argument.ssa, if (library != null) library.ssa],
    ),
    CoreTypes.symbol.ref(ctx),
  );
  return internConst(ctx, value, value.type);
}
