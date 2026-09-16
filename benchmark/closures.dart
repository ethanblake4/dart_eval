import 'package:dart_eval/dart_eval.dart';

// dart compile exe benchmark/closures.dart -o closures.exe
// closures.exe [iterations] [samples]
const _library = 'package:closures/main.dart';

void main(List<String> args) {
  final iterations = args.isEmpty ? 1000000 : int.parse(args[0]);
  final samples = args.length < 2 ? 5 : int.parse(args[1]);
  if (iterations < 1 || samples < 1) {
    throw ArgumentError('Positive iterations and samples required');
  }
  final workloads = [
    (
      'direct',
      3,
      1,
      '''
      int step(int value, int delta) => value + delta;
      int main(int n) {
        var sum = 0;
        for (var i = 0; i < n; i++) { sum = step(sum, 3); }
        return sum;
      }
    ''',
    ),
    (
      'noncapturing-exact',
      3,
      1,
      '''
      int main(int n) {
        final step = (int value, int delta) => value + delta;
        var sum = 0;
        for (var i = 0; i < n; i++) { sum = step(sum, 3); }
        return sum;
      }
    ''',
    ),
    (
      'shared-mutable-capture',
      3,
      2,
      '''
      int main(int n) {
        var captured = 0;
        final add = (int delta) { captured = captured + delta; return captured; };
        final read = () => captured;
        var sum = 0;
        for (var i = 0; i < n; i++) { add(3); sum = read(); }
        return sum;
      }
    ''',
    ),
    (
      'overflow-four',
      6,
      1,
      '''
      int main(int n) {
        final step = (int a, int b, int c, int d) => a + b + c + d;
        var sum = 0;
        for (var i = 0; i < n; i++) { sum = step(sum, 1, 2, 3); }
        return sum;
      }
    ''',
    ),
    (
      'default-adapter',
      3,
      1,
      '''
      int main(int n) {
        final step = (int value, {int delta = 3}) => value + delta;
        var sum = 0;
        for (var i = 0; i < n; i++) { sum = step(sum); }
        return sum;
      }
    ''',
    ),
  ];
  // Compile every workload before timing. Closures and their environments are
  // created once per entry, outside the source loop; calls repeat inside the VM.
  final cases = [
    for (final (name, multiplier, calls, source) in workloads)
      (
        name,
        multiplier,
        calls,
        Runtime.ofProgram(
          Compiler().compile({
            'closures': {'main.dart': source},
          }),
        ),
      ),
  ];
  var checksum = 0;
  print('typed_closures iterations=$iterations samples=$samples');
  for (final (name, multiplier, calls, runtime) in cases) {
    for (var warm = 0; warm < 5; warm++) {
      final result = runtime.executeLib(
        _library,
        'main',
        arguments: {'n': 1000},
      );
      if (result != multiplier * 1000) {
        throw StateError('$name warmup returned $result');
      }
      checksum += result as int;
    }
    final times = <double>[];
    for (var sample = 0; sample < samples; sample++) {
      final watch = Stopwatch()..start();
      final result = runtime.executeLib(
        _library,
        'main',
        arguments: {'n': iterations},
      );
      watch.stop();
      if (result != multiplier * iterations) {
        throw StateError(
          '$name returned $result, expected ${multiplier * iterations}',
        );
      }
      checksum += result as int;
      times.add(watch.elapsedMicroseconds / 1000);
    }
    times.sort();
    final median = times[times.length ~/ 2];
    print(
      '$name calls/iteration=$calls '
      'median_ms=${median.toStringAsFixed(3)} '
      'min_ms=${times.first.toStringAsFixed(3)} '
      'max_ms=${times.last.toStringAsFixed(3)} '
      'ns/iteration=${(median * 1000000 / iterations).toStringAsFixed(2)}',
    );
  }
  print('checksum=$checksum');
}
