import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  group('Records', () {
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
          '''
        }
      });

      expect(
        () {
          runtime.executeLib('package:eval_test/main.dart', 'main');
        },
        prints('0\n1\n'),
      );
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
          '''
        }
      });
      expect(
        () {
          runtime.executeLib('package:eval_test/main.dart', 'main');
        },
        prints('2\n3\n'),
      );
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
          '''
        }
      });
      expect(
        () {
          runtime.executeLib('package:eval_test/main.dart', 'main');
        },
        prints('Alice\n30\n'),
      );
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
          '''
        }
      });
      expect(
        () {
          runtime.executeLib('package:eval_test/main.dart', 'main');
        },
        prints('1\nBob\n3.5\n'),
      );
    });
  });
}
