import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('constructor schema holes finalize before runtime type emission', () {
    final program = Compiler().compile({
      'constructor_schema': {
        'main.dart': '''
          class BGeneric<X> {
            const BGeneric();
          }
          class Box<T> {
            final T value;
            Box(this.value);
          }
          Type argumentOf<X>(BGeneric<X> x,
              {required BGeneric<List<X>> y}) => X;
          Box<T> lexical<T>(T value) => Box(value);
          BGeneric<List<T>> lexicalNested<T>() => BGeneric();
          int main() {
            if (argumentOf(const BGeneric(), y: const BGeneric()) != dynamic) {
              return -1;
            }
            if (argumentOf(y: const BGeneric(), const BGeneric()) != dynamic) {
              return -2;
            }
            if (argumentOf(const BGeneric<int>(),
                y: const BGeneric<List<int>>()) != int) return -3;
            if (argumentOf(y: const BGeneric<List<String>>(),
                const BGeneric<String>()) != String) return -4;
            final box = lexical<int>(7);
            if (box is! Box<int>) return -5;
            if (lexicalNested<String>() is! BGeneric<List<String>>) return -6;
            return box.value;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:constructor_schema/main.dart', 'main'),
        7,
      );
    }
  });
}
