import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test('virtual calls require named arguments before emission', () {
    expect(
      () => Compiler().compile({
        'binding': {
          'main.dart': '''
            class A { int m({required int x}) => x; }
            A make() => A();
            int main() => make().m();
          ''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });

  test('invalid operator operands do not fall back to untyped dispatch', () {
    expect(
      () => Compiler().compile({
        'binding': {
          'main.dart': '''
            class A { int operator +(String value) => 1; }
            int main() => A() + 2;
          ''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
