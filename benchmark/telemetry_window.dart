import 'support/comparison.dart';

// Rolling sixteen-sample telemetry windows for 64 devices.
// dart compile exe benchmark/telemetry_window.dart -o .dart_tool/telemetry_window.exe
// .dart_tool/telemetry_window.exe [events] [samples]
const _source = r'''
int main(int events) {
  const devices = 64;
  const window = 16;
  final readings = List<int>.filled(devices * window, 0);
  final sums = List<int>.filled(devices, 0);
  final counts = List<int>.filled(devices, 0);
  final positions = List<int>.filled(devices, 0);
  final alerts = List<int>.filled(devices, 0);
  var state = 123456789;
  var alertScore = 0;

  for (var event = 0; event < events; event++) {
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    final device = (state >> 8) & 63;
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    var reading = 20 + ((state >> 9) % 81);
    if (event % 97 == 0) reading += 180;
    if (event % 131 == 0) reading = 0;

    final count = counts[device];
    final sum = sums[device];
    if (count >= 8 && reading * count > sum * 2) {
      alerts[device]++;
      alertScore += device + reading;
    }
    final slot = device * window + positions[device];
    final old = readings[slot];
    readings[slot] = reading;
    sums[device] = sum + reading - old;
    if (count < window) counts[device] = count + 1;
    positions[device] = (positions[device] + 1) & 15;
  }

  var checksum = alertScore;
  for (var device = 0; device < devices; device++) {
    checksum += sums[device] * (device + 1) + alerts[device] * 17;
  }
  return checksum;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'telemetry_window',
  source: _source,
  parameter: 'events',
  unit: 'event',
  iterations: 100000,
  warmupIterations: 1000,
);
