import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('function Type objects use Dart function notation', () {
    const source = '''
      typedef Required = int Function(bool);
      typedef Optional = int Function(bool, [String?]);
      typedef Named = int Function({required int value, String? label});
      typedef Nullable = int Function()?;
      String main() =>
          '\${Required}|\${Optional}|\${Named}|\${Nullable}|'
          '\${((int x) => x).runtimeType}';
    ''';
    const expected = DynamicFixtureResult.value(
      '(bool) => int|(bool, [String?]) => int|'
      '({String? label, required int value}) => int|'
      '(() => int)?|(int) => int',
    );
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, expected, reason: mode);
    }
  });
}
