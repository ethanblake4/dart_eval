import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  group('Top-level variable tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Assignment to top-level variable', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            var x = 1;
            void main() {
              x = 3;
              print(x);
            }
          '''
        }
      });

      expect(() => runtime.executeLib('package:eval_test/main.dart', 'main'),
          prints('3\n'));
    });
  });
}
