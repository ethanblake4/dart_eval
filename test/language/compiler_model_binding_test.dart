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

  test('an explicit super-formal default resolves in its own library', () {
    final program = Compiler().compile({
      'binding': {
        'base.dart': '''
          class Base {
            final int value;
            Base({this.value = 1});
          }
        ''',
        'main.dart': '''
          import 'base.dart';
          const localDefault = 2;
          class Child extends Base {
            Child({super.value = localDefault});
          }
          int main() => Child().value;
        ''',
      },
    });
    expect(
      Runtime.ofProgram(
        program,
      ).executeLib('package:binding/main.dart', 'main'),
      2,
    );
  });

  test('explicit self-referential bounds use the callee parameter', () {
    final program = Compiler().compile({
      'binding': {
        'main.dart': '''
          class Link<T> {}
          class Good extends Link<Good> {}
          T echo<T extends Link<T>>(T value) => value;
          int main() => echo<Good>(Good()) is Good ? 1 : 0;
        ''',
      },
    });
    expect(
      Runtime.ofProgram(
        program,
      ).executeLib('package:binding/main.dart', 'main'),
      1,
    );
    expect(
      () => Compiler().compile({
        'binding': {
          'main.dart': '''
            class Link<T> {}
            T echo<T extends Link<T>>(T value) => value;
            int main() => echo<int>(1);
          ''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
