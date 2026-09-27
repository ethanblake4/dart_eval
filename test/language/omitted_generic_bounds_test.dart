import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void _expectTrue(String source) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, const DynamicFixtureResult.value(true), reason: mode);
  }
}

void main() {
  test('dynamic call rejects a self-recursive omitted bound', () {
    _expectTrue('''
      int calls = 0;
      void recursive<T extends Iterable<T>>() { calls++; }

      bool main() {
        dynamic callback = recursive;
        try {
          callback();
        } on TypeError {
          return calls == 0;
        }
        return false;
      }
    ''');
  });

  test('dynamic call rejects mutually recursive omitted bounds', () {
    _expectTrue('''
      int calls = 0;
      void recursive<T extends Iterable<U>, U extends T>() { calls++; }

      bool main() {
        dynamic callback = recursive;
        try {
          callback();
        } on TypeError {
          return calls == 0;
        }
        return false;
      }
    ''');
  });

  test('dynamic call instantiates acyclic dependent bounds', () {
    _expectTrue('''
      bool simple<T extends num, U extends T>() => T == num && U == num;
      bool nested<T extends List<U>, U extends int>() =>
          (T == List<int>) && U == int;

      bool main() {
        dynamic first = simple;
        dynamic second = nested;
        return first() && second();
      }
    ''');
  });

  test('nested generic closure resolves its outer type parameter', () {
    _expectTrue('''
      bool outer<T extends num>() {
        Type inner<U extends T>() => U;
        dynamic callback = inner;
        return callback() == T;
      }

      bool main() => outer<int>() && outer<double>();
    ''');
  });

  test('omitted bounds survive named and default argument invocation', () {
    _expectTrue('''
      bool check<T extends num>(T value, {int bias = 2}) =>
          T == num && value + bias == 5;

      bool main() {
        dynamic callback = check;
        return callback(3) && callback(1, bias: 4);
      }
    ''');
  });

  test('bound generic method tear-off instantiates omitted arguments', () {
    _expectTrue('''
      class Checker {
        bool check<T extends num, U extends T>(T value) =>
            T == num && U == num && value == 3;
      }

      bool main() {
        dynamic callback = Checker().check;
        return callback(3);
      }
    ''');
  });

  test('explicit self-bound argument accepts a concrete implementation', () {
    _expectTrue('''
      class Items extends Iterable<Items> {
        @override
        Iterator<Items> get iterator => <Items>[].iterator;
      }

      bool check<T extends Iterable<T>>() => T == Items;

      bool main() {
        dynamic callback = check;
        return callback<Items>();
      }
    ''');
  });
}
