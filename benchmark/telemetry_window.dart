import 'package:dart_eval/dart_eval.dart';

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

void main(List<String> args) {
  final events = args.isEmpty ? 100000 : int.parse(args[0]);
  final samples = args.length < 2 ? 7 : int.parse(args[1]);
  if (events < 1 || samples < 7) {
    throw ArgumentError('Positive events and at least seven samples required');
  }
  final compiler = Compiler();
  compiler.entrypoints.add('package:telemetry_window/main.dart');
  final program = compiler.compile({
    'telemetry_window': {'main.dart': _source},
  });
  final runtime = Runtime(program.write().buffer);
  int run(int n) =>
      runtime.executeLib(
            'package:telemetry_window/main.dart',
            'main',
            arguments: {'events': n},
          )
          as int;

  var checksum = 0;
  for (var warm = 0; warm < 2; warm++) {
    checksum += run(1000);
  }
  final times = <double>[];
  for (var sample = 0; sample < samples; sample++) {
    final watch = Stopwatch()..start();
    checksum += run(events);
    watch.stop();
    times.add(watch.elapsedMicroseconds / 1000);
  }
  times.sort();
  final median = times[times.length ~/ 2];
  print(
    'telemetry_window median_ms=${median.toStringAsFixed(3)} '
    'min_ms=${times.first.toStringAsFixed(3)} '
    'max_ms=${times.last.toStringAsFixed(3)} '
    'ns/event=${(median * 1000000 / events).toStringAsFixed(2)}',
  );
  print('checksum=$checksum');
}
