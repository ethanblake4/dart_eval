import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('record runtime types resolve interleaved fields by layout', () {
    const source = '''
      class Base {}
      class A extends Base {}
      class B extends Base {}

      Type typeOf<T>() => T;

      bool main() {
        Base a = A();
        Base b = B();
        final first = (a, foo: b, b, bar: a);
        final reordered = (bar: a, a, b, foo: b);
        final different = (b, foo: b, a, bar: a);
        return first.runtimeType == typeOf<(A, B, {A bar, B foo})>() &&
            reordered.runtimeType == first.runtimeType &&
            different.runtimeType != first.runtimeType;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('record runtime types retain null and nested interleaved fields', () {
    const source = '''
      Type typeOf<T>() => T;

      bool main() {
        Object? value = null;
        Object nested = (1, name: 'one');
        final record = (value: value, nested, value);
        return record.runtimeType ==
            typeOf<((int, {String name}), Null, {Null value})>();
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
