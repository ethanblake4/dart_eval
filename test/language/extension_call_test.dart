import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('implicit extension calls bind optional positional arguments', () {
    const source = r'''
      extension Invoke on Object {
        String call([String suffix = '!']) => '$this$suffix';
      }

      String main() {
        Object value = 'hello';
        return value() + value('?');
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(
        result,
        const DynamicFixtureResult.value('hello!hello?'),
        reason: mode,
      );
    }
  });

  test('imported generic extension calls retain their receiver bindings', () {
    for (final (mode, result) in runDynamicPackages({
      'dynamic_fixtures': {
        'main.dart': '''
          import 'invoke.dart';

          bool main() {
            final numbers = <int>[42];
            final words = <String>['hello'];
            return numbers() == 42 && words() == 'hello';
          }
        ''',
        'invoke.dart': '''
          extension Invoke<T> on List<T> {
            T call() => first;
          }
        ''',
      },
    }, entrypoint: dynamicFixtureLibrary)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
