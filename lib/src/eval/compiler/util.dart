import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

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
    final countPos = p.parameters
        .where((element) => element.isPositional)
        .length;

    final sig = p.parameters
        .where((element) => element.isNamed)
        .fold(
          '$countPos#',
          (previousValue, element) => '${element.name!.lexeme}#',
        );

    return signatures[sig] ?? (signatures[sig] = _idx++);
  }
}

void asyncComplete(CompilerContext ctx, SSA? value) {
  ctx.pushOp(ReturnAsync(value, ctx.lookupLocal('#completer')!.ssa));
}
