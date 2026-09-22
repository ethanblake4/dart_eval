import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed.dart';

// Measures instance-method dispatch: direct Call vs InvokeDynamic.
// Run with: dart compile exe benchmark/virtual_calls.dart -o virtual_calls.exe
// Then: virtual_calls.exe [iterations] [samples]
TypedProgram compile(String source) => Compiler().compileTyped({
      'virtual_calls': {'main.dart': source},
    }, entrypoint: 'package:virtual_calls/main.dart');

void main(List<String> args) {
  final iterations = args.isEmpty ? 1000000 : int.parse(args[0]);
  final samples = args.length < 2 ? 7 : int.parse(args[1]);
  if (iterations < 1 || samples < 1) {
    throw ArgumentError('Positive iterations and samples required');
  }

  // Method declared on grandparent; receiver static type has no own
  // declaration and a single concrete type -> devirtualizable direct call.
  final inherited = compile('''
    class Base { int hit(int x) => x + 1; }
    class Mid extends Base {}
    class Leaf extends Mid {}
    int main(int n) {
      final Mid receiver = Leaf();
      var sum = 0;
      for (var i = 0; i < n; i++) { sum += receiver.hit(i); }
      return sum;
    }
  ''');

  // Same shape, but a sibling overrides the method -> stays dynamic.
  final overridden = compile('''
    class Base { int hit(int x) => x + 1; }
    class Mid extends Base {}
    class Leaf extends Mid {}
    class Rival extends Mid { int hit(int x) => x + 2; }
    int main(int n) {
      final Mid receiver = Leaf();
      var sum = 0;
      for (var i = 0; i < n; i++) { sum += receiver.hit(i); }
      return sum;
    }
  ''');

  // Receiver static type declares the method itself -> direct call.
  final declared = compile('''
    class Mid { int hit(int x) => x + 1; }
    class Leaf extends Mid {}
    int main(int n) {
      final Mid receiver = Leaf();
      var sum = 0;
      for (var i = 0; i < n; i++) { sum += receiver.hit(i); }
      return sum;
    }
  ''');

  var checksum = 0;
  print('virtual_calls iterations=$iterations samples=$samples');
  for (final (name, program, expected) in [
    ('inherited-direct', inherited, iterations * (iterations + 1) ~/ 2),
    ('inherited-overridden', overridden, iterations * (iterations + 1) ~/ 2),
    ('declared-direct', declared, iterations * (iterations + 1) ~/ 2),
  ]) {
    for (var warm = 0; warm < 3; warm++) {
      checksum += TypedMachine.run(program, intArguments: [1000]) as int;
    }
    final times = <double>[];
    for (var sample = 0; sample < samples; sample++) {
      final watch = Stopwatch()..start();
      final result = TypedMachine.run(program, intArguments: [iterations]);
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
