import 'support/comparison.dart';

// Build per-request processors that retain configuration and mutable output.
// Each processor escapes its factory and runs on a batch of records.
const _source = r'''
class Config {
  Config(this.multiplier, this.offset);
  final int multiplier;
  final int offset;
}

class Output {
  int total = 0;
}

int Function(int) processor(int seed) {
  final config = Config(seed % 7 + 1, seed % 13);
  final output = Output();
  return (int value) {
    output.total += value * config.multiplier + config.offset;
    return output.total;
  };
}

int main(int batches) {
  var checksum = 0;
  for (var batch = 0; batch < batches; batch++) {
    final process = processor(batch);
    for (var record = 0; record < 32; record++) {
      checksum += process(record);
    }
  }
  return checksum;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'configured_callbacks',
  source: _source,
  parameter: 'batches',
  unit: 'batch',
  iterations: 20000,
  warmupIterations: 500,
);
