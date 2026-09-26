import 'package:dart_eval/dart_eval.dart';

/// Times guest execution after compilation, using the same sampling protocol
/// as comparison.py. Compile each benchmark host with `dart compile exe`.
void runComparison(
  List<String> args, {
  required String name,
  required String source,
  required String parameter,
  required String unit,
  required int iterations,
  required int warmupIterations,
}) {
  final count = args.isEmpty ? iterations : int.parse(args[0]);
  final samples = args.length < 2 ? 7 : int.parse(args[1]);
  if (count < 1 || samples < 7) {
    throw ArgumentError(
      'Positive iterations and at least seven samples required',
    );
  }
  final library = 'package:$name/main.dart';
  final compiler = Compiler()..entrypoints.add(library);
  final program = compiler.compile({
    name: {'main.dart': source},
  });
  final runtime = Runtime(program.write().buffer);
  int run(int n) =>
      runtime.executeLib(library, 'main', arguments: {parameter: n}) as int;

  var checksum = 0;
  for (var warm = 0; warm < 2; warm++) {
    checksum += run(warmupIterations);
  }
  final times = <double>[];
  int? expected;
  for (var sample = 0; sample < samples; sample++) {
    final watch = Stopwatch()..start();
    final result = run(count);
    watch.stop();
    if (expected != null && result != expected) {
      throw StateError('Result changed between samples: $expected -> $result');
    }
    expected = result;
    checksum += result;
    times.add(watch.elapsedMicroseconds / 1000);
  }
  final raw = List<double>.of(times);
  times.sort();
  final middle = times.length ~/ 2;
  final median = times.length.isOdd
      ? times[middle]
      : (times[middle - 1] + times[middle]) / 2;
  print(
    '$name median_ms=${median.toStringAsFixed(3)} '
    'min_ms=${times.first.toStringAsFixed(3)} '
    'max_ms=${times.last.toStringAsFixed(3)} '
    'ns/$unit=${(median * 1000000 / count).toStringAsFixed(2)} '
    'raw_ms=${raw.map((value) => value.toStringAsFixed(3)).join(',')}',
  );
  print('checksum=$checksum');
}
