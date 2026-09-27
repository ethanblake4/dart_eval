import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('yield* delegates lazily and infers closure element types', () {
    final program = Compiler().compile({
      'generator': {
        'main.dart': r'''
          int started = 0;
          Iterable<int> child() sync* {
            started++;
            yield 2;
            yield 3;
          }
          int main() {
            final make = () sync* {
              yield 1;
              yield* child();
              yield* <int>[];
              yield 4;
            };
            dynamic values = make();
            if (values is! Iterable<int>) return -1;
            final it = values.iterator;
            if (started != 0) return -2;
            if (!it.moveNext() || it.current != 1 || started != 0) return -3;
            if (!it.moveNext() || it.current != 2 || started != 1) return -4;
            if (!it.moveNext() || it.current != 3) return -5;
            if (!it.moveNext() || it.current != 4 || it.moveNext()) return -6;
            var result = 0;
            for (final value in make()) {
              result = result * 10 + value;
            }
            return result;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:generator/main.dart', 'main'), 1234);
    }
  });

  test('yield* iterator errors enter the delegating catch and finally', () {
    final program = Compiler().compile({
      'generator': {
        'main.dart': r'''
          int completed = 0;
          Iterable<int> values(List<int> source) sync* {
            try {
              yield* source;
            } catch (e) {
              yield 9;
            } finally {
              completed++;
            }
            yield 7;
          }
          int main() {
            final source = [1, 2];
            final it = values(source).iterator;
            if (!it.moveNext() || it.current != 1) return -1;
            source.add(3);
            if (!it.moveNext() || it.current != 9 || completed != 0) return -2;
            if (!it.moveNext() || it.current != 7 || completed != 1) return -3;
            return it.moveNext() ? -4 : completed;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:generator/main.dart', 'main'), 1);
    }
  });
}
