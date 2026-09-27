import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void _expectTrue(String source) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, const DynamicFixtureResult.value(true), reason: mode);
  }
}

void main() {
  test('dependent defaults respect callback parameter variance', () {
    _expectTrue('''
      class Callback<X extends dynamic Function(Y), Y> {}
      bool main() {
        final callback = Callback();
        dynamic value = callback;
        return callback is Callback<dynamic Function(Never), dynamic> &&
          callback is! Callback<dynamic Function(Object?), dynamic> &&
          value is Callback<dynamic Function(Never), dynamic> &&
          value is! Callback<dynamic Function(Object?), dynamic>;
      }
    ''');
  });
  test(
    'raw generic construction retains defaults through dynamic and raw views',
    () {
      _expectTrue('''
      class Box<T> { Box(); factory Box.make() => Box<T>(); }
      dynamic create() => Box();
      bool main() {
        Box raw = Box();
        dynamic factory = Box.make();
        return raw is! Box<int> && raw is Box<dynamic> &&
          create() is Box<dynamic> && create() is! Box<String> &&
          factory is Box<dynamic> && factory is! Box<int>;
      }
    ''');
    },
  );
  test('implicit constructors instantiate omitted dependent bounds', () {
    _expectTrue('''
      class Pair<T extends num, U extends List<T>> {}
      bool main() {
        Pair raw = Pair();
        dynamic value = raw;
        return raw is Pair<num, List<num>> &&
          raw is! Pair<int, List<int>> &&
          value is Pair<num, List<num>> && value is! Pair<int, List<int>>;
      }
    ''');
  });
  test('raw bounded supertypes use their declared defaults in type checks', () {
    _expectTrue('''
      class Base<T extends num> {}
      class Child<U> extends Base {}
      bool main() {
        final child = Child<int>();
        dynamic value = child;
        Object object = child;
        return object is Child<int> && child is Base<num> && child is! Base<int> &&
          value is Base<num> && value is! Base<int>;
      }
    ''');
  });
}
