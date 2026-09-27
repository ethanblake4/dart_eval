import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('generic extension and method arguments retain distinct owners', () {
    const source = '''
      Type typeOf<X>() => X;

      extension Inspect<T> on List<T> {
        bool check<U>(U value) =>
            typeOf<T>() == int &&
            typeOf<U>() == String &&
            this is List<int> &&
            this is List<T> &&
            value is String &&
            value is U;
      }

      bool main() {
        final values = <int>[1, 2];
        return values.check<String>('direct');
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
