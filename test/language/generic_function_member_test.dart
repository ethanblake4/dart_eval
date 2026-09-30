import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'generic fields and getters retain explicit and inferred call types',
    () {
      const source = '''
T identity<T extends num>(T value) => value;
int integer(int value) => value;
class Callback {
  T Function<T extends num>(T) invoke;
  final num Function(int) _narrow = integer;
  Callback(this.invoke);
  T Function<T extends num>(T) get callback => invoke;
}
int main() {
  final callback = Callback(identity);
  if (callback._narrow is! int Function(int)) return -1;
  final int narrowed = callback._narrow(3);
  if (narrowed != 3) return -2;
  final int explicit = callback.invoke<int>(3);
  final double inferred = callback.invoke(2.5);
  final int getter = callback.callback<int>(4);
  final record = (invoke: callback.invoke,);
  final int fromRecord = record.invoke<int>(5);
  return explicit * 1000 + inferred.toInt() * 100 + getter * 10 + fromRecord;
}
''';
      final program = Compiler().compile({
        'callback': {'main.dart': source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:callback/main.dart', 'main'), 3245);
      }
    },
  );

  test(
    'arguments run before getter lookup when invoking its function value',
    () {
      const source = '''
T first<T>(T value) => value;
T second<T>(T value) { calls++; return value; }
int calls = 0;
class Callback {
  T Function<T>(T) current = first;
  T Function<T>(T) get invoke => current;
  int change() { current = second; return 7; }
}
int main() {
  final callback = Callback();
  final int result = callback.invoke<int>(callback.change());
  return result * 10 + calls;
}
''';
      final program = Compiler().compile({
        'callback': {'main.dart': source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:callback/main.dart', 'main'), 71);
      }
    },
  );
}
