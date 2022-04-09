import 'package:analyzer/dart/ast/ast.dart';

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

    final sig = p.parameters.where((element) => element.isNamed)
        .fold('$countPos#', (previousValue, element) => element.identifier!.name + '#');

    return signatures[sig] ?? (signatures[sig] = _idx++);
  }
}