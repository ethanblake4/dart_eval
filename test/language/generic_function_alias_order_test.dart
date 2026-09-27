import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

const _declarations = '''
  typedef G<U> = num Function<T extends U>(T value);
  num f<T extends num>(T value) => value + 2;

  bool rejects(void Function() cast) {
    try {
      cast();
    } on TypeError {
      return true;
    }
    return false;
  }
''';

void _check(String body, {String declarations = ''}) {
  final source =
      '''
    $_declarations
    $declarations
    bool main() {
      dynamic d = f;
      $body
    }
  ''';
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, const DynamicFixtureResult.value(true), reason: mode);
  }
}

void main() {
  test('generic function alias casts distinguish bounds, narrow first', () {
    _check('''
      if (!rejects(() => f as G<int>)) return false;
      if (!rejects(() => d as G<int>)) return false;
      if ((f as G<num>)(40) != 42) return false;
      if ((d as G<num>)(40) != 42) return false;
      if (!rejects(() => f as G<double>)) return false;
      if (!rejects(() => d as G<double>)) return false;
      if (!rejects(() => f as G<String>)) return false;
      if (!rejects(() => d as G<String>)) return false;
      return true;
    ''');
  });

  test('generic function alias casts distinguish bounds, broad first', () {
    _check('''
      if (!rejects(() => f as G<String>)) return false;
      if (!rejects(() => d as G<String>)) return false;
      if (!rejects(() => f as G<double>)) return false;
      if (!rejects(() => d as G<double>)) return false;
      if ((f as G<num>)(40) != 42) return false;
      if ((d as G<num>)(40) != 42) return false;
      if (!rejects(() => f as G<int>)) return false;
      if (!rejects(() => d as G<int>)) return false;
      return true;
    ''');
  });

  test('generic function alias substitutes nested bounds', () {
    _check(
      '''
      if (!rejects(() => length as Nested<int>)) return false;
      if ((length as Nested<num>)(<num>[1, 2]) != 2) return false;
      return true;
    ''',
      declarations: '''
      typedef Nested<U> = num Function<T extends List<U>>(T values);
      num length<T extends List<num>>(T values) => values.length;
    ''',
    );
  });
}
