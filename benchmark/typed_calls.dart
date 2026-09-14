import 'package:dart_eval/dart_eval.dart';

// Run with: dart compile exe benchmark/typed_calls.dart -o typed_calls.exe
// Then: typed_calls.exe [iterations] [samples]
class Payload {
  const Payload(this.label);
  final String label;
}

TypedProgram compile(String source) => Compiler().compileTyped({
  'calls': {'main.dart': source},
}, entrypoint: 'package:calls/main.dart');

void main(List<String> args) {
  final iterations = args.isEmpty ? 1000000 : int.parse(args[0]);
  final samples = args.length < 2 ? 7 : int.parse(args[1]);
  if (iterations < 1 || samples < 1) {
    throw ArgumentError('Positive iterations and samples required');
  }
  final primitive = compile('''
    int step(int value, int delta) => value + delta;
    int main(int n) {
      var sum = 0;
      for (var i = 0; i < n; i++) { sum = step(sum, 3); }
      return sum;
    }
  ''');
  final mixed = compile('''
    Object step(Object first, Object second, int i, bool choose) {
      if (choose) return first;
      return second;
    }
    int main(int n, Object first, Object second) {
      var sum = 0;
      for (var i = 0; i < n; i++) {
        var selected = step(first, second, i, i % 2 == 0);
        if (selected == first) { sum += 1; } else { sum += 2; }
      }
      return sum;
    }
  ''');
  const objects = [Payload('first'), Payload('second')];
  var checksum = 0;
  print('typed_calls iterations=$iterations samples=$samples');
  for (final (name, program, expected, objectArguments) in [
    ('primitive', primitive, iterations * 3, const <Object?>[]),
    ('mixed', mixed, iterations + iterations ~/ 2, objects),
  ]) {
    for (var warm = 0; warm < 5; warm++) {
      checksum +=
          TypedMachine.run(
                program,
                intArguments: [1000],
                objectArguments: objectArguments,
              )
              as int;
    }
    final times = <double>[];
    for (var sample = 0; sample < samples; sample++) {
      final watch = Stopwatch()..start();
      final result = TypedMachine.run(
        program,
        intArguments: [iterations],
        objectArguments: objectArguments,
      );
      watch.stop();
      if (result != expected) {
        throw StateError('$name returned $result, expected $expected');
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
