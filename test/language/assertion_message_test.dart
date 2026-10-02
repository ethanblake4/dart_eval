import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('assertion messages retain null and guest identity lazily', () {
    const source = '''
      class Message {
        bool stringified = false;
        String toString() {
          stringified = true;
          return 'message';
        }
      }

      bool main() {
        final direct = AssertionError();
        if (direct.message != null || direct.toString() != 'Assertion failed') {
          return false;
        }
        try {
          assert(false, null);
          return false;
        } on AssertionError catch (error) {
          if (error.message != null ||
              !error.toString().contains('is not true')) return false;
        }
        final message = Message();
        try {
          assert(false, message);
          return false;
        } on AssertionError catch (error) {
          return !message.stringified && identical(error.message, message);
        }
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
