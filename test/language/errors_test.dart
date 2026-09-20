import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('Errors tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('test TypeError', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              try {
                throw TypeError();
                return 'no exception';
              } on TypeError {
                return 'caught TypeError';
              }
            }
          ''',
        },
      });

      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result is $String ? result.$reified : result, 'caught TypeError');
    });

    test('test NoSuchMethodError', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              final dynamic a = 'String';

              try {
                a.clear();
                return 'no exception';
              } on NoSuchMethodError {
                return 'caught NoSuchMethodError';
              } catch (e) {
                return 'caught \$e instead of NoSuchMethodError';
              }
            }
          ''',
        },
      });

      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(
        result is $String ? result.$reified : result,
        'caught NoSuchMethodError',
      );
    });
  });
}
