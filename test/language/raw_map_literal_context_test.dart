import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
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
