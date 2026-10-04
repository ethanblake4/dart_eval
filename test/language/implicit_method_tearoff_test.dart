import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  for (final abstractMethod in [true, false]) {
    test('implicit private method tear-off dispatches an override '
        'with ${abstractMethod ? "abstract" : "concrete"} base', () {
      final program = Compiler().compile({
        'implicit_tearoff': {
          'main.dart':
              '''
            abstract class _Base<T> {
              _Base();
              factory _Base.named(T value) => _Derived<T>(value);
              T _create() ${abstractMethod ? ';' : "=> throw 'base';"}
              T read() {
                final T Function() callback = _create;
                return callback();
              }
            }
            class _Derived<T> extends _Base<T> {
              final T value;
              _Derived(this.value);
              T _create() => value;
            }
            int main() => _Base<int>.named(42).read();
          ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:implicit_tearoff/main.dart', 'main'),
          42,
        );
      }
    });
  }
}
