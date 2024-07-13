import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
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

void asyncComplete(CompilerContext ctx, SSA? value) {
  var _completer = ctx.lookupLocal('#completer');
  if (_completer == null) {
    _completer = Variable.ssa(
        ctx,
        InvokeExternal(
            ctx.svar('#completer'),
            ctx.bridgeStaticFunctionIndices[ctx.libraryMap['dart:async']!]![
                'Completer.']!,
            []),
        AsyncTypes.completer.ref(ctx));
  }
  ctx.pushOp(ReturnAsync(value, _completer.ssa));
}
