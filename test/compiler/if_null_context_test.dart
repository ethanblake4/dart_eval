import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('dynamic if-null context infers the right operand from the left', () {
    const source = '''
      typedef Exactly<T> = T Function(T);
      extension StaticType<T> on T {
        T expectStaticType<R extends Exactly<T>>() => this;
      }
      bool main() {
        dynamic value = (null as List<int>?) ??
            ([]..expectStaticType<Exactly<List<int>>>());
        List<num> informative = (null as List<int>?) ??
            ([]..expectStaticType<Exactly<List<num>>>());
        return value is List<int> && informative is List<num>;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
