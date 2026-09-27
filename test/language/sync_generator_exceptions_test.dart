import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'sync* suspends exception handlers and closes after an uncaught error',
    () {
      final program = Compiler().compile({
        'generator': {
          'main.dart': r'''
          int completed = 0;
          int fail() => throw 'failure';
          Iterable<int> values() sync* {
            try {
              yield 1;
              try {
                fail();
              } catch (e) {
                yield 2;
              }
              fail();
            } finally {
              completed++;
            }
          }
          int main() {
            final it = values().iterator;
            if (!it.moveNext() || it.current != 1) return -1;
            if (!it.moveNext() || it.current != 2 || completed != 0) return -2;
            try {
              it.moveNext();
              return -3;
            } catch (e) {
              if (e != 'failure') return -4;
            }
            if (it.moveNext() || it.moveNext()) return -5;
            return completed;
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
    },
  );

  test('sync* rejects reentrant iteration without closing the active body', () {
    final program = Compiler().compile({
      'generator': {
        'main.dart': r'''
          late Iterator<int> iterator;
          Iterable<int> values() sync* {
            try {
              iterator.moveNext();
            } on StateError {
              yield 1;
            }
            yield 2;
          }
          int main() {
            iterator = values().iterator;
            if (!iterator.moveNext() || iterator.current != 1) return -1;
            if (!iterator.moveNext() || iterator.current != 2) return -2;
            return iterator.moveNext() ? -3 : 1;
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
