import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('dynamic reads tear off abstract noSuchMethod forwarders', () {
    const source = '''
      abstract class Interface {
        int method(String value);
      }
      class Proxy implements Interface {
        dynamic noSuchMethod(Invocation invocation) => 5;
      }
      bool main() {
        Interface value = Proxy();
        dynamic receiver = value;
        final tearOff = receiver.method;
        return tearOff is Function && tearOff('hello') == 5;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
