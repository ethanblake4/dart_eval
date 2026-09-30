import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('captures const scalars after later initializers unbox them', () {
    final program = Compiler().compile({
      'const_capture': {
        'main.dart': '''
        class Value {
          final Object value;
          const Value(this.value);
        }

        bool Function() makeClosure() {
          const min = 2 - 1;
          const max = 8 * 2;
          const mask = (1 << (max - min + 1)) - 1;
          bool check() {
            const text = 'min = \$min, max = \$max, mask = \$mask';
            const value = Value(text);
            return min == 1 && max == 16 && mask == 65535 &&
                text == 'min = 1, max = 16, mask = 65535' &&
                identical(value, const Value(
                    'min = \$min, max = \$max, mask = \$mask'));
          }
          return check;
        }

        bool main() => makeClosure()();
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:const_capture/main.dart', 'main'),
        true,
      );
    }
  });
}
