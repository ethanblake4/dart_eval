import 'package:analyzer/dart/ast/ast.dart';
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
    final countPos = p.parameters.where((element) => element.isPositional).length;

    final sig = p.parameters
        .where((element) => element.isNamed)
        .fold('$countPos#', (previousValue, element) => '${element.name!.value() as String}#');

    return signatures[sig] ?? (signatures[sig] = _idx++);
  }
}

void asyncComplete(CompilerContext ctx, int valueOffset) {
  var _completer = ctx.lookupLocal('#completer');
  if (_completer == null) {
    InvokeExternal.make(ctx.bridgeStaticFunctionIndices[ctx.libraryMap['dart:async']!]!['Completer.']!);
    _completer = Variable.alloc(ctx, TypeRef.stdlib(ctx, 'dart:async', 'Completer'));
  }
  ctx.pushOp(ReturnAsync.make(valueOffset, _completer.scopeFrameOffset), Return.LEN);
}
