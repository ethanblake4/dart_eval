import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('private accessors dispatch on nonleaf receivers in their library', () {
    final program = Compiler().compile({
      'private_accessor': {
        'main.dart': r'''
class Base {
  int storage = 0;
  int get _value { return storage + 1; }
  set _value(int value) { storage = value - 1; }
}
class Child extends Base {}
int exercise(Base value) {
  value._value = 7;
  return value._value;
}
int main() => exercise(Child());
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:private_accessor/main.dart', 'main'),
        7,
      );
    }
  });

  test('inherited private accessors retain their defining library', () {
    final program = Compiler().compile({
      'private_inherited_accessor': {
        'base.dart': r'''
class Base {
  int storage = 0;
  int get _value { return storage + 1; }
  set _value(int value) { storage = value - 1; }
}
int exerciseBase(Base value) {
  value._value = 7;
  return value._value;
}
''',
        'main.dart': r'''
import 'base.dart';
class Child extends Base {
  int ownStorage = 0;
  int get _value { return ownStorage + 10; }
  set _value(int value) { ownStorage = value - 10; }
}
int exerciseChild(Child value) {
  value._value = 23;
  return value._value;
}
int main() {
  final child = Child();
  if (exerciseBase(child) != 7) return -1;
  if (exerciseChild(child) != 23) return -2;
  return exerciseBase(child) + exerciseChild(child);
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib(
          'package:private_inherited_accessor/main.dart',
          'main',
        ),
        30,
      );
    }
  });

  test('folded private accessor collisions keep independent state', () {
    final program = Compiler().compile({
      'private_mixin_accessor': {
        'mixin.dart': r'''
int mixinStorage = 0;
mixin Secret {
  int get _value { return mixinStorage + 1; }
  set _value(int value) { mixinStorage = value - 1; }
  int exerciseMixin() {
    _value = 7;
    return _value;
  }
}
''',
        'main.dart': r'''
import 'mixin.dart';
class Host with Secret {
  int hostStorage = 0;
  int get _value { return hostStorage + 10; }
  set _value(int value) { hostStorage = value - 10; }
}
class Child extends Host {}
int exerciseHost(Host value) {
  value._value = 23;
  return value._value;
}
int main() {
  final child = Child();
  if (child.exerciseMixin() != 7) return -1;
  if (exerciseHost(child) != 23) return -2;
  return child.exerciseMixin() + exerciseHost(child);
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:private_mixin_accessor/main.dart', 'main'),
        30,
      );
    }
  });
}
