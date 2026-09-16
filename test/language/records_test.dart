import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/record.dart';
import 'package:test/test.dart';

void main() {
  group('Records', () {
    test(
      'records retain object and null fields across calls and serialization',
      () {
        final program = Compiler().compile({
          'records': {
            'main.dart': r'''
              (int, String?, {List<int> values}) make(int value) {
                return (value, null, values: [value, value + 1]);
              }
              int main() {
                final first = make(3);
                final second = make(8);
                if (first.$2 != null) return -1;
                return first.$1 + second.values[1];
              }
            ''',
          },
        });
        for (final runtime in [
          Runtime.ofProgram(program),
          Runtime(program.write().buffer),
        ]) {
          expect(runtime.executeLib('package:records/main.dart', 'main'), 12);
          final record =
              runtime.executeLib(
                    'package:records/main.dart',
                    'make',
                    arguments: {'value': 2},
                  )
                  as $Record;
          expect(record.fields[1], isNull);
          expect(record.mapping, {r'$1': 0, r'$2': 1, 'values': 2});
        }
      },
    );

    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Create and access records', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': r'''
            void main() {
              var numbers = (0, 1);
              print(numbers.$1);
              print(numbers.$2);
            }
          ''',
        },
      });

      expect(() {
        runtime.executeLib('package:eval_test/main.dart', 'main');
      }, prints('0\n1\n'));
    });

    test('Returning record from function', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': r'''
            (int, int) add(int a, int b) {
              return (a + 1, b + 1);
            }

            void main() {
              var result = add(1, 2);
              print(result.$1);
              print(result.$2);
            }
          ''',
        },
      });
      expect(() {
        runtime.executeLib('package:eval_test/main.dart', 'main');
      }, prints('2\n3\n'));
    });

    test('Record with named fields', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': r'''
            void main() {
              var person = (name: 'Alice', age: 30);
              print(person.name);
              print(person.age);
            }
          ''',
        },
      });
      expect(() {
        runtime.executeLib('package:eval_test/main.dart', 'main');
      }, prints('Alice\n30\n'));
    });

    test('Record with mixed fields', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': r'''
            void main() {
              var mixed = (1, name: 'Bob', 3.5);
              print(mixed.$1);
              print(mixed.name);
              print(mixed.$2);
            }
          ''',
        },
      });
      expect(() {
        runtime.executeLib('package:eval_test/main.dart', 'main');
      }, prints('1\nBob\n3.5\n'));
    });
  });
}
