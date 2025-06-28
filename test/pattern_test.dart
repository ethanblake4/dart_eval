import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  group('Patterns', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Destructure record with variable declaration pattern', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': r'''
            void main() {
              var data = (1, name: "Elise");
              final (a, :name) = data;
              print(a);
              print(name);
            }
          '''
        }
      });

      expect(
        () {
          runtime.executeLib('package:eval_test/main.dart', 'main');
        },
        prints('1\nElise\n'),
      );
    });

    test('Destructure record with variable assignment pattern', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': r'''
            void main() {
              var data = (1, name: "Elise");
              int a = 0;
              String name = "";
              (a, :name) = data;
              print(a);
              print(name);
            }
          '''
        }
      });

      expect(
        () {
          runtime.executeLib('package:eval_test/main.dart', 'main');
        },
        prints('1\nElise\n'),
      );
    });

    test('Destructure record across function boundary', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': r'''
            (int, {String greeting}) getData() {
              return (42, greeting: "Hello");
            }

            void main() {
              final (number, :greeting) = getData();
              print(number);
              print(greeting);
            }
          '''
        }
      });

      expect(
        () {
          runtime.executeLib('package:eval_test/main.dart', 'main');
        },
        prints('42\nHello\n'),
      );
    });

    test('Destructure list with variable declaration pattern', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': r'''
            void main() {
              var numbers = [1, 2, 3];
              final [first, _, third] = numbers;
              print(first);
              print(third);
            }
          '''
        }
      });
      expect(
        () {
          runtime.executeLib('package:eval_test/main.dart', 'main');
        },
        prints('1\n3\n'),
      );
    });
  });
}
