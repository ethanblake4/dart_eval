import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('typedef constructors still infer unresolved alias arguments', () {
    const source = '''
      class Base<T> {
        Base(T value);
        Type get payloadType => T;
      }
      typedef Alias<T> = Base<List<T>>;

      bool main() {
        final value = Alias(<num>[1]);
        return value.payloadType == (List<num>);
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('explicit forwarding constructor arguments cannot be reinferred', () {
    const source = '''
      class Base<T> { Base(T value); }
      mixin Marker {}
      class Alias<T> = Base<T> with Marker;

      bool rejectsNew(dynamic value) {
        try { new Alias<String>(value); return false; }
        on TypeError { return true; }
      }
      bool rejectsBare(dynamic value) {
        try { Alias<String>(value); return false; }
        on TypeError { return true; }
      }
      bool main() => rejectsNew(42) && rejectsBare(42) &&
          !rejectsNew('valid') && !rejectsBare('valid');
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('forwarding constructors preserve transformed superclass arguments', () {
    const source = '''
      class Base<T> {
        final T value;
        Base(this.value);
        Type get payloadType => T;
      }
      mixin Marker {}
      class Alias<T> = Base<List<T>> with Marker;

      bool main() {
        final value = new Alias<String>(<String>['hello']);
        return value.payloadType == (List<String>) && value.value.first == 'hello';
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('raw mixin chains retain nested generic supertypes at runtime', () {
    const source = '''
      class Base<T> {}
      mixin Payload<T> { Type get payloadType => T; }
      class Inner<U, V> = Object with Payload<Map<U, V>>;
      class Middle<T> = Object with Inner<T, Set<T>>;
      class Outer<T> = Base<List<T>> with Middle;

      bool check(dynamic value) =>
          value is Payload<Map<dynamic, Set<dynamic>>> &&
          value is Base<List<int>> &&
          value.payloadType == Map<dynamic, Set<dynamic>>;
      bool main() => check(new Outer<int>());
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
