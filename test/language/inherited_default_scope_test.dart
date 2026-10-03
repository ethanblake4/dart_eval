import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'escaping local defaults retain lexical constants and formal shadowing',
    () {
      final program = Compiler().compile({
        'defaults': {
          'main.dart': '''
Function make() {
  const values = <int>[3, 5];
  const alias = values;
  const seed = 7;
  int sum([List<int> values = alias, int seed = seed]) =>
      values[0] + values[1] + seed;
  return sum;
}
int main() {
  dynamic sum = make();
  return sum() + sum(<int>[1, 1], 4);
}
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:defaults/main.dart', 'main'), 21);
      }
    },
  );

  test(
    'inherited defaults resolve static constants in their declaring class',
    () {
      final program = Compiler().compile({
        'defaults': {
          'main.dart': '''
import 'target.dart';
abstract class Factory {
  static const values = [99];
  factory Factory([List<int> value]) = Target;
  List<int> get value;
}
abstract class ScalarFactory {
  factory ScalarFactory([int value]) = Target.number;
  List<int> get value;
}
class Derived extends Target {
  static const values = [88];
  Derived([super.value]);
}
class Caller {
  static const values = [77];
  static int call() {
    final values = [66];
    final make = Factory.new;
    dynamic dynamicMake = make;
    final derived = Derived.new;
    dynamic dynamicDerived = derived;
    Factory dynamicFactory = dynamicMake();
    Derived dynamicChild = dynamicDerived();
    final scalarMake = ScalarFactory.new;
    dynamic dynamicScalarMake = scalarMake;
    ScalarFactory dynamicScalar = dynamicScalarMake();
    return Factory().value[0] + make().value[0] + dynamicFactory.value[0] +
        Derived().value[0] + derived().value[0] + dynamicChild.value[0] +
        ScalarFactory().value[0] + scalarMake().value[0] + dynamicScalar.value[0] +
        values[0];
  }
}
int main() => Caller.call();
''',
          'target.dart': '''
import 'main.dart';
const values = 91;
const scalar = 92;
class Target implements Factory, ScalarFactory {
  static const values = [3];
  static const scalar = 4;
  final List<int> value;
  Target([this.value = values]);
  Target.number([int value = scalar]) : value = [value];
}
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:defaults/main.dart', 'main'), 96);
      }
    },
  );

  test('omitted bounded factory parameters retain their erased slots', () {
    final program = Compiler().compile({
      'defaults': {
        'main.dart': '''
abstract class Factory<T extends int> {
  factory Factory([T value]) = Target<T>;
  int get value;
}
class Target<T extends int> implements Factory<T> {
  final int value;
  Target([this.value = 7]);
}
int main() {
  final make = Factory<int>.new;
  dynamic dynamicMake = make;
  Factory<int> value = dynamicMake();
  return Factory<int>().value + make().value + value.value;
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:defaults/main.dart', 'main'), 21);
    }
  });

  test('constant defaults exclude the calling function type parameters', () {
    final program = Compiler().compile({
      'defaults': {
        'main.dart': '''
class Element {}
abstract class Factory {
  factory Factory([List<Element> values]) = Target;
  List<Element> get values;
}
class Target implements Factory {
  final List<Element> values;
  Target([this.values = const <Element>[]]);
}
int check(Factory value) => value.values is List<Element> ? 1 : 0;
int make<Element>() {
  final direct = Factory();
  final factory = Factory.new;
  final staticValue = factory();
  dynamic dynamicFactory = factory;
  Factory dynamicValue = dynamicFactory();
  final own = <Element>[];
  return check(direct) + check(staticValue) + check(dynamicValue) +
      (own is List<int> ? 1 : 0);
}
int main() => make<int>();
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:defaults/main.dart', 'main'), 4);
    }
  });
}
