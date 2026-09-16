import 'package:dart_eval/dart_eval.dart';

// dart compile exe benchmark/exceptions.dart -o exceptions.exe
// exceptions.exe [iterations] [samples]
const _library = 'package:exceptions/main.dart';

void main(List<String> args) {
  final iterations = args.isEmpty ? 100001 : int.parse(args[0]);
  final samples = args.length < 2 ? 3 : int.parse(args[1]);
  if (iterations < 1 || samples < 1) {
    throw ArgumentError('Positive iterations and samples required');
  }
  final program = Compiler().compile({
    'exceptions': {
      'main.dart': '''
      int increment(int value) => value + 3;

      int incrementWithFinally(int value) {
        try {
          return value + 3;
        } finally {}
      }

      int noTry(int n) {
        var result = 0;
        for (var i = 0; i < n; i++) {
          result += 3;
        }
        return result;
      }

      int protectedNoThrow(int n) {
        var result = 0;
        for (var i = 0; i < n; i++) {
          try {
            result += 3;
          } finally {}
        }
        return result;
      }

      int handledThrow(int n) {
        var result = 0;
        for (var i = 0; i < n; i++) {
          try {
            throw 'expected';
          } catch (error) {
            result += 3;
          }
        }
        return result;
      }

      int protectedCall(int n) {
        var result = 0;
        for (var i = 0; i < n; i++) {
          try {
            result = increment(result);
          } finally {}
        }
        return result;
      }

      int returnFinally(int n) {
        var result = 0;
        for (var i = 0; i < n; i++) {
          result = incrementWithFinally(result);
        }
        return result;
      }
    ''',
    },
  });
  var checksum = 0;
  print('typed_exceptions iterations=$iterations samples=$samples');
  for (final name in [
    'noTry',
    'protectedNoThrow',
    'handledThrow',
    'protectedCall',
    'returnFinally',
  ]) {
    final runtime = Runtime.ofProgram(program);
    int expected(int n) => n * 3;
    for (var warm = 0; warm < 5; warm++) {
      final result = runtime.executeLib(_library, name, arguments: {'n': 1001});
      if (result != expected(1001)) {
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
