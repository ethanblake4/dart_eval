import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('Object toString tear-offs reject arguments', () {
    for (final (mode, result) in runDynamicFixture('''
int main() {
  dynamic object = Object();
  dynamic stringify = object.toString;
  int result = stringify() is String ? 1 : 0;
  try { stringify(42); } on NoSuchMethodError { result += 2; }
  try { stringify(x: 37); } on NoSuchMethodError { result += 4; }
  return result;
}
''')) {
      expect(result, const DynamicFixtureResult.value(7), reason: mode);
    }
  });

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
  Invocation named = handler.missing(7, named: 11);
  return (cannotClear(named.positionalArguments) ? 1 : 0) +
      (cannotClear(named.namedArguments) ? 2 : 0) +
      (named.namedArguments[Symbol('named')] == 11 ? 4 : 0);
}
''')) {
      expect(result, const DynamicFixtureResult.value(7), reason: mode);
    }
  });
}
