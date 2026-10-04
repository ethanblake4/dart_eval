import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void check(String body, {String classes = ''}) {
  final program = Compiler().compile({
    'probe': {
      'main.dart':
          '''
    import 'dart:collection';
    class Key {
      final int value;
      Key(this.value);
      bool operator ==(Object other) => other is Key && value == other.value;
      int get hashCode => value;
    }
    class Plain {}
    $classes
    bool main() { $body }
  ''',
    },
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib('package:probe/main.dart', 'main'), true);
  }
}

void main() {
  test(
    'guest superclass and native bridge subclasses retain key overrides',
    () {
      check(
        '''
      final values = HashMap<Object, int>();
      values[InheritedKey(3)] = 7;
      values[BridgeKey(4)] = 8;
      return values[InheritedKey(3)] == 7 && values[BridgeKey(4)] == 8;
    ''',
        classes: '''
      class InheritedKey extends Key {
        InheritedKey(int value) : super(value);
      }
      class BridgeKey extends ListBase<int> {
        final int value;
        BridgeKey(this.value);
        int get length => 0;
        set length(int value) {}
        int operator [](int index) => value;
        void operator []=(int index, int value) {}
        bool operator ==(Object other) => other is BridgeKey && other.value == value;
        int get hashCode => value;
      }
    ''',
      );
    },
  );
  for (final map in ['HashMap', 'LinkedHashMap']) {
    test(
      '$map dispatches guest key equality and rejects wrong keys',
      () => check('''
      final map = $map<Key, int>();
      map[Key(3)] = 8;
      dynamic dynamicMap = map;
      if (dynamicMap.containsKey('wrong') || dynamicMap.containsKey(null)) return false;
      return map[Key(3)] == 8 && !map.containsKey(Key(4));
    '''),
    );
    test(
      '$map identity and default Object keys stay distinct',
      () => check('''
      final first = Key(3);
      final second = Key(3);
      final identity = $map<Key, int>.identity();
      identity[first] = 1;
      identity[second] = 2;
      final plain = Plain();
      final defaults = $map<Plain, int>();
      defaults[plain] = 4;
      return identity.length == 2 && identity[first] == 1 &&
        defaults[plain] == 4 && !defaults.containsKey(Plain());
    '''),
    );
    test(
      '$map native scalars and explicit callbacks retain semantics',
      () => check('''
      final native = $map<dynamic, int>();
      native[1] = 3;
      native['key'] = 4;
      native[null] = 5;
      final object = Object();
      native[object] = 6;
      final dates = $map<DateTime, int>();
      dates[DateTime.utc(2020)] = 7;
      final nested = $map<Key, int>();
      nested[Key(8)] = 1;
      final custom = $map<Key, int>(
        equals: (Key a, Key b) => nested.containsKey(Key(8)) && a.value % 2 == b.value % 2,
        hashCode: (Key key) => key.value % 2);
      custom[Key(1)] = 8;
      return native[1.0] == 3 && native['key'] == 4 && native[null] == 5 &&
        native[object] == 6 && !native.containsKey(Object()) &&
        dates[DateTime.utc(2020)] == 7 && !dates.containsKey(Object()) &&
        custom[Key(3)] == 8;
    '''),
    );
  }
  for (final set in ['HashSet', 'LinkedHashSet']) {
    test(
      '$set uses guest overrides and identity factory',
      () => check('''
      final values = $set<Key>();
      values.add(Key(3));
      values.add(Key(3));
      final first = Key(4);
      final identity = $set<Key>.identity();
      identity.add(first);
      identity.add(Key(4));
      dynamic dynamicValues = values;
      final object = Object();
      final native = $set<Object>()..add(object)..add(DateTime.utc(2020));
      return values.length == 1 && values.contains(Key(3)) &&
        !values.contains(Key(4)) && !dynamicValues.contains('wrong') &&
        native.contains(object) && !native.contains(Object()) &&
        native.contains(DateTime.utc(2020)) &&
        identity.length == 2 && identity.contains(first);
    '''),
    );
  }
  test(
    'explicit callback types remain checked',
    () => check('''
    final values = HashMap<String, int>(hashCode: (int key) => key);
    try {
      values['wrong'] = 1;
    } on TypeError { return true; }
    return false;
  '''),
  );
}
