import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('alternating successful and failed subtype checks', () {
    const source = '''
      bool isInteger(dynamic value) => value is int;

      bool main() {
        for (var i = 0; i < 128; i++) {
          if (!isInteger(i) || isInteger(i.toString())) return false;
        }
        return true;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('class type parameter checks retain their owner', () {
    const source = '''
      class Box<T> {
        bool accepts(dynamic value) => value is T;
      }

      bool main() {
        final integers = Box<int>();
        final strings = Box<String>();
        for (var i = 0; i < 128; i++) {
          if (!integers.accepts(i) || integers.accepts('value')) {
            return false;
          }
          if (!strings.accepts('value') || strings.accepts(i)) {
            return false;
          }
        }
        return true;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
