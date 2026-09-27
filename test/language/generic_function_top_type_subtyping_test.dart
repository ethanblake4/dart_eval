import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void _expectTrue(String source) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, const DynamicFixtureResult.value(true), reason: mode);
  }
}

void main() {
  test('generic optional and named parameters respect Object? as top', () {
    _expectTrue('''
      typedef OptionalObject = Object? Function<T>(Object?, [Object?]);
      typedef OptionalType = Object? Function<T>(T, [T?]);
      typedef NamedObject = Object? Function<T>(Object?, {Object? value});
      typedef NamedType = Object? Function<T>(T, {T? value});

      Object? optionalObject<T>(Object? x, [Object? y]) => x;
      Object? optionalType<T>(T x, [T? y]) => x;
      Object? namedObject<T>(Object? x, {Object? value}) => x;
      Object? namedType<T>(T x, {T? value}) => x;

      bool main() =>
          optionalObject is OptionalType &&
          optionalType is OptionalType &&
          optionalType is! OptionalObject &&
          namedObject is NamedType &&
          namedType is NamedType &&
          namedType is! NamedObject;
    ''');
  });

  test('generic returns distinguish Object? from Object and T', () {
    _expectTrue('''
      typedef ReturnsT = T Function<T>();
      typedef ReturnsNullableT = T? Function<T>();
      typedef ReturnsObject = Object Function<T>();
      typedef ReturnsNullableObject = Object? Function<T>();

      T returnsT<T>() => throw StateError('unused');
      T? returnsNullableT<T>() => null;
      Object? returnsNullableObject<T>() => null;

      bool main() =>
          returnsT is ReturnsNullableObject &&
          returnsNullableT is ReturnsNullableObject &&
          returnsT is! ReturnsObject &&
          returnsNullableT is! ReturnsObject &&
          returnsNullableObject is! ReturnsT;
    ''');
  });

  test('generic list return and nullable bounded type parameter', () {
    _expectTrue('''
      typedef ObjectList = List<Object?> Function<T>();
      typedef NullableObject = Object? Function<T extends num>();

      List<T> listOfT<T>() => <T>[];
      T? nullableNum<T extends num>() => null;

      bool main() =>
          listOfT is ObjectList && nullableNum is NullableObject;
    ''');
  });
}
