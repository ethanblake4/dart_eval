import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _library = 'package:map_set/main.dart';

Program _compile(String source) => Compiler().compile({
  'map_set': {'main.dart': source},
});

Iterable<(String, Runtime)> _runtimes(Program program) sync* {
  yield ('fresh', Runtime.ofProgram(program));
  yield ('serialized', Runtime(program.write().buffer));
}

Set<String> _opNames(Program program) {
  final result = <String>{};
  final typed = program.typedProgram;
  for (var pc = 0; pc < typed.code.length;) {
    final op = TypedOp.instructions[typed.code[pc]];
    result.add(op.name);
    pc += op.length;
  }
  return result;
}

void main() {
  test('map literals use direct index and store operations', () {
    final program = _compile('''
      num main() {
        final values = <String, int>{'a': 1, 'b': 2};
        values['a'] = 4;
        final hadSecond = values.containsKey('b');
        final int removed = values.remove('b');
        int result = values['a'];
        result += removed;
        result += values.length;
        if (hadSecond) result += 10;
        return result;
      }
    ''');
    expect(
      _opNames(program),
      containsAll(['cNewMap', 'mapSetCSR', 'rMapIndexCS', 'rBoxMap']),
    );
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 17, reason: kind);
    }
  });

  test('set literals and mutations keep canonical values', () {
    final program = _compile('''
      int main() {
        final values = <int>{1, 2};
        final inserted = values.add(3);
        final duplicate = values.add(3);
        final contained = values.contains(2);
        final removed = values.remove(2);
        return values.length +
            (inserted ? 10 : 0) +
            (duplicate ? 100 : 0) +
            (contained ? 1000 : 0) +
            (removed ? 10000 : 0);
      }
    ''');
    expect(_opNames(program), containsAll(['cNewSet', 'setAddCR', 'rBoxSet']));
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 11012, reason: kind);
    }
  });

  test('map and set spreads preserve insertion iteration', () {
    final program = _compile('''
      int main() {
        final baseMap = <String, int>{'a': 1, 'b': 2};
        final map = <String, int>{'z': 9, ...baseMap, 'c': 3};
        final baseSet = <int>{2, 1};
        final set = <int>{0, ...baseSet, 3};
        var result = 0;
        for (final entry in map.entries) {
          result = result * 10 + entry.value;
        }
        for (final value in set) {
          result = result * 10 + value;
        }
        return result;
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 91230213, reason: kind);
    }
  });

  test('guest equality and hashCode drive map and set lookup', () {
    final program = _compile('''
      class Key {
        final int id;
        Key(this.id);
        bool operator ==(Object other) => other is Key && other.id == id;
        int get hashCode => id;
      }

      int main() {
        final first = Key(7);
        final equivalent = Key(7);
        final map = <Key, int>{first: 11};
        final set = <Key>{first, equivalent};
        return map[equivalent] + set.length;
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 12, reason: kind);
    }
  });

  test('host map and set adapters preserve identity and native values', () {
    final program = _compile('''
      Map<String, int> mutateMap(Map<String, int> values) {
        values['added'] = values['base'] + 2;
        return values;
      }

      Set<int> mutateSet(Set<int> values) {
        values.add(5);
        values.remove(1);
        return values;
      }

      int readMap(Map<String, int> values) => values['host'];
      bool readSet(Set<int> values) => values.contains(8);
      Map<String, int> makeMap() => <String, int>{'guest': 7};
      Set<int> makeSet() => <int>{2, 3};
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      final map = <String, int>{'base': 3};
      final mapResult = runtime.executeLib(
        _library,
        'mutateMap',
        arguments: {'values': map},
      );
      expect(identical(mapResult, map), isTrue, reason: kind);
      expect(map, {'base': 3, 'added': 5}, reason: kind);

      final set = <int>{1, 2};
      final setResult = runtime.executeLib(
        _library,
        'mutateSet',
        arguments: {'values': set},
      );
      expect(identical(setResult, set), isTrue, reason: kind);
      expect(set, {2, 5}, reason: kind);

      final guestMap = runtime.executeLib(_library, 'makeMap') as Map;
      guestMap['host'] = 13;
      expect(
        runtime.executeLib(
          _library,
          'readMap',
          arguments: {'values': guestMap},
        ),
        13,
        reason: kind,
      );
      final guestSet = runtime.executeLib(_library, 'makeSet') as Set;
      guestSet.add(8);
      expect(
        runtime.executeLib(
          _library,
          'readSet',
          arguments: {'values': guestSet},
        ),
        isTrue,
        reason: kind,
      );
    }
  });

  test('boxed set reports the Set runtime type', () {
    final program = _compile('''
      bool main() {
        Object value = <int>{1};
        return value is Set<int> && value is! Map<int, int>;
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), isTrue, reason: kind);
    }
  });
}
