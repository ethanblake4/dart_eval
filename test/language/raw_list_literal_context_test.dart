import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('raw collection context supplies dynamic to list literals', () {
    const source = '''
      bool main() {
        List rawList = [1, 2];
        Iterable rawIterable = [1, 2];
        var inferred = [1, 2];
        List<int> typed = [1, 2];
        return rawList.runtimeType == <dynamic>[].runtimeType &&
            rawIterable.runtimeType == <dynamic>[].runtimeType &&
            rawList is! List<int> &&
            rawIterable is! List<int> &&
            inferred is List<int> &&
            typed is List<int>;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
