import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'super callable getters preserve context and check before arguments',
    () {
      final program = Compiler().compile({
        'super_callable': {
          'main.dart': r'''
class Base {
  double Function(double) get callable;
  dynamic noSuchMethod(Invocation invocation) => (double value) => value;
}
class Child extends Base {
  String log = '';
  dynamic noSuchMethod(Invocation invocation) {
    log += 'g';
    if (!invocation.isGetter || invocation.memberName != #callable) return null;
    return (double value) { log += 'f'; return value + 1; };
  }
  double argument() { log += 'a'; return 2; }
  double literal() => super.callable(2);
  double ordered() => super.callable(argument());
}
class Invalid extends Base {
  String log = '';
  dynamic noSuchMethod(Invocation invocation) { log += 'g'; return 'invalid'; }
  double argument() { log += 'a'; return 2; }
  double invoke() => super.callable(argument());
}
bool main() {
  final child = Child();
  if (child.literal() != 3 || child.log != 'gf') return false;
  child.log = '';
  if (child.ordered() != 3 || child.log != 'gaf') return false;
  final invalid = Invalid();
  try { invalid.invoke(); } on TypeError { return invalid.log == 'g'; }
  return false;
}
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:super_callable/main.dart', 'main'),
          true,
        );
      }
    },
  );

  test('abstract super getters dispatch and check their declared result', () {
    final program = Compiler().compile({
      'super_getter': {
        'main.dart': r'''
class Base {
  int get value;
  dynamic noSuchMethod(Invocation invocation) => 42;
}
class Child extends Base {
  int calls = 0;
  dynamic noSuchMethod(Invocation invocation) {
    if (!invocation.isGetter || invocation.isMethod || invocation.isSetter ||
        invocation.memberName != #value ||
        invocation.positionalArguments.isNotEmpty ||
        invocation.namedArguments.isNotEmpty ||
        invocation.typeArguments.isNotEmpty) return -100;
    calls++;
    return 7;
  }
  int get value => super.value + 1;
}
class Grandchild extends Child {
  dynamic noSuchMethod(Invocation invocation) => 9;
}
class ConcreteAncestor { int get value => 3; }
abstract class Redeclared extends ConcreteAncestor { int get value; }
class ConcreteChild extends Redeclared {
  dynamic noSuchMethod(Invocation invocation) => 99;
  int get value => super.value + 1;
}
class GenericBase<T> {
  T get value;
  dynamic noSuchMethod(Invocation invocation) => null;
}
class GenericChild extends GenericBase<int> {
  dynamic noSuchMethod(Invocation invocation) => 11;
  int get value => super.value + 2;
}
class InvalidChild extends Base {
  dynamic noSuchMethod(Invocation invocation) => 'invalid';
  Object read() => super.value;
}
bool main() {
  final child = Child();
  if (child.value != 8 || child.calls != 1 || Grandchild().value != 10 ||
      ConcreteChild().value != 4 || GenericChild().value != 13) return false;
  try { InvalidChild().read(); } on TypeError { return true; }
  return false;
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:super_getter/main.dart', 'main'),
        true,
      );
    }
  });
}
