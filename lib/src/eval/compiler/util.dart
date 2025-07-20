import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

class Pair<T, T2> {
  Pair(this.first, this.second);

  T first;
  T2 second;
}

class FunctionSignaturePool {
  FunctionSignaturePool();

  int _idx = 0;
  final Map<String, int> signatures = {};

  int getSignature(FormalParameterList p) {
    final countPos =
        p.parameters.where((element) => element.isPositional).length;

    final sig = p.parameters.where((element) => element.isNamed).fold(
        '$countPos#', (previousValue, element) => '${element.name!.lexeme}#');

    return signatures[sig] ?? (signatures[sig] = _idx++);
  }
}

void asyncComplete(CompilerContext ctx, int valueOffset) {
  var completer = ctx.lookupLocal('#completer');
  if (completer == null) {
    InvokeExternal.make(ctx.bridgeStaticFunctionIndices[
        ctx.libraryMap['dart:async']!]!['Completer.']!);
    completer = Variable.alloc(ctx, AsyncTypes.completer.ref(ctx));
  }
  ctx.pushOp(
      ReturnAsync.make(valueOffset, completer.scopeFrameOffset), Return.LEN);
}
