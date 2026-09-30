import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  void check(String name, String source, Object expected) {
    test(name, () {
      final program = Compiler().compile({
        'primary': {'main.dart': '// @dart=3.13\n$source'},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:primary/main.dart', 'main'),
          expected,
        );
      }
    });
  }

  check('header fields reuse constructor checks and mutable field storage', '''
class Point(var int x, final int y);
int main() {
  final make = Point.new;
  dynamic dynamicMake = make;
  Point point = dynamicMake(1, 2);
  point.x = 3;
  return point.x + point.y + make(4, 5).x;
}
''', 9);

  check('named generic headers retain optional defaults and redirects', '''
class Box<T>.named(final T value, {var int count = 2}) {
  Box.redirect(T value) : this.named(value);
  factory Box.from(T value) => Box<T>.named(value, count: 3);
}
int main() {
  final make = Box<int>.named;
  return make(4).value + Box<int>.redirect(5).count + Box<int>.from(6).count;
}
''', 9);

  check(
    'header parameters have initializer scope and fields have body scope',
    '''
int value = 100;
class Fields(int value, final int stored) {
  int initialized = value;
  final int sum;
  this : sum = value + stored {
    initialized += value;
    initialized += stored;
  }
}
int main() {
  final fields = Fields(2, 3);
  return fields.initialized + fields.sum;
}
''',
    12,
  );

  check('initializing formal storage survives initializer arithmetic', '''
class Fields {
  int x;
  int y;
  int z;
  Fields(this.x) : y = x + 1, z = x + 2;
}
int main() {
  final fields = Fields(1);
  return fields.x * 100 + fields.y * 10 + fields.z;
}
''', 123);

  check('super formals are excluded from constructor body scope', '''
int value = 100;
class Base {
  final int inherited;
  Base(int value) : inherited = value;
}
class Ordinary extends Base {
  int seen = 0;
  Ordinary(super.value) { seen = value; }
}
class Primary(super.value) extends Base {
  int seen = 0;
  this { seen = value; }
}
int main() {
  final ordinary = Ordinary(2);
  final primary = Primary(2);
  return ordinary.seen + ordinary.inherited + primary.seen + primary.inherited;
}
''', 204);

  test('unsupported primary late initializer scope is explicit', () {
    expect(
      () => Compiler().compile({
        'primary': {
          'main.dart':
              'class C(int x) { late int y = x; } void main() { C(1); }',
        },
      }),
      throwsA(
        isA<CompileError>().having(
          (error) => error.message,
          'message',
          contains('late field initializers'),
        ),
      ),
    );
  });
}
