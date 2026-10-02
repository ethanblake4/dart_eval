import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('dynamic spread checks collection shape before iteration', () {
    const source = '''
      bool rejects(void Function() build) {
        try {
          build();
        } on TypeError {
          return true;
        }
        return false;
      }

      int main() {
        dynamic number = 3;
        dynamic list = <int>[1, 2];
        dynamic map = <int, int>{1: 2};
        if (!rejects(() => <int>[...number])) return -1;
        if (!rejects(() => <int>{...number})) return -2;
        if (!rejects(() => <int, int>{...number})) return -3;
        if (!rejects(() => <int>[...map])) return -4;
        if (!rejects(() => <int, int>{...list})) return -5;
        dynamic absent = null;
        if (<int>[1, ...?absent, ...list].length != 3) return -6;
        if (<int, int>{...map}[1] != 2) return -7;
        return 0;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(0), reason: mode);
    }
  });
}
