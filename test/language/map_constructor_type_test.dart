import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('Map factories retain class type parameters', () {
    const source = '''
      class Holder<T> {
        final Map<T, T> initialized = Map<T, T>();

        Map<T, T> fresh() => Map<T, T>();
        Map<T, T> copied(Map<T, T> values) => Map<T, T>.from(values);
        Map<T, T> cloned(Map<T, T> values) => Map<T, T>.of(values);
        Map<T, T> entries(T key, T value) =>
            Map<T, T>.fromEntries([MapEntry<T, T>(key, value)]);
      }

      class Derived<T> extends Holder<T> {}

      bool main() {
        final holder = Derived<int>();
        dynamic initialized = holder.initialized;
        dynamic fresh = holder.fresh();
        dynamic copied = holder.copied(<int, int>{1: 2});
        dynamic cloned = holder.cloned(<int, int>{1: 2});
        dynamic entries = holder.entries(1, 2);
        return initialized is Map<int, int> &&
            fresh is Map<int, int> &&
            copied is Map<int, int> &&
            cloned is Map<int, int> &&
            entries is Map<int, int> &&
            initialized is! Map<String, String>;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
