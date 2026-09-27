import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('mutually F-bounded class parameters have finite descriptors', () {
    const source = '''
      class First<A extends First<A, B>, B extends Second<A, B>> {
        bool accepts(dynamic first, dynamic second) =>
            first is First<A, B> && second is Second<A, B>;
      }

      class Second<A extends First<A, B>, B extends Second<A, B>> {}
      class A extends First<A, B> {}
      class B extends Second<A, B> {}

      bool main() => First<A, B>().accepts(A(), B());
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
