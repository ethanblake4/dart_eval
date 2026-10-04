import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';
import 'package:test/test.dart';

void main() {
  group('Enum tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Enum boxing error', () {
      final compiler2 = Compiler();
      compiler2.defineBridgeEnum(
        BridgeEnumDef(
          BridgeTypeRef(
            BridgeTypeSpec('package:my_package/show.dart', 'ShowType'),
          ),
          values: ['Movie', 'Series'],
        ),
      );
      final program = compiler2.compile({
        'my_package': {
          'main.dart': r'''
            import 'show.dart';
            class Media {
              Media(this.type, this.url);
              final ShowType type;
              String? url;
            }
            void main() {
              final requiredType = 'movie';
              final type = (requiredType == 'movie') ? 
                ShowType.Movie : ShowType.Series;
              
              final media = Media(type, 'example.com');
              print(media.url);
            }
          ''',
        },
      });
      final runtime = Runtime.ofProgram(program);
      runtime.registerBridgeEnumValues(
        'package:my_package/show.dart',
        'ShowType',
        {'Movie': $int(0), 'Series': $int(1)},
      );
      runtime.executeLib('package:my_package/main.dart', 'main');
    });

    test('Enum value index property from imported file', () {
      const libSource = '''
        enum TestEnum {
          alpha,
          beta
        }
      ''';

      const mainSource = '''
        import 'package:my_test_package/lib.dart';

        int main() {
          return TestEnum.beta.index;
        }
      ''';

      final runtime = compiler.compileWriteAndLoad({
        'my_test_package': {'main.dart': mainSource, 'lib.dart': libSource},
      });

      final result = runtime.executeLib(
        'package:my_test_package/main.dart',
        'main',
      );
      expect(result, 1);
    });
  });
}
