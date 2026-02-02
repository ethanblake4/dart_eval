import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  group('Regular classes test', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Final fields test', () {
      final runtime = compiler.compileWriteAndLoad({
        'field_test': {
          'main.dart': '''
          class Test {
            final int value;
            Test(this.value);
          }
          
          class Test2 {
            final int value;
            Test2(): value = 2;
          }
          
          void main() {
            print(Test(3).value);
            print(Test2().value);
          }
          ''',
        },
      });

      expect(() {
        runtime.executeLib('package:field_test/main.dart', 'main');
      }, prints('3\n2\n'));
    });

    test('Late fields test', () {
      final runtime = compiler.compileWriteAndLoad({
        'field_test': {
          'main.dart': '''
          class Test {
            late int value;
            Test(int init) {
              value = init;
            }
          }
          
          class Test2 {
            late final int value;
            Test2() {
              value = 2;
            }
          }
          
          void main() {
            print(Test(3).value);
            print(Test2().value);
          }
          ''',
        },
      });

      expect(() {
        runtime.executeLib('package:field_test/main.dart', 'main');
      }, prints('3\n2\n'));
    }, skip: true);
  });
}
