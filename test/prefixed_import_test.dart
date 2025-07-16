import 'package:dart_eval/dart_eval.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Prefixed imports', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Importing constant via prefix', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            import 'package:eval_test/chars.dart' as chars;

            void main() {
              if (chars.plus == 0x2b) {
                print('Plus is correct');
              } else {
                print('Plus is incorrect');
              }
            }
          ''',
          'chars.dart': '''
            const plus = 0x2b;
            const minus = 0x2d;
            const period = 0x2e;
            const slash = 0x2f;
          '''
        }
      });

      expect(
        () {
          runtime.executeLib('package:eval_test/main.dart', 'main');
        },
        prints('Plus is correct\n'),
      );
    });
  });
}
