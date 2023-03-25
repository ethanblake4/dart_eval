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
  });
}
