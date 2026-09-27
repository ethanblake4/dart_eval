import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void _expectTrue(String source) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, const DynamicFixtureResult.value(true), reason: mode);
  }
}

void main() {
  test('map assignment infers empty set keys and nested values', () {
    const source = '''
      class A {}
      typedef T = A;
      bool main() {
        final values = <Set<T>, Set<T>>{};
        values[{}] = {T()};
        return values.keys.single is Set<A> &&
            values.values.single.single is A;
      }
    ''';
    _expectTrue(source);
  });

  test('custom inherited operators provide index and value contexts', () {
    const source = '''
      class Store<T> {
        bool valid = false;
        void operator []=(Set<T> index, List<T> value) {
          valid = index is Set<int> && value is List<int>;
        }
        bool operator [](Set<T> index) => index is Set<int>;
      }
      class IntStore extends Store<int> {}
      bool main() {
        final store = IntStore();
        store[{}] = [];
        return store.valid && store[{}];
      }
    ''';
    _expectTrue(source);
  });

  test(
    'generic extension index operators infer keys for writes and cascades',
    () {
      _expectTrue('''
      class Bucket<T> {
        int value = 0;
        bool valid = true;
      }

      extension BucketIndex<T> on Bucket<T> {
        int operator [](Set<T> key) {
          valid = valid && key is Set<int>;
          return value;
        }
        void operator []=(Set<T> key, int next) {
          valid = valid && key is Set<int>;
          value = next;
        }
      }

      bool main() {
        final bucket = Bucket<int>();
        bucket..[{}] = 3;
        bucket[{}] += 2;
        final before = bucket[{}]++;
        final after = ++bucket[{}];
        return bucket.valid && before == 5 && after == 7 &&
            bucket[{}] == 7;
      }
    ''');
    },
  );

  test('null-aware index writes skip the key and right-hand side', () {
    _expectTrue('''
      class Bucket {
        int operator [](Set<int> key) => 1;
        void operator []=(Set<int> key, int value) {}
      }

      int keyCalls = 0;
      int valueCalls = 0;
      Set<int> key() { keyCalls++; return {}; }
      int value() { valueCalls++; return 2; }

      bool main() {
        Bucket? absent;
        absent?[key()] = value();
        absent?[key()] += value();
        absent?[key()]++;
        ++absent?[key()];
        return keyCalls == 0 && valueCalls == 0;
      }
    ''');
  });

  test('null-coalescing index write uses getter key context', () {
    _expectTrue('''
      class Bucket<T> {
        int? value;
        bool valid = true;
        int? operator [](Set<T> key) {
          valid = valid && key is Set<int>;
          return value;
        }
        void operator []=(Set<T> key, int next) {
          valid = valid && key is Set<int>;
          value = next;
        }
      }

      bool main() {
        final bucket = Bucket<int>();
        final first = bucket[{}] ??= 4;
        final second = bucket[{}] ??= 9;
        return bucket.valid && first == 4 && second == 4 &&
            bucket.value == 4;
      }
    ''');
  });

  test('compound writes infer keys from a narrower getter parameter', () {
    _expectTrue('''
      class Mixed {
        int value = 1;
        bool getterSawInt = false;
        bool setterSawNumOnly = false;
        bool setterSawInt = false;

        int operator [](Set<int> key) {
          getterSawInt = key is Set<int>;
          return value;
        }

        void operator []=(Set<num> key, int next) {
          if (value == 1) {
            setterSawNumOnly = key is Set<num> && key is! Set<int>;
          } else {
            setterSawInt = key is Set<int>;
          }
          value = next;
        }
      }

      bool main() {
        final mixed = Mixed();
        mixed[{}] = 3;
        mixed[{}] += 2;
        return mixed.setterSawNumOnly && mixed.getterSawInt &&
            mixed.setterSawInt && mixed.value == 5;
      }
    ''');
  });
}
