import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _library = 'package:sync_generator/main.dart';

void main() {
  test('sync* is lazy and each iterator owns captured parameter state', () {
    final program = Compiler().compile({
      'sync_generator': {
        'main.dart': r'''
          int starts = 0;

          Iterable<int> sequence(int seed) sync* {
            starts++;
            int next() => ++seed;
            yield next();
            yield next();
          }

          int main() {
            final values = sequence(4);
            if (starts != 0) return -1;
            final first = values.iterator;
            final second = values.iterator;
            if (!first.moveNext() || first.current != 5 || starts != 1) {
              return -2;
            }
            if (!second.moveNext() || second.current != 5 || starts != 2) {
              return -3;
            }
            if (!first.moveNext() || first.current != 6) return -4;
            if (!second.moveNext() || second.current != 6) return -5;
            if (first.moveNext() || second.moveNext()) return -6;
            return 1;
          }
        ''',
      },
    });
    for (final (name, runtime) in [
      ('fresh', Runtime.ofProgram(program)),
      ('serialized', Runtime(program.write().buffer)),
    ]) {
      expect(runtime.executeLib(_library, 'main'), 1, reason: name);
    }
  });

  test('method and closure sync* yield typed elements', () {
    final program = Compiler().compile({
      'sync_generator': {
        'main.dart': r'''
          class Source {
            Iterable<int> values(int start) sync* {
              yield start;
              yield start + 1;
              return;
            }
          }

          int main() {
            final make = () sync* {
              yield 3;
              yield 4;
            };
            if (make() is! Iterable<int>) return -1;
            Iterable<int> inferred = make();
            var result = 0;
            for (final value in Source().values(1)) {
              result = result * 10 + value;
            }
            for (final value in inferred) {
              result = result * 10 + value;
            }
            return result;
          }
        ''',
      },
    });
    for (final (name, runtime) in [
      ('fresh', Runtime.ofProgram(program)),
      ('serialized', Runtime(program.write().buffer)),
    ]) {
      expect(runtime.executeLib(_library, 'main'), 1234, reason: name);
    }
  });

  test('bare return completes a generator through finally', () {
    final program = Compiler().compile({
      'sync_generator': {
        'main.dart': r'''
          int finishes = 0;

          Iterable<int> values() sync* {
            try {
              yield 7;
              return;
            } finally {
              finishes++;
            }
          }

          int main() {
            final iterator = values().iterator;
            if (!iterator.moveNext() || iterator.current != 7) return -1;
            if (finishes != 0) return -2;
            if (iterator.moveNext()) return -3;
            return finishes;
          }
        ''',
      },
    });
    for (final (name, runtime) in [
      ('fresh', Runtime.ofProgram(program)),
      ('serialized', Runtime(program.write().buffer)),
    ]) {
      expect(runtime.executeLib(_library, 'main'), 1, reason: name);
    }
  });

  test('overflow parameters survive interleaved iterator resumes', () {
    final program = Compiler().compile({
      'sync_generator': {
        'main.dart': r'''
          Iterable<int> values(int a, int b, int c, int d, int e, int f)
              sync* {
            yield a + f;
            yield b + c + d + e;
          }

          int unrelated(int a, int b, int c, int d, int e, int f) =>
              a + b + c + d + e + f;

          int main() {
            final source = values(1, 2, 3, 4, 5, 6);
            final first = source.iterator;
            final second = source.iterator;
            if (!first.moveNext() || first.current != 7) return -1;
            if (unrelated(7, 8, 9, 10, 11, 12) != 57) return -2;
            if (!second.moveNext() || second.current != 7) return -3;
            if (!first.moveNext() || first.current != 14) return -4;
            if (!second.moveNext() || second.current != 14) return -5;
            return 1;
          }
        ''',
      },
    });
    for (final (name, runtime) in [
      ('fresh', Runtime.ofProgram(program)),
      ('serialized', Runtime(program.write().buffer)),
    ]) {
      expect(runtime.executeLib(_library, 'main'), 1, reason: name);
    }
  });

  test('generator iterable types use class and callable type arguments', () {
    final program = Compiler().compile({
      'sync_generator': {
        'main.dart': r'''
          class Source<T> {
            Source(this.value);
            final T value;

            Iterable<T> owner() sync* {
              yield value;
            }

            Iterable<S> method<S>(S item) sync* {
              yield item;
            }
          }

          Iterable<T> function<T>(T item) sync* {
            yield item;
          }

          int main() {
            final source = Source<int>(3);
            dynamic owner = source.owner();
            dynamic method = source.method<String>('four');
            dynamic topLevel = function<int>(5);
            if (owner is! Iterable<int> || owner.first != 3) return -1;
            if (method is! Iterable<String> || method.first != 'four') {
              return -2;
            }
            if (topLevel is! Iterable<int> || topLevel.first != 5) return -3;
            return 1;
          }
        ''',
      },
    });
    for (final (name, runtime) in [
      ('fresh', Runtime.ofProgram(program)),
      ('serialized', Runtime(program.write().buffer)),
    ]) {
      expect(runtime.executeLib(_library, 'main'), 1, reason: name);
    }
  });
}
