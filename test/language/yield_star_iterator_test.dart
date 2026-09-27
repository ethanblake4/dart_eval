import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _library = 'package:yield_star/main.dart';

void main() {
  test('yield* dispatches guest iterator errors through catch and finally', () {
    final program = Compiler().compile({
      'yield_star': {
        'main.dart': r'''
          int moveCalls = 0;
          int currentReads = 0;
          int catches = 0;
          int finishes = 0;

          class ProbeIterator implements Iterator<int> {
            ProbeIterator(this.failOnMove);
            final bool failOnMove;
            bool moved = false;

            bool moveNext() {
              moveCalls++;
              if (failOnMove) throw StateError('moveNext');
              if (moved) return false;
              moved = true;
              return true;
            }

            int get current {
              currentReads++;
              throw StateError('current');
            }

            dynamic noSuchMethod(Invocation invocation) =>
                throw StateError('unexpected iterator member');
          }

          class ProbeIterable implements Iterable<int> {
            ProbeIterable(this.failOnMove);
            final bool failOnMove;
            Iterator<int> get iterator => ProbeIterator(failOnMove);

            dynamic noSuchMethod(Invocation invocation) =>
                throw StateError('unexpected iterable member');
          }

          Iterable<int> delegated(bool failOnMove) sync* {
            try {
              yield* ProbeIterable(failOnMove);
            } on StateError {
              catches++;
              yield 90;
            } finally {
              finishes++;
            }
          }

          int main() {
            final moveFailure = delegated(true).iterator;
            if (!moveFailure.moveNext() || moveFailure.current != 90) {
              return -1;
            }
            if (moveFailure.moveNext()) return -2;
            if (moveCalls != 1 || currentReads != 0 ||
                catches != 1 || finishes != 1) return -3;

            final currentFailure = delegated(false).iterator;
            if (!currentFailure.moveNext() || currentFailure.current != 90) {
              return -4;
            }
            if (currentFailure.moveNext()) return -5;
            if (moveCalls != 2 || currentReads != 1 ||
                catches != 2 || finishes != 2) return -6;
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

  test('yield* forwards nullable native values and nested generators', () {
    final program = Compiler().compile({
      'yield_star': {
        'main.dart': r'''
          Iterable<int?> nested() sync* {
            yield 3;
          }

          Iterable<int?> values() sync* {
            yield* <int?>[1, null];
            yield* nested();
          }

          int main() {
            final iterator = values().iterator;
            if (!iterator.moveNext() || iterator.current != 1) return -1;
            if (!iterator.moveNext() || iterator.current != null) return -2;
            if (!iterator.moveNext() || iterator.current != 3) return -3;
            if (iterator.moveNext()) return -4;
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
