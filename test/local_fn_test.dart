import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('simple local function', () {
    final compiler = Compiler();
    final runtime = compiler.compileWriteAndLoad({
      't': {
        'main.dart': '''
          void main() {
            int square(int x) => x * x;
            print(square(5));
          }
        ''',
      },
    });
    expect(
      () => runtime.executeLib('package:t/main.dart', 'main'),
      prints('25\n'),
    );
  });

  test('local function calling another local function', () {
    final compiler = Compiler();
    final runtime = compiler.compileWriteAndLoad({
      't': {
        'main.dart': '''
          void main() {
            int square(int x) => x * x;
            int sumOfSquares(int a, int b) => square(a) + square(b);
            print(sumOfSquares(3, 4));
          }
        ''',
      },
    });
    expect(
      () => runtime.executeLib('package:t/main.dart', 'main'),
      prints('25\n'),
    );
  });

  test('local function with block body', () {
    final compiler = Compiler();
    final runtime = compiler.compileWriteAndLoad({
      't': {
        'main.dart': '''
          void main() {
            String greet(String name) {
              return 'Hello, \$name!';
            }
            print(greet('World'));
          }
        ''',
      },
    });
    expect(
      () => runtime.executeLib('package:t/main.dart', 'main'),
      prints('Hello, World!\n'),
    );
  });

  test('local function accessing outer variable', () {
    final compiler = Compiler();
    final runtime = compiler.compileWriteAndLoad({
      't': {
        'main.dart': '''
          void main() {
            var multiplier = 3;
            int multiply(int x) => x * multiplier;
            print(multiply(7));
          }
        ''',
      },
    });
    expect(
      () => runtime.executeLib('package:t/main.dart', 'main'),
      prints('21\n'),
    );
  });
}
