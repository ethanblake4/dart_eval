import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void check(String source, Object expected) {
  final program = Compiler().compile({
    'collection_base': {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(
      runtime.executeLib('package:collection_base/main.dart', 'main'),
      expected,
    );
  }
}

void main() {
  test('MapBase inherits defaults from only its five guest primitives', () {
    check(r'''
      import 'dart:collection';

      class NoLengthMap extends MapBase<String, int> {
        final Map<String, int> data = {'a': 2, 'b': 4};
        Iterable<String> get keys => data.keys;
        int? operator [](Object? key) => data[key];
        void operator []=(String key, int value) { data[key] = value; }
        int? remove(Object? key) => data.remove(key);
        void clear() { data.clear(); }
      }

      int main() {
        final map = NoLengthMap();
        if (map.length != 2 || !map.containsKey('a') || map.containsKey('c')) return -1;
        if (map[1] != null || !map.containsValue(4)) return -2;
        if (map.keys.first != 'a' || map.values.first != 2) return -3;
        if (map.entries.first.key != 'a' || map.entries.first.value != 2) return -4;
        map.putIfAbsent('c', () => 6);
        map.update('a', (value) => value + 1);
        int total = 0;
        map.forEach((String key, int value) { total += value; });
        if (total != 13 || map.length != 3) return -5;
        map.removeWhere((key, value) => value == 4);
        if (map.containsKey('b')) return -6;
        map.clear();
        return map.isEmpty && !map.isNotEmpty ? total : -7;
      }
    ''', 13);
  });

  test('ListBase SDK defaults call guest accessors and setters', () {
    check(r'''
      import 'dart:collection';

      class Values extends ListBase<int> {
        final List<int> data = [2, 4, 6];
        int get length => data.length;
        set length(int value) { data.length = value; }
        int operator [](int index) => data[index];
        void operator []=(int index, int value) { data[index] = value; }
        void add(int value) { data.add(value); }
      }

      int main() {
        final values = Values();
        if (values.first != 2 || values.last != 6 || !values.contains(4)) return -1;
        values.first = 3;
        values.last = 7;
        values.addAll([9]);
        if (values.length != 4 || values[0] != 3 || values[3] != 9) return -2;
        if (values.reversed.first != 9 || values.getRange(1, 3).last != 7) return -3;
        if (values.map((value) => value + 1).first != 4) return -4;
        if (values.followedBy([11]).last != 11) return -5;
        final copied = values.toList();
        if (copied is! List<int> || copied[2] != 7) return -6;
        values.length = 2;
        return values.fold<int>(0, (total, value) => total + value);
      }
    ''', 7);
  });

  test('SDK MapMixin and ListMixin aliases forward superclass bindings', () {
    check(r'''
      import 'dart:collection';
      class Values extends ListMixin<int> {
        int get length => 1;
        set length(int value) {}
        int operator [](int index) => 8;
        void operator []=(int index, int value) {}
      }
      class Entries extends MapMixin<String, int> {
        Iterable<String> get keys => ['x'];
        int? operator [](Object? key) => key == 'x' ? 5 : null;
        void operator []=(String key, int value) {}
        int? remove(Object? key) => null;
        void clear() {}
      }
      int main() => Values().first + Entries().values.first;
    ''', 13);
  });

  test('MapBase preserves collection and guest object key identities', () {
    check(r'''
      import 'dart:collection';
      class Key {}
      class Entries extends MapBase<Object, int> {
        final Map<Object, int> data = {};
        Iterable<Object> get keys => data.keys;
        int? operator [](Object? key) => data[key];
        void operator []=(Object key, int value) { data[key] = value; }
        int? remove(Object? key) => data.remove(key);
        void clear() { data.clear(); }
      }
      int main() {
        final listKey = [1];
        final objectKey = Key();
        final map = Entries();
        map[listKey] = 3;
        map[objectKey] = 5;
        if (!map.containsKey(listKey) || !map.containsKey(objectKey)) return -1;
        if (map.values.first != 3 || map.values.last != 5) return -2;
        if (!identical(map.entries.first.key, listKey) ||
            !identical(map.entries.last.key, objectKey)) return -5;
        bool sawList = false;
        bool sawObject = false;
        map.forEach((Object key, int value) {
          if (identical(key, listKey)) sawList = true;
          if (identical(key, objectKey)) sawObject = true;
        });
        if (!sawList || !sawObject) return -3;
        map.update(listKey, (int value) => value + 1);
        if (map[listKey] != 4 || map.length != 2) return -4;
        return 9;
      }
    ''', 9);
  });
}
