import 'support/comparison.dart';

// Apply parsed name/value patches to long-lived session records.
// dart compile exe benchmark/string_fields.dart -o .dart_tool/string-fields-baseline.exe
// .dart_tool/string-fields-baseline.exe [batches] [samples]
const _source = r'''
class Patch {
  Patch(this.target, this.line);
  final int target;
  final String line;
}

class TokenRecord {
  String name = 'unknown';
  String state = 'idle';
  String region = 'none';
  String lastKey = '';
  String lastValue = '';

  void apply(String line) {
    final separator = line.indexOf('=');
    final key = line.substring(0, separator);
    final value = line.substring(separator + 1);
    lastKey = key;
    lastValue = value;
    if (key == 'name') {
      name = value;
    } else if (key == 'state') {
      state = value;
    } else if (key == 'region') {
      region = value;
    }
  }

  int get score => name.length * 3 + state.length * 5 +
      region.length * 7 + lastKey.length * 11 + lastValue.length * 13 +
      name.codeUnitAt(0) + state.codeUnitAt(0) + region.codeUnitAt(0);
}

int main(int batches) {
  final records = <TokenRecord>[
    TokenRecord(), TokenRecord(), TokenRecord(), TokenRecord(),
  ];
  final patches = <Patch>[
    Patch(0, 'name=alpha'),
    Patch(1, 'name=bravo'),
    Patch(2, 'state=active'),
    Patch(0, 'region=us-west'),
    Patch(3, 'name=delta'),
    Patch(1, 'state=paused'),
    Patch(2, 'region=eu-central'),
    Patch(0, 'state=active'),
    Patch(3, 'region=ap-south'),
    Patch(1, 'region=us-east'),
    Patch(2, 'name=charlie'),
    Patch(3, 'state=ready'),
  ];
  var checksum = 0;
  for (var batch = 0; batch < batches; batch++) {
    for (var i = 0; i < patches.length; i++) {
      final patch = patches[i];
      final record = records[patch.target];
      record.apply(patch.line);
      checksum += record.lastValue.length;
    }
    for (var i = 0; i < records.length; i++) {
      checksum += records[i].score;
    }
  }
  return checksum;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'string_fields',
  source: _source,
  parameter: 'batches',
  unit: 'batch',
  iterations: 15000,
  warmupIterations: 100,
  defaultSamples: 15,
);
