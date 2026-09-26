import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('a dynamic list index is checked before integer indexing', () {
    final program = Compiler().compile({
      'index': {
        'main.dart': '''
          Object select(dynamic n) => [7, 'other'][n % 2];

          bool main() {
            if (select(0) != 7 || select(1) != 'other') return false;
            dynamic bad = '0';
            try {
              [7][bad];
            } on TypeError {
              return true;
            }
            return false;
          }
        ''',
      },
    });

    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:index/main.dart', 'main'), true);
    }
  });
}
