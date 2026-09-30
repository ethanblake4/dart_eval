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

  check('declaring callbacks retain parameter and mutable field scope', '''
int twice(int value) => value * 2;
int triple(int value) => value * 3;
class Callback(var int invoke(int value)) {
  int Function(int) initial = invoke;
  int call(int value) => invoke(value);
}
int main() {
  final callback = Callback(twice);
  callback.invoke = triple;
  return callback.initial(4) * 10 + callback.call(4);
}
''', 92);

  check('generic declaring callback retains its type parameters', '''
T identity<T extends num>(T value) => value;
class Callback(final T invoke<T extends num>(T value));
int main() {
  final callback = Callback(identity);
  final int integer = callback.invoke<int>(3);
  final double decimal = callback.invoke<double>(2.5);
  return integer * 10 + decimal.toInt();
}
''', 32);

  check('nullable callbacks and defaults survive constructor tearoffs', '''
int twice(int value) => value * 2;
class Callback([final int invoke(int value)? = twice]);
int main() {
  final create = Callback.new;
  dynamic dynamicCreate = create;
  final first = create();
  final missing = create(null);
  final third = dynamicCreate(twice);
  if (missing.invoke != null) return -1;
  return first.invoke!(3) * 10 + (third.invoke(4) as int);
}
''', 68);

  check('class and callback type parameters remain distinct', '''
T identity<T>(T value) => value;
class Callback<T>(final T invoke(T value), final U other<U>(U value));
int main() {
  final callback = Callback<int>(identity, identity);
  return callback.invoke(5) * 10 + callback.other<int>(7);
}
''', 57);
}
