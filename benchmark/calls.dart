import 'package:dart_eval/dart_eval.dart';

// Run with: dart compile exe benchmark/calls.dart -o calls.exe
// Then: calls.exe [iterations] [samples]
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
  final method = compile('''
    class Counter {
      int value;
      Counter(this.value);
      int add(int amount) { value = value + amount; return value; }
    }
    int main(int n) {
      final counter = Counter(0);
      var result = 0;
      for (var i = 0; i < n; i++) { result = counter.add(3); }
      return result;
    }
  ''');
  final polymorphic = compile('''
    class First { int value(int n) => n + 1; }
    class Second { int value(int n) => n + 3; }
    int main(int n) {
      final first = First();
      final second = Second();
      dynamic receiver = first;
      var sum = 0;
      for (var i = 0; i < n; i++) {
        if (i % 2 == 0) { receiver = first; } else { receiver = second; }
        int value = receiver.value(i);
        sum += value;
      }
      return sum;
    }
  ''');
  final boxedArguments = compile('''
    class Selector {
      Object choose(Object first, Object second, bool chooseFirst) {
        if (chooseFirst) return first;
        return second;
      }
    }
    int main(int n, Object first, Object second) {
      final selector = Selector();
      var sum = 0;
      for (var i = 0; i < n; i++) {
        var selected = selector.choose(first, second, i % 2 == 0);
        if (selected == first) { sum += 1; } else { sum += 2; }
      }
      return sum;
    }
  ''');
  final overflowArguments = compile('''
    class Combiner {
      int combine(int a, int b, int c, int d) => a + b + c + d;
    }
    int main(int n) {
      final combiner = Combiner();
      var sum = 0;
      for (var i = 0; i < n; i++) { sum += combiner.combine(i, 1, 2, 3); }
      return sum;
    }
  ''');
  var checksum = 0;
  print('typed_calls iterations=$iterations samples=$samples');
  for (final (name, program, expected, objectArguments) in [
    ('primitive', primitive, iterations * 3, const <Object?>[]),
    ('mixed', mixed, iterations + iterations ~/ 2, objects),
    ('method', method, iterations * 3, const <Object?>[]),
    (
      'polymorphic',
      polymorphic,
      iterations * (iterations - 1) ~/ 2 + iterations + 2 * (iterations ~/ 2),
      const <Object?>[],
    ),
    ('boxed-arguments', boxedArguments, iterations + iterations ~/ 2, objects),
    (
      'overflow-arguments',
      overflowArguments,
      iterations * (iterations - 1) ~/ 2 + 6 * iterations,
      const <Object?>[],
    ),
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
    final raw = List<double>.of(times);
    times.sort();
    final median = times[times.length ~/ 2];
    print(
      '$name median_ms=${median.toStringAsFixed(3)} '
      'min_ms=${times.first.toStringAsFixed(3)} '
      'max_ms=${times.last.toStringAsFixed(3)} '
      'ns/iteration=${(median * 1000000 / iterations).toStringAsFixed(2)} '
      'raw_ms=${raw.map((value) => value.toStringAsFixed(3)).join(',')}',
    );
  }
  print('checksum=$checksum');
}
