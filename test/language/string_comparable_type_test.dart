import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('String retains its Comparable<String> supertype', () {
    const source = '''
      class Accepts<T> {
        bool check(dynamic value) => value is T;
      }

      bool main() {
        dynamic text = 'hest';
        return text is Comparable<String> &&
            text is Comparable<dynamic> &&
            text is! Comparable<int> &&
            Accepts<Comparable<String>>().check(text) &&
            Accepts<Comparable<dynamic>>().check(text) &&
            !Accepts<Comparable<int>>().check(text);
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
