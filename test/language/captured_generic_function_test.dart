import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('explicit callable object instantiation retains override defaults', () {
    final program = Compiler().compile({
      'captured_generics': {
        'main.dart': '''
String selected = '';
class Callable {
  T call<T>(T value, {String label = 'base'}) => value;
}
class Child extends Callable {
  T call<T>(T value, {String label = 'child'}) {
    selected = label;
    return value;
  }
}
Function specialize(Callable value) => value<String>;
bool main() {
  final function = specialize(Child());
  if (function is! String Function(String, {String label})) return false;
  if (function('first') != 'first' || selected != 'child') return false;
  return function('second', label: 'supplied') == 'second' && selected == 'supplied';
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:captured_generics/main.dart', 'main'),
        true,
      );
    }
  });
  test('stored generic instantiations use the selected closure defaults', () {
    final program = Compiler().compile({
      'captured_generics': {
        'main.dart': '''
          num positional(bool second) {
            num first<T extends num>([num value = 7]) => value;
            num other<T extends num>([num value = 11]) => value;
            final selected = second ? other : first;
            final instantiated = selected<int>;
            return instantiated();
          }
          num named(bool second) {
            num first<T extends num>({num value = 13}) => value;
            num other<T extends num>({num value = 17}) => value;
            final selected = second ? other : first;
            final instantiated = selected<int>;
            return instantiated();
          }
          num main() => positional(false) + positional(true) +
              named(false) + named(true);
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:captured_generics/main.dart', 'main'),
        48,
      );
    }
  });

  test('captured local functions retain their own generic bounds', () {
    final program = Compiler().compile({
      'captured_generics': {
        'main.dart': '''
          int main() {
            T number<T extends num>(T value) => value;
            B text<A extends String, B extends A>(A first, B second) => second;
            final callNumber = () => number<int>(2);
            final callText = () => text<String, String>('first', 'last');
            return callNumber() + callText().length;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:captured_generics/main.dart', 'main'),
        6,
      );
    }
  });
}
