import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('nested loops retain changing phi inputs and mutable field reads', () {
    const source = '''
class Counter { int value = 1; }
int main() {
  final counter = Counter();
  var total = 0;
  for (var row = 0; row < 3; row++) {
    for (var column = 0; column < 4; column++) {
      total += row * 7 + column * 3 + counter.value;
      counter.value++;
    }
  }
  return total;
}
''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(216), reason: mode);
    }
  });

  test('a skipped loop does not evaluate throwing invariant arithmetic', () {
    const source = '''
int divide(int count, int divisor) {
  var total = 0;
  for (var i = 0; i < count; i++) total += 42 ~/ divisor;
  return total;
}
int main() {
  final skipped = divide(0, 0);
  try { divide(1, 0); } catch (_) { return skipped; }
  return -1;
}
''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(0), reason: mode);
    }
  });
}
