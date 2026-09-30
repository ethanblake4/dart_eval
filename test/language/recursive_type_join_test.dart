import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void _run(String body, int expected) {
  final program = Compiler().compile({
    'joins': {
      'main.dart':
          '''
import 'dart:async';
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T exact<R extends Exactly<T>>() => this;
}
$body
''',
    },
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib('package:joins/main.dart', 'main'), expected);
  }
}

void main() {
  test('function and union joins preserve object nullability', () {
    _run('''
Object choose(bool condition, int Function(int) x, FutureOr<Function> y) {
  var z = condition ? x : y;
  z.exact<Exactly<Object>>();
  return z;
}
Object? nullable(bool condition, FutureOr<Function?> x, int Function(int) y) {
  var z = condition ? x : y;
  z.exact<Exactly<Object?>>();
  if (z == null) return null;
  z.exact<Exactly<Object>>();
  return z;
}
int main() {
  final identity = (int value) => value;
  var count = 0;
  if (choose(true, identity, identity) == identity) count++;
  if (nullable(true, null, identity) == null) count++;
  if (nullable(false, null, identity) == identity) count++;
  return count;
}
''', 3);
  });

  test('recursive union bounds terminate and close only their parameter', () {
    _run('''
int recursive<X extends FutureOr<X>>(X x, FutureOr<Object> y, bool condition) {
  var same = condition ? x : ((throw 0) as FutureOr<X>);
  same.exact<Exactly<FutureOr<X>>>();
  var joined = condition ? x : y;
  joined.exact<Exactly<FutureOr<Object?>>>();
  var reversed = condition ? y : x;
  reversed.exact<Exactly<FutureOr<Object?>>>();
  return joined == x && reversed == y ? 1 : 0;
}
int nullable<X extends FutureOr<X?>>(X x, FutureOr<Object> y, bool condition) {
  var joined = condition ? x : y;
  joined.exact<Exactly<FutureOr<Object?>>>();
  return joined == x ? 1 : 0;
}
FutureOr<num> widen<X extends FutureOr<int>>(X value) => value;
int main() => recursive<int>(1, 2, true) + nullable<int?>(null, 2, true) +
    (widen<FutureOr<int>>(3) == 3 ? 1 : 0);
''', 3);
  });
}
