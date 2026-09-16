import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  group('Function tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Simple tearoff', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              var fn = fun;
              return fn(4);
            }
            
            int fun(int a) {
              return a + 1;
            }
           ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 5);
    });

    test('Tearoff as argument', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              return fun(4, fun2);
            }
            
            int fun(int a, Function fn) {
              return fn(a) + 1;
            }

            int fun2(int a) {
              return a + 2;
            }
           ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 7);
    });

    test('Method tearoffs', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              return M(4).run();
            }
            
            class M {
              M(this.x);
              
              final int x;
              
              int run() {
                return load(x, add);
              }

              int load(int y, Function op) {
                return op(y) + 1;
              }

              int add(int y) {
                return y + 5;
              }
            }
            
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 10);
    });
  });
}
