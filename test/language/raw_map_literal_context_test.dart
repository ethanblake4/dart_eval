import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test(
    'putIfAbsent contextualizes empty callback lists through Map values',
    () {
      const source = '''
      bool main() {
        final buckets = <String, List<int>>{};
        for (final value in <int>[1, 2, 3]) {
          buckets.putIfAbsent('all', () => []).add(value);
        }
        if (buckets['all'] is! List<int> ||
            buckets['all']!.join(',') != '1,2,3') return false;
        dynamic wrong = () => <String>[];
        try {
          buckets.putIfAbsent('wrong', wrong);
          return false;
        } on TypeError {
          return true;
        }
      }
    ''';
      for (final (mode, result) in runDynamicFixture(source)) {
        expect(result, const DynamicFixtureResult.value(true), reason: mode);
      }
    },
  );

  test('raw Map context supplies dynamic type arguments', () {
    const source = '''
      int main() {
        Map rawConst = const {'0': 0, '1': 1};
        Map rawMutable = {'0': 0, '1': 1};
        var inferredConst = const {'0': 0, '1': 1};
        Map<String, int> typedConst = const {'0': 0, '1': 1};
        if (rawConst is Map<String, int>) return -1;
        if (rawMutable is Map<String, int>) return -2;
        if (inferredConst is! Map<String, int>) return -3;
        if (typedConst is! Map<String, int>) return -4;
        return 0;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(0), reason: mode);
    }
  });
}
