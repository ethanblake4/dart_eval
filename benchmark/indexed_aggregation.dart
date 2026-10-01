import 'support/comparison.dart';

// Aggregate aligned amounts and weights, as in a column-oriented report.
// The function boundary makes list storage unknown to the compiler.
const common = r'''
class AdjustedList implements List<int> {
  AdjustedList(this.values, this.adjustment);
  final List<int> values;
  final int adjustment;
  int get length => values.length;
  int operator [](int index) => values[index] + adjustment;
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError('unused');
}
int weightedTotal(List<int> amounts, List<int> weights) {
  final length = amounts.length;
  var total = 0;
  for (var column = 0; column < length; column++) {
    total += amounts[column] * weights[column];
  }
  return total;
}
''';

String sourceFor(String mode) =>
    '''$common
int main(int batches) {
  final amounts = <int>[3, 7, 5, 11, 2, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53];
  final weights = <int>[1, 3, 2, 5, 7, 2, 3, 1, 5, 7, 2, 3, 1, 5, 7, 2];
  final adjusted = AdjustedList(amounts, 1);
  var result = 0;
  for (var batch = 0; batch < batches; batch++) {
    final List<int> row = ${switch (mode) {
      'native' => 'amounts',
      'guest' => 'adjusted',
      'mixed' => 'batch.isEven ? amounts : adjusted',
      _ => throw ArgumentError.value(mode, 'mode'),
    }};
    result += weightedTotal(row, weights) ^ (batch & 7);
  }
  return result;
}
''';

void main(List<String> args) {
  final mode = args.length > 2 ? args[2] : 'native';
  runComparison(
    args.take(2).toList(),
    name: 'indexed_aggregation_$mode',
    source: sourceFor(mode),
    parameter: 'batches',
    unit: 'batch',
    iterations: 5000,
    warmupIterations: 5,
  );
}
