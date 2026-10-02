import 'support/comparison.dart';

// Repeated calls to a small generic helper with a concrete call-site type.
const _source = r'''
T keep<T>(T value) => value;

int main(int count) {
  var checksum = 0;
  for (var i = 0; i < count; i++) {
    checksum += keep<int>(i);
  }
  return checksum;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'fixed_generic_calls',
  source: _source,
  parameter: 'count',
  unit: 'call',
  iterations: 100000,
  warmupIterations: 1000,
  defaultSamples: 15,
);
