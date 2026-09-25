import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test('field formal requires a declared field', () {
    for (final declaration in [
      'class A { A(this.x); }',
      'class A { int get x => 1; A(this.x); }',
    ]) {
      expect(
        () => Compiler().compile({
          'binding': {'main.dart': '$declaration void main() {}'},
        }),
        throwsA(isA<CompileError>()),
      );
    }
  });

  test('explicit constructor binds an applied generic parameter', () {
    expect(
      eval('''
        class Box<T> {
          final T value;
          Box(this.value);
        }
        int main() => Box<int>(3).value;
      '''),
      3,
    );
  });

  test('dot shorthand constructor uses its context type', () {
    expect(
      eval('''
        class Box<T> {
          final T value;
          Box(this.value);
        }
        int main() {
          Box<int> box = .new(4);
          return box.value;
        }
      '''),
      4,
    );
  });

  test('dot shorthand static source method binds through its signature', () {
    expect(
      eval('''
        class Token {
          final int value;
          Token(this.value);
          static Token make(int value) => Token(value);
        }
        int main() {
          Token token = .make(5);
          return token.value;
        }
      '''),
      5,
    );
  });

  test('dot shorthand static method forwards explicit type arguments', () {
    expect(
      eval('''
        class Token {
          final int value;
          Token(this.value);
          static Token from<T>(T value) => Token(value as int);
        }
        int main() {
          Token token = .from<int>(6);
          return token.value;
        }
      '''),
      6,
    );
  });

  test('dot shorthand static bridge method binds through its signature', () {
    expect(
      eval('''
        int main() {
          int value = .parse('42');
          return value;
        }
      '''),
      42,
    );
  });

  test('enum constants bind omitted constructor defaults', () {
    expect(
      eval('''
        enum Item {
          first, second(4);
          final int value;
          const Item([this.value = 3]);
        }
        int main() => Item.first.value + Item.second.value;
      '''),
      7,
    );
  });

  test('explicit super call binds an applied generic parameter', () {
    expect(
      eval('''
        class Base<T> {
          final T value;
          Base(this.value);
        }
        class Child extends Base<int> {
          Child(int value) : super(value);
        }
        int main() => Child(8).value;
      '''),
      8,
    );
  });

  test('explicit super call combines forwarded and supplied arguments', () {
    expect(
      eval('''
        class Base {
          final int first;
          final int second;
          Base(this.first, {this.second = 2});
        }
        class Child extends Base {
          Child(super.first) : super(second: 3);
        }
        int main() {
          final child = Child(4);
          return child.first + child.second;
        }
      '''),
      7,
    );
  });

  test('positional super formals reject explicit positional arguments', () {
    expect(
      () => Compiler().compile({
        'binding': {
          'main.dart': '''
            class Base { Base(int first, int second); }
            class Child extends Base {
              Child(super.first) : super(2);
            }
            void main() {}
          ''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });

  test('named super formals reject duplicate named arguments', () {
    expect(
      () => Compiler().compile({
        'binding': {
          'main.dart': '''
            class Base { Base(int first, {required int second}); }
            class Child extends Base {
              Child(int first, {required super.second})
                  : super(first, second: 2);
            }
            void main() {}
          ''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
