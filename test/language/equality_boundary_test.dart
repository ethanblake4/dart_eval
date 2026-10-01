import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const source = r'''
bool equal(Object? left, Object? right) => left == right;
bool unequal(Object? left, Object? right) => left != right;
bool same(Object? left, Object? right) => identical(left, right);
Type argumentType<T>() => T;
class Plain { const Plain(); }
class Base {
  Object identity() => this;
  bool same(Object other) => super == other;
}
class Child extends Base {}
class ConstantEquality {
  const ConstantEquality(Object? left, Object? right) : value = left == right;
  final bool value;
}
int calls = 0;
class Overridden {
  bool operator ==(Object other) { calls++; return true; }
  int get hashCode => 0;
}
class CustomType implements Type {
  const CustomType();
  bool operator ==(Object other) => identical(this, other);
  int get hashCode => 0;
}
enum Choice { first, second }
int topLevel(int value) => value;
Function closure(int value) => () => value;
int main() {
  const plain = Plain();
  if (!const ConstantEquality(plain, plain).value) return -1;
  if (const ConstantEquality(true, plain).value) return -2;
  for (final primitive in <Object?>[null, true, 1, 1.5, '', Choice.first, int]) {
    if (equal(primitive, plain) || equal(plain, primitive)) return -3;
    if (!unequal(primitive, plain) || !unequal(plain, primitive)) return -4;
    if (same(primitive, plain) || same(plain, primitive)) return -5;
  }
  if (!equal(plain, plain) || !same(plain, plain)) return -6;
  if (equal(Plain(), Plain()) || same(Plain(), Plain())) return -7;
  if (!equal(null, null) || unequal(null, null) || !same(null, null)) return -8;
  if (!equal(Choice.first, Choice.first) || equal(Choice.first, Choice.second)) return -9;
  if (!same(Choice.first, Choice.first) || same(Choice.first, Choice.second)) return -10;
  final overridden = Overridden();
  if (!equal(overridden, plain) || calls != 1) return -11;
  if (equal(1, overridden) || calls != 1) return -12;
  if (same(overridden, plain) || calls != 1) return -13;
  if (equal(overridden, null) || calls != 1) return -14;
  final type = argumentType<int>();
  if (!equal(type, int) || unequal(type, int) || !same(type, int)) return -15;
  if (equal(type, String) || same(type, String)) return -16;
  const custom = CustomType();
  if (equal(custom, int) || same(custom, int) || same(int, custom)) return -17;
  if (!equal(custom, custom) || !same(custom, custom)) return -18;
  const types = <Type, int>{int: 1, String: 2};
  if (types[type] != 1 || types[String] != 2) return -19;
  final first = closure(1);
  final second = closure(1);
  if (!equal(first, first) || !same(first, first)) return -20;
  if (equal(first, second) || same(first, second)) return -21;
  if (equal(first, plain) || equal(plain, first) || same(first, plain)) return -22;
  if (!equal(topLevel, topLevel) || !same(topLevel, topLevel)) return -23;
  if (equal(topLevel, plain) || equal(plain, topLevel)) return -24;
  final child = Child();
  dynamic dynamicChild = child;
  final identity = dynamicChild.identity();
  if (!equal(identity, child) || !same(identity, child)) return -25;
  if (!child.same(child) || child.same(Child())) return -26;
  return 0;
}
''';

void main() {
  test(
    'equality keeps guest values boxed at Object and identical boundaries',
    () {
      final program = Compiler().compile({
        'equality': {'main.dart': source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:equality/main.dart', 'main'), 0);
      }
    },
  );
}
