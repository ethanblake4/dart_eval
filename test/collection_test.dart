import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Collection tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Collection if', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final i = 3, k = 2, l = 1;

              var list = [
                if (i == 3) 1, 
                if (k == 2) 2, 
                if (l == 1) 3 else if (k == 2) 4,
                if (l == 2) 5 else 6,
                if (l == 2) 7 else if (k == 2) 8,
              ];

              return list.join();
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), $String('12368'));
    });

    test('Collection for', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final j = 3, k = 2, l = 1;

              var list = [
                for (var i = 0; i < 3; i = i + 1) i,
                for (var i = 0; i < 3; i = i + 1) if (i == 1) i,
                for (var i = 0; i < 3; i = i + 1) if (i == 1) j else i,
                for (var i = 0; i < 3; i = i + 1) if (i == 1) k else if (i == 2) j,
                for (var i = 0; i < 3; i = i + 1) if (i == 1) i else if (i == 2) i else j,
              ];

              return list.join();
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), $String('012103223312'));
    });
  });
}
