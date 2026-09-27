import 'support/comparison.dart';

// Build pricing callbacks with scalar configuration, then price each batch.
const _source = r'''
int Function(int) pricing(int seed) {
  final threshold = seed % 16 + 8;
  final rate = seed % 7 + 1;
  final fee = seed % 13;
  return (int quantity) =>
      quantity < threshold ? quantity * rate + fee : fee;
}

int main(int batches) {
  var total = 0;
  for (var batch = 0; batch < batches; batch++) {
    final price = pricing(batch);
    for (var quantity = 0; quantity < 32; quantity++) {
      total += price(quantity);
    }
  }
  return total;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'scalar_callbacks',
  source: _source,
  parameter: 'batches',
  unit: 'batch',
  iterations: 20000,
  warmupIterations: 500,
);
