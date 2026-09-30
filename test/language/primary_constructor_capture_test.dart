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

  check(
    'declaration and list closures capture parameters, body captures fields',
    '''
class Values(var String value) {
  String Function() declaration = () => value;
  String Function() initializer;
  String Function()? body;
  this : initializer = (() => value) { body = () => value; }
}
String main() {
  final values = Values('old');
  final before = values.declaration() + values.initializer() + values.body!();
  values.value = 'new';
  return before + ':' + values.declaration() + values.initializer() + values.body!();
}
''',
    'oldoldold:oldoldnew',
  );

  check(
    'mutable primary parameters share captures without capturing same-named fields',
    '''
class Values(int value) {
  int Function() declaration = () => value;
  int Function() initializer;
  int Function()? increment;
  int value = 100;
  this : initializer = (() => value) {
    value += 10;
    increment = () => ++value;
  }
}
int main() {
  final values = Values(1);
  final first = values.declaration();
  final changed = values.increment!();
  final latest = values.declaration();
  if (values.initializer() != latest) return -1;
  return first * 10000 + changed * 1000 + latest * 100 + values.value;
}
''',
    123300,
  );

  check(
    'ordinary initializer-list and body captures retain distinct bindings',
    '''
class Values {
  String value;
  String Function() initializer;
  String Function()? body;
  Values(this.value) : initializer = (() => value) { body = () => value; }
}
String main() {
  final values = Values('old');
  values.value = 'new';
  return values.initializer() + ':' + values.body!();
}
''',
    'old:new',
  );

  check('super initializer captures exclude the constructor body binding', '''
int value = 100;
class Base { Base(int value); }
class Derived extends Base {
  int Function() initializer;
  int Function()? body;
  Derived(super.value) : initializer = (() => value) { body = () => value; }
}
int main() {
  final value = Derived(2);
  return value.initializer() + value.body!();
}
''', 102);

  test('initializing and super formal bindings are final in initializer scope', () {
    for (final source in [
      'class C { int x; int y; C(this.x) : y = (x = 2); } void main() { C(1); }',
      'class B { B(int x); } class C extends B { int y; C(super.x) : y = (x = 2); } void main() { C(1); }',
      'class C(var int x) { int Function() change = () => ++x; } void main() { C(1); }',
    ]) {
      expect(
        () => Compiler().compile({
          'primary': {'main.dart': '// @dart=3.13\n$source'},
        }),
        throwsA(isA<CompileError>()),
      );
    }
  });
}
