import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void _expectDisplay(String source, String expected) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, DynamicFixtureResult.value(expected), reason: mode);
  }
}

void main() {
  test('dependent bounds keep the declared return type', () {
    _expectDisplay('''
      num f<T extends num, U extends T>(T first, U second) => first;
      String main() => f.runtimeType.toString();
    ''', '<T0 extends num, T1 extends T0>(T0, T1) => num');
  });

  test('unbounded generic parameters remain symbolic', () {
    _expectDisplay('''
      num f<T, U>(T first, U second) => 1;
      String main() => f.runtimeType.toString();
    ''', '<T0, T1>(T0, T1) => num');
  });

  test('recursive bounds display their own parameter', () {
    _expectDisplay('''
      T f<T extends Comparable<T>>(T value) => value;
      String main() => f.runtimeType.toString();
    ''', '<T0 extends Comparable<T0>>(T0) => T0');
  });

  test('nested generic binders keep shadowed parameters distinct', () {
    _expectDisplay('''
      Object Function<T extends num>(T) outer<T extends String>(T text) =>
          <T extends num>(T value) => value;
      String main() => outer.runtimeType.toString();
    ''', '<T0 extends String>(T0) => <T1 extends num>(T1) => Object');
  });
}
