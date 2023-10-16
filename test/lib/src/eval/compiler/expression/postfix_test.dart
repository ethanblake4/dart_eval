import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Postfix', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('i++', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            num main() {
              var d = 0.0;
              d++;
              var i = 0;
              i++;
              return i + d;
            }
          '''
        }
      });

      expect(
        runtime.executeLib('package:eval_test/main.dart', 'main'),
        // ignore: unnecessary_cast
        equals($num(2 as num)),
      );
    });

    test('i--', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            num main() {
              var d = 1.0;
              d--;
              var i = 1;
              i--;
              return i + d;
            }
          '''
        }
      });

      expect(
        runtime.executeLib('package:eval_test/main.dart', 'main'),
        // ignore: unnecessary_cast
        equals($num(0 as num)),
      );
    });
  });
}
