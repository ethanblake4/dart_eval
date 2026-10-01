import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = '''
T identityGeneric<T>(T value) => value;
Object identity(Object value) => value;
Object foo(f(Object a), Object a) => f(a);
Object explicitDynamic(dynamic f(Object a), Object a) => f(a);
dynamic nested(f(g(Object a)), g(Object a)) => f(g);
dynamic consume(g(Object a)) => g(3);
Object optional([f(Object a) = identity]) => f(4);
Object named({required f(Object a)}) => f(5);
Object generic(f<T>(T a), Object a) => f<Object>(a);
class Holder {
  dynamic Function(Object) callback;
  Holder(this.callback);
  Object run() => callback(6);
}
class Parent {
  dynamic Function(Object) callback;
  Parent(this.callback);
}
class Child extends Parent {
  Child(super.callback);
  Object run() => callback(8);
}
class Receiver<T> {
  join<V>(T first, int second, V third) =>
      first.toString() + second.toString() + third.toString();
  accept<U>(callback<V>(T first, U second, V third)) =>
      callback<int>(1 as T, 2 as U, 3);
}
class DerivedReceiver<T> extends Receiver<T> {}
bool genericMembers() {
  final receiver = Receiver<int>();
  final derived = DerivedReceiver<int>();
  return receiver.accept<int>(receiver.join) == '123' &&
      derived.accept<int>(derived.join) == '123';
}
int accepted() {
  final local = (f(Object a), Object a) => f(a);
  return (foo(identity, 1) as int) +
      (explicitDynamic(identity, 2) as int) +
      (nested(consume, identity) as int) +
      (optional() as int) +
      (named(f: identity) as int) +
      (Holder(identity).run() as int) +
      (generic(identityGeneric, 7) as int) +
      (Child(identity).run() as int) +
      (local(identity, 9) as int);
}
bool rejectedDirect() {
  dynamic callback = identityGeneric;
  try { foo(callback, 1); } on TypeError { return true; }
  return false;
}
bool rejectedTearoff() {
  dynamic target = foo;
  dynamic callback = identityGeneric;
  try { target(callback, 1); } on TypeError { return true; }
  return false;
}
bool rejectedNested() {
  dynamic callback = identityGeneric;
  try { nested(consume, callback); } on TypeError { return true; }
  return false;
}
bool rejectedOptional() {
  dynamic callback = identityGeneric;
  try { optional(callback); } on TypeError { return true; }
  return false;
}
bool rejectedNamed() {
  dynamic target = named;
  dynamic callback = identityGeneric;
  try { target(f: callback); } on TypeError { return true; }
  return false;
}
bool rejectedField() {
  dynamic callback = identityGeneric;
  try { Holder(callback); } on TypeError { return true; }
  return false;
}
bool rejectedSuper() {
  dynamic callback = identityGeneric;
  try { Child(callback); } on TypeError { return true; }
  return false;
}
''';

void main() {
  test('omitted-return legacy callback formals retain their signatures', () {
    final program = Compiler().compile({
      'legacy': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:legacy/main.dart', 'accepted'), 45);
      expect(
        runtime.executeLib('package:legacy/main.dart', 'genericMembers'),
        true,
      );
      for (final entry in [
        'rejectedDirect',
        'rejectedTearoff',
        'rejectedNested',
        'rejectedOptional',
        'rejectedNamed',
        'rejectedField',
        'rejectedSuper',
      ]) {
        expect(
          runtime.executeLib('package:legacy/main.dart', entry),
          true,
          reason: entry,
        );
      }
    }
  });
}
