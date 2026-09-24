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

  test('implicit super calls bind the constructor signature defaults', () {
    final program = Compiler().compile({
      'binding': {
        'main.dart': '''
          class Base {
            final int value;
            Base([this.value = 7]);
          }
          class Child extends Base { Child(); }
          int main() => Child().value;
        ''',
      },
    });
    expect(
      Runtime.ofProgram(
        program,
      ).executeLib('package:binding/main.dart', 'main'),
      7,
    );
  });

  test('function values convert supplied arguments to the closure ABI', () {
    final program = Compiler().compile({
      'binding': {
        'main.dart': '''
          double accepts(double x) => x;
          int main() {
            final f = accepts;
            return f(2).toInt();
          }
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

  test('parenthesized function refs bind defaults through the closure', () {
    final program = Compiler().compile({
      'binding': {
        'main.dart': '''
          double f([double x = 2.5]) => x;
          int main() => (f)().toInt();
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

  test('parenthesized generic refs retain explicit type arguments', () {
    final program = Compiler().compile({
      'binding': {
        'main.dart': '''
          T identity<T>(T value) => value;
          int main() => (identity)<int>(3);
        ''',
      },
    });
    expect(
      Runtime.ofProgram(
        program,
      ).executeLib('package:binding/main.dart', 'main'),
      3,
    );
  });

  test(
    'generic function values infer type arguments from args and context',
    () {
      final program = Compiler().compile({
        'binding': {
          'main.dart': '''
          Type selected<T>(T value) => T;
          T make<T>() => 2 as T;
          int main() {
            final select = selected;
            final create = make;
            if (select(1) != int) return -1;
            int value = create();
            int parenthesized = (create)();
            return value + parenthesized;
          }
        ''',
        },
      });
      expect(
        Runtime.ofProgram(
          program,
        ).executeLib('package:binding/main.dart', 'main'),
        4,
      );
    },
  );

  test('bare source targets bind defaults before emission', () {
    final program = Compiler().compile({
      'binding': {
        'main.dart': '''
          int top([int value = 2]) => value;
          class Box {
            final int value;
            Box([this.value = 4]);
            static int stat([int value = 3]) => value;
          }
          typedef BoxAlias<T> = Box<T>;
          int main() => top() + Box.stat() + BoxAlias<int>().value;
        ''',
      },
    });
    expect(
      Runtime.ofProgram(
        program,
      ).executeLib('package:binding/main.dart', 'main'),
      9,
    );
  });
}
