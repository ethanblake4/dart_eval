import 'package:dart_eval/dart_eval.dart';
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

  check(
    'extension bodies return locally and factories preserve representation',
    r'''
final events = <int>[];
extension type Scalar<T>(T value) {
  this {
    events.add(1);
    if (value is int) return;
    events.add(2);
  }
  factory Scalar.wrap(T value) => Scalar<T>(value);
  factory Scalar.block(T value) {
    try { return Scalar<T>(value); }
    finally { events.add(3); }
  }
  factory Scalar.redirect(T value) = Scalar<T>;
}
extension type const Checked.named(int value) {
  this : assert(value > 0);
  const factory Checked.redirect(int value) = Checked.named;
}
int main() {
  final first = Scalar<int>.wrap(4);
  final second = Scalar<String>.block('ok');
  final make = Scalar<int>.redirect;
  final third = make(5);
  const checked = Checked.redirect(4);
  final checkedMake = Checked.named;
  var caught = false;
  try { Checked.named(-1); } on AssertionError { caught = true; }
  if (first.value != 4 || second.value != 'ok' || third.value != 5 ||
      !identical(checked, 4) || checkedMake(5).value != 5 || !caught) return -1;
  return events.fold(0, (result, event) => result * 10 + event);
}
''',
    11231,
  );

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

  check(
    'enum headers preserve defaults and captured initializer parameters',
    '''
enum Gauge({final int a = 2, required final int b}) {
  first(b: 3), second(a: 4, b: 5);
  final int doubled = b * 2;
  final int Function() total = () => a + b;
  final int sum;
  this : sum = a + b;
}
int main() => Gauge.first.doubled + Gauge.first.total() +
    Gauge.first.sum + Gauge.second.total();
''',
    25,
  );

  check('declaring parameter defaults infer field types', '''
class Named({final x = 1, var y = 2});
enum Optional([final x = 3]) { first, second(4); }
bool main() => [Named().x, Named().y, Optional.first.x] is List<int>;
''', true);

  check('covariant declaring fields permit narrower interface setters', '''
class Wide(covariant var num value);
class Narrow(var int value) implements Wide;
int main() {
  Wide first = Narrow(4);
  first.value = 5;
  try { first.value = 2.5; } on TypeError { return first.value.toInt(); }
  return 0;
}
''', 5);

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
}
