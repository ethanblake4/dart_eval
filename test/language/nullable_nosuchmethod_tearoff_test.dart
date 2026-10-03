import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('Object noSuchMethod tear-offs invoke the supplied Invocation', () {
    for (final (mode, result) in runDynamicFixture('''
class Plain {}
class Handler {
  dynamic noSuchMethod(Invocation invocation) =>
      invocation.memberName == #missing ? 19 : -1;
}
int check(Object? receiver) {
  final tearOff = receiver.noSuchMethod;
  dynamic callable = tearOff;
  try { callable(); return -100; } on NoSuchMethodError {}
  try {
    tearOff(Invocation.method(#missing, [7]));
    return -100;
  } on NoSuchMethodError catch (error) {
    return error.toString().contains('missing') ? 1 : -100;
  }
}
int main() {
  Object? handler = Handler();
  final native = 0.noSuchMethod;
  final nullMethod = null.noSuchMethod;
  final handlerMethod = handler.noSuchMethod;
  if (native != 0.noSuchMethod || nullMethod != null.noSuchMethod) return -1;
  return check(0) + check(null) + check(Plain()) +
      (handlerMethod(Invocation.method(#missing, [])) as int);
}
''')) {
      expect(result, const DynamicFixtureResult.value(22), reason: mode);
    }
  });
}
