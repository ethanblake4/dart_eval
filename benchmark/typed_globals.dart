import 'package:dart_eval/dart_eval.dart';

// dart compile exe benchmark/typed_globals.dart -o typed_globals.exe
// typed_globals.exe [iterations] [samples]
const _library = 'package:globals/main.dart';

void main(List<String> args) {
  final iterations = args.isEmpty ? 1000000 : int.parse(args[0]);
  final samples = args.length < 2 ? 5 : int.parse(args[1]);
  if (iterations < 1 || samples < 1) {
    throw ArgumentError('Positive iterations and samples required');
  }
  final program = Compiler().compile({
    'globals': {
      'main.dart': '''
      int initializations = 0;
      int initialize() { initializations = initializations + 1; return 7; }
      int value = initialize();
      class Token {}
      final first = Token();
      final second = Token();
      Object selected = first;
      int setup() => value;
      int initializationCount() => initializations;
      int local(int n) {
        var sum = 0;
        for (var i = 0; i < n; i++) { sum = sum + 3; }
        return sum + initializations;
      }
      int global(int n) {
        value = 0;
        for (var i = 0; i < n; i++) { value = value + 3; }
        return value + initializations;
      }
      int object(int n) {
        var sum = 0;
        for (var i = 0; i < n; i++) {
          if (i % 2 == 0) { selected = first; } else { selected = second; }
          if (selected == first) { sum += 1; } else { sum += 2; }
        }
        return sum + initializations;
      }
    ''',
    },
  });
  var checksum = 0;
  print('typed_globals iterations=$iterations samples=$samples');
  for (final name in ['local', 'global', 'object']) {
    final runtime = Runtime.ofProgram(program);
    // Trigger lazy initialization before timing and verify repeated reads do
    // not rerun it. Each workload receives independent per-Runtime state.
    for (var read = 0; read < 2; read++) {
      if (runtime.executeLib(_library, 'setup') != 7) {
        throw StateError('$name global initialization failed');
      }
    }
    int expected(int n) => name == 'object' ? n + n ~/ 2 + 1 : n * 3 + 1;
    for (var warm = 0; warm < 5; warm++) {
      final result = runtime.executeLib(_library, name, arguments: {'n': 1000});
      if (result != expected(1000)) {
        throw StateError('$name warmup returned $result');
      }
      checksum += result as int;
    }
    final times = <double>[];
    for (var sample = 0; sample < samples; sample++) {
      final watch = Stopwatch()..start();
      final result = runtime.executeLib(
        _library,
        name,
        arguments: {'n': iterations},
      );
      watch.stop();
      if (result != expected(iterations)) {
        throw StateError(
          '$name returned $result, expected ${expected(iterations)}',
        );
      }
      checksum += result as int;
      times.add(watch.elapsedMicroseconds / 1000);
    }
    if (runtime.executeLib(_library, 'initializationCount') != 1) {
      throw StateError('$name reran its global initializer');
    }
    times.sort();
    final median = times[times.length ~/ 2];
    print(
      '$name median_ms=${median.toStringAsFixed(3)} '
      'min_ms=${times.first.toStringAsFixed(3)} '
      'max_ms=${times.last.toStringAsFixed(3)} '
      'ns/iteration=${(median * 1000000 / iterations).toStringAsFixed(2)}',
    );
  }
  print('checksum=$checksum');
}
