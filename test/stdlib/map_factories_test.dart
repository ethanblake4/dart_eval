import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  final program = Compiler().compile({
    'map_factories': {
      'main.dart': '''
        class EqualKey {
          const EqualKey(this.id);
          final int id;
          @override
          bool operator ==(Object other) =>
              other is EqualKey && other.id == id;
          @override
          int get hashCode => id;
        }

        bool identity() {
          final first = EqualKey(1);
          final second = EqualKey(1);
          final values = Map<Object?, String>.identity();
          values[first] = 'first';
          values[second] = 'second';
          values[1000] = 'int';
          values['text'] = 'string';
          values[null] = 'null';
          dynamic typed = Map<String, int>.identity();
          var rejectsWrongValue = false;
          try {
            typed['typed'] = 'wrong';
          } on TypeError {
            rejectsWrongValue = true;
          }
          return values.length == 5 &&
              values[first] == 'first' &&
              values[second] == 'second' &&
              values[1000] == 'int' &&
              values['text'] == 'string' &&
              values[null] == 'null' &&
              typed is Map<String, int> &&
              rejectsWrongValue;
        }

        bool fromIterables() {
          final values = Map.fromIterables(
            ['repeat', 'repeat', 'last'],
            [1, 2, 3],
          );
          var rejectsUnequalLengths = false;
          try {
            Map.fromIterables([1], [1, 2]);
          } on ArgumentError {
            rejectsUnequalLengths = true;
          }
          dynamic typed = Map<String, int>.fromIterables(['typed'], [7]);
          var rejectsWrongValue = false;
          try {
            typed['other'] = 'wrong';
          } on TypeError {
            rejectsWrongValue = true;
          }
          return values.length == 2 &&
              values['repeat'] == 2 &&
              values['last'] == 3 &&
              rejectsUnequalLengths &&
              typed is Map<String, int> &&
              typed['typed'] == 7 &&
              rejectsWrongValue;
        }

        bool unmodifiable() {
          dynamic values = Map<String, int>.unmodifiable({'a': 1});
          bool rejects(void Function() mutation) {
            try {
              mutation();
            } on UnsupportedError {
              return true;
            }
            return false;
          }
          return values is Map<String, int> &&
              values['a'] == 1 &&
              rejects(() { values['b'] = 2; }) &&
              rejects(() { values.addAll({'b': 2}); }) &&
              rejects(() { values.addEntries([MapEntry('b', 2)]); }) &&
              rejects(() { values.clear(); }) &&
              rejects(() { values.putIfAbsent('b', () => 2); }) &&
              rejects(() { values.remove('a'); }) &&
              rejects(() { values.removeWhere((key, value) => true); }) &&
              rejects(() { values.update('a', (value) => value + 1); }) &&
              rejects(() { values.updateAll((key, value) => value + 1); });
        }
      ''',
    },
  });

  for (final (mode, runtime) in [
    ('fresh', Runtime.ofProgram(program)),
    ('encoded', Runtime(program.write().buffer)),
  ]) {
    test('$mode Map.identity preserves guest and scalar identity', () {
      expect(
        runtime.executeLib('package:map_factories/main.dart', 'identity'),
        true,
      );
    });

    test('$mode Map.fromIterables preserves native factory behavior', () {
      expect(
        runtime.executeLib('package:map_factories/main.dart', 'fromIterables'),
        true,
      );
    });

    test('$mode Map.unmodifiable rejects all mutation paths', () {
      expect(
        runtime.executeLib('package:map_factories/main.dart', 'unmodifiable'),
        true,
      );
    });
  }
}
