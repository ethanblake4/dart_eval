import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  group('Expression tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('"is" expression', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            void main() {
              print(1 is int);
              print(2 is! String);
              print([] is List);
              print(RegExp(r'.*') is RegExp);
              print(RegExp(r'.*') is! RegExp);
              print(RegExp(r'.*') is String);
              print(Y() is X);
              print(X() is Y);
            }

            class X {
              X();
            }

            class Y extends X {
              Y();
            }
          '''
        }
      });

      expect(() {
        runtime.executeLib('package:eval_test/main.dart', 'main');
      }, prints('true\ntrue\ntrue\ntrue\nfalse\nfalse\ntrue\nfalse\n'));
    });

    test('Is num', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            num main () {
              var myfunc = ([dynamic a, dynamic b, dynamic c]) {
                if(a is num && b is num){
                  return a + b;
                }
                return 0;
              };
              return myfunc(2, 4);
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), 6);
    });

    test('Null coalescing operator', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            void main() {
              print(null ?? 1);
              print(2 ?? 1);
            }
          '''
        }
      });

      expect(() {
        runtime.executeLib('package:eval_test/main.dart', 'main');
      }, prints('1\n2\n'));
    });

    test("Not expression", () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            void main() {
              print(!true);
              print(!false);
            }
          '''
        }
      });

      expect(() {
        runtime.executeLib('package:eval_test/main.dart', 'main');
      }, prints('false\ntrue\n'));
    });

    test('Bitwise int operators', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            void main() {
              print(1 & 2);
              print(1 | 2);
              print(1 << 2);
              print(1 >> 2);
            }
          '''
        }
      });

      expect(() {
        runtime.executeLib('package:eval_test/main.dart', 'main');
      }, prints('0\n3\n4\n0\n'));
    });
  });
}
