import 'support/comparison.dart';

// Reuse a generic reducer captured from a typed batch processor.
// dart compile exe benchmark/generic_reducer.dart -o .dart_tool/generic-reducer.exe
// .dart_tool/generic-reducer.exe [batches] [samples]
const _source = r'''
dynamic reducer<T extends num>() {
  T reduce<U extends T>(U first, U second, U third, U fourth) {
    return (first + second + third + fourth) as T;
  }
  return reduce;
}

int main(int batches) {
  final dynamic combine = reducer<int>();
  var checksum = 0;
  for (var batch = 0; batch < batches; batch++) {
    checksum += combine<int>(batch, 2, 3, 4) as int;
  }
  return checksum;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'generic_reducer',
  source: _source,
  parameter: 'batches',
  unit: 'batch',
  iterations: 10000,
  warmupIterations: 100,
  defaultSamples: 15,
);
