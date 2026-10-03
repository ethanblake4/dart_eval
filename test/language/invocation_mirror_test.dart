import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('Object toString rejects arguments on dynamic calls and tear-offs', () {
    for (final (mode, result) in runDynamicFixture('''
int main() {
  dynamic object = Object();
  dynamic stringify = object.toString;
  int result = object.toString() is String && stringify() is String ? 1 : 0;
  try { object.toString(42); } on NoSuchMethodError { result += 2; }
  try { object.toString(x: 37); } on NoSuchMethodError { result += 4; }
  try { stringify(42); } on NoSuchMethodError { result += 8; }
  try { stringify(x: 37); } on NoSuchMethodError { result += 16; }
  return result;
}
''')) {
      expect(result, const DynamicFixtureResult.value(31), reason: mode);
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
