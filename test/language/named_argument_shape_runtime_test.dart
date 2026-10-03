import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('one named argument still checks required names', () {
    final program = Compiler().compile({
      'named_shapes': {
        'main.dart': '''
          class C {
            int call({required int requiredValue, int optional = 3}) =>
                requiredValue + optional;
          }
          bool main() {
            dynamic callable = C();
            if (callable(requiredValue: 2) != 5) return false;
            try {
              callable(optional: 2);
              return false;
            } on NoSuchMethodError {
              return callable(requiredValue: 2, optional: 4) == 6;
            }
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:named_shapes/main.dart', 'main'),
        true,
      );
    }
  });
}
