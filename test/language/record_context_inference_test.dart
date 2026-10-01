import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = '''
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T expectStaticType<R extends Exactly<T>>() => this;
}
Type typeOf<T>() => T;
Type fromValue<T>(T value) => T;
Type inferredCaller<T>(T value) => fromValue(value);
bool callerEnvironment() =>
    inferredCaller<double>(1) == double && inferredCaller<int>(1) == int;
({T foo}) f<T>(T x) => (foo: x);
(T,) single<T>(T x) => (x,);
(T, {T foo}) mixed<T>(T x) => (x, foo: x);
({T foo, S bar}) pair<T, S>(T x, S y) => (foo: x, bar: y);
({({T foo}) nested}) nested<T>(T x) => (nested: f(x));
bool matching() {
  Object y = (foo: 0.5);
  if (y is ({double foo})) {
    y = f(1..expectStaticType<Exactly<double>>());
    y.expectStaticType<Exactly<({double foo})>>();
    return y.runtimeType == typeOf<({double foo})>() && y.foo == 1.0;
  }
  return false;
}
bool mismatchedNames() {
  Object y = (bar: 0.5);
  if (y is ({double bar})) {
    y = f(1..expectStaticType<Exactly<int>>());
    y.expectStaticType<Exactly<Object>>();
    return y.runtimeType == typeOf<({int foo})>();
  }
  return false;
}
bool mismatchedCounts() {
  Object y = (0.5, 2);
  if (y is (double, int)) {
    y = single(1..expectStaticType<Exactly<int>>());
    y.expectStaticType<Exactly<Object>>();
    return y.runtimeType == typeOf<(int,)>();
  }
  return false;
}
bool mismatchedMixedNames() {
  Object y = (0.5, bar: 0.5);
  if (y is (double, {double bar})) {
    y = mixed(1..expectStaticType<Exactly<int>>());
    y.expectStaticType<Exactly<Object>>();
    return y.runtimeType == typeOf<(int, {int foo})>();
  }
  return false;
}
bool matchingPositional() {
  (double,) y = single(1);
  return y.runtimeType == typeOf<(double,)>() && y.\$1 == 1.0;
}
bool reorderedNames() {
  ({double bar, int foo}) y = pair(1, 2);
  return y.runtimeType == typeOf<({int foo, double bar})>() &&
      y.foo == 1 && y.bar == 2.0;
}
bool nestedContext() {
  ({({double foo}) nested}) y = nested(1);
  return y.runtimeType == typeOf<({({double foo}) nested})>() &&
      y.nested.foo == 1.0;
}
''';

void main() {
  test(
    'record downward inference requires matching field names and counts',
    () {
      final program = Compiler().compile({
        'records': {'main.dart': _source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        for (final entry in [
          'matching',
          'mismatchedNames',
          'mismatchedCounts',
          'mismatchedMixedNames',
          'matchingPositional',
          'reorderedNames',
          'nestedContext',
          'callerEnvironment',
        ]) {
          expect(
            runtime.executeLib('package:records/main.dart', entry),
            true,
            reason: entry,
          );
        }
      }
    },
  );
}
