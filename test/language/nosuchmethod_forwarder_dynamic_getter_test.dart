import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('dynamic noSuchMethod forwarder tear-offs remain callable', () {
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
        return tearOff('hello') == 5;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('forwarder tear-offs preserve named invocation arguments', () {
    const source = '''
      abstract class Interface {
        int transform(int value, {int scale = 2, int bias = 0});
      }
      class Handler {
        dynamic noSuchMethod(Invocation invocation) {
          if (invocation.memberName != #transform || !invocation.isMethod ||
              invocation.positionalArguments.length != 1 ||
              invocation.namedArguments.length != 2) {
            return -1000;
          }
          return invocation.positionalArguments[0] *
              invocation.namedArguments[#scale] +
              invocation.namedArguments[#bias];
        }
      }
      class Proxy extends Handler implements Interface {}
      int main() {
        dynamic receiver = Proxy();
        final tearOff = receiver.transform;
        return tearOff(3, bias: 5, scale: 7) +
            Function.apply(tearOff, [4], {#scale: 11, #bias: 13}) +
            tearOff.call(5, bias: 19, scale: 17);
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(187), reason: mode);
    }
  });
}
