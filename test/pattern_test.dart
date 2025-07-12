import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
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

  group('Switch pattern tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Switch matching record pattern', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              var data = (1, name: "Elise");
              switch (data) {
                case (0, name: var n):
                  return "Fail";
                case (1, name: var n):
                  return n + " is the name";
                default:
                  return "Unknown";
              }
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('Elise is the name'));
    });

    test('Switch matching list pattern', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              var data = [1, 2, 3];
              switch (data) {
                case [1, 2, var x]:
                  return "Matched with x = " + x.toString();
                case [var a, var b]:
                  return "Matched with a = " + a.toString() + ", b = " + b.toString();
                default:
                  return "No match";
              }
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('Matched with x = 3'));
    });

    test('Switch with pattern guard', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              var data = (1, name: "Elise");
              switch (data) {
                case (var id, name: var n) when id > 5:
                  return n + " has ID " + id.toString();
                default:
                  return "No match";
              }
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('No match'));
    });

    test('Switch with relational pattern', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              var data = 10;
              switch (data) {
                case >5:
                  return "Greater than 5";
                case <=5:
                  return "5 or less";
                default:
                  return "No match";
              }
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('Greater than 5'));
    });
  });
}
