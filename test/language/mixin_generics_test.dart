import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('folded mixin bodies retain applied lexical member types and storage', () {
    const source = '''
      typedef Exactly<T> = T Function(T);
      extension StaticType<T> on T {
        void check<R extends Exactly<T>>() {}
      }
      class Base<T> {
        final T value;
        Base(this.value);
        T read() => value;
      }
      mixin Payload<T> on Base<T> {
        int calls = 0;
        T own() => value;
        T inspect() {
          calls++;
          own().check<Exactly<T>>();
          read().check<Exactly<T>>();
          return super.read();
        }
      }
      class Applied extends Base<num> with Payload<num> {
        Applied() : super(3.5);
        int own() => 9;
        int read() => 7;
      }
      bool main() {
        final value = Applied();
        return value.inspect() == 3.5 && value.calls == 1 && value.own() == 9;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('folded mixins resolve members of every on constraint', () {
    const source = '''
      typedef Exactly<T> = T Function(T);
      extension StaticType<T> on T {
        void check<R extends Exactly<T>>() {}
      }
      class Left { num get left => 1; }
      class Right { num get right => 2; }
      class Both extends Left implements Right { num get right => 3; }
      mixin Joined on Left, Right {
        num total() {
          left.check<Exactly<num>>();
          this.right.check<Exactly<num>>();
          right.check<Exactly<num>>();
          return left + right;
        }
      }
      class Applied extends Both with Joined {
        int get left => 4;
        int get right => 5;
      }
      class Narrow extends Left { int get left => 6; }
      mixin Specific on Narrow, Left {
        bool checkSpecific() {
          left.check<Exactly<int>>();
          return left == 6;
        }
      }
      class SpecificApplied extends Narrow with Specific {}
      bool main() => Applied().total() == 9 && SpecificApplied().checkSpecific();
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

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
