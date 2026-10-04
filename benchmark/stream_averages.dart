import 'support/comparison.dart';

// Maintain per-device running averages, periodically resetting each reporting
// window. Each accepted reading returns the average displayed by a consumer.
// dart compile exe benchmark/stream_averages.dart -o .dart_tool/stream-averages.exe
// .dart_tool/stream-averages.exe [readings] [samples]
const _source = r'''
class ReportingWindow {
  int total = 0;
  int count = 0;

  int accept(int reading) {
    count++;
    total += reading;
    return total ~/ count;
  }

  void reset() {
    total = 0;
    count = 0;
  }
}

int main(int readings) {
  final windows = List<ReportingWindow>.generate(16, (_) => ReportingWindow());
  var checksum = 0;
  for (var i = 0; i < readings; i++) {
    final window = windows[i & 15];
    checksum += window.accept((i * 31 + 7) & 1023);
    if ((i & 4095) == 4095) {
      for (final window in windows) {
        window.reset();
      }
    }
  }
  return checksum;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'stream_averages',
  source: _source,
  parameter: 'readings',
  unit: 'reading',
  iterations: 100000,
  warmupIterations: 1000,
  defaultSamples: 15,
);
