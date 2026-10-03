import 'support/comparison.dart';

// Create short-lived callbacks with captured configuration, then invoke once.
const _source = r'''
int Function(int) makeCallback(int seed) {
  final threshold = seed % 16 + 8;
  final rate = seed % 7 + 1;
  final fee = seed % 13;
  return (int quantity) =>
      quantity < threshold ? quantity * rate + fee : fee;
}

int main(int callbacks) {
  var total = 0;
  for (var i = 0; i < callbacks; i++) {
    final callback = makeCallback(i);
    total += callback(i % 32);
  }
  return total;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'closure_factory',
  source: _source,
  parameter: 'callbacks',
  unit: 'callback',
  iterations: 100000,
  warmupIterations: 1000,
);
