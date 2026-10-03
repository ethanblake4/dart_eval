import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('noSuchMethod argument collections are immutable', () {
    for (final (mode, result) in runDynamicFixture('''
class Handler {
  Invocation noSuchMethod(Invocation invocation) => invocation;
}
bool cannotClear(dynamic collection) {
  try {
    collection.clear();
    return false;
  } on UnsupportedError {
    return true;
  }
}
int main() {
  dynamic handler = Handler();
  Invocation getter = handler.missing;
  Invocation empty = handler.missing();
  Invocation named = handler.missing(7, named: 11);
  return (cannotClear(getter.positionalArguments) ? 1 : 0) +
      (cannotClear(getter.namedArguments) ? 2 : 0) +
      (cannotClear(empty.positionalArguments) ? 4 : 0) +
      (cannotClear(empty.namedArguments) ? 8 : 0) +
      (cannotClear(named.positionalArguments) ? 16 : 0) +
      (cannotClear(named.namedArguments) ? 32 : 0) +
      (named.namedArguments[Symbol('named')] == 11 ? 64 : 0);
}
''')) {
      expect(result, const DynamicFixtureResult.value(127), reason: mode);
    }
  });
}
