import 'package:dart_eval/dart_eval.dart';
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
            void main() {
              double d = 0.0;
              double di = d++;
              print(di);
              print(d);
              int i = 0;
              int ii = i++;
              print(ii);
              print(i);
              List<int> list = [0];
              print(list[0]++);
              print(list[0]);
            }
          ''',
        },
      });

      expect(() {
        runtime.executeLib('package:eval_test/main.dart', 'main');
      }, prints('0.0\n1.0\n0\n1\n0\n1\n'));
    });

    test('i--', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            void main() {
              double d = 1.0;
              double di = d--;
              print(di);
              print(d);
              int i = 1;
              int ii = i--;
              print(ii);
              print(i);
              List<int> list = [1];
              print(list[0]--);
              print(list[0]);
            }
          ''',
        },
      });

      expect(() {
        runtime.executeLib('package:eval_test/main.dart', 'main');
      }, prints('1.0\n0.0\n1\n0\n1\n0\n'));
    });
  });
}
