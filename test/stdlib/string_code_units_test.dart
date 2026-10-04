import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test(
    'String.codeUnits keeps List<int> typing and SDK read-only behavior',
    () {
      for (final (mode, result) in runDynamicFixture(r'''
      String main() {
        dynamic source = 'A😀';
        final dynamic units = source.codeUnits;
        if (units is! List<int>) return 'wrong type';
        if (units.join(',') != '65,55357,56832') return 'wrong values';
        try {
          units[0] = 0;
          return 'mutable';
        } on UnsupportedError {
          return '65,55357,56832';
        }
      }
    ''')) {
        expect(
          result,
          const DynamicFixtureResult.value('65,55357,56832'),
          reason: mode,
        );
      }
    },
  );
}
