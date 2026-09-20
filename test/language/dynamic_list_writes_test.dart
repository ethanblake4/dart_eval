import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void _expectValue(String source, Object? expected) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, DynamicFixtureResult.value(expected), reason: mode);
  }
}

void main() {
  group('reified dynamic list writes', () {
    test('rejects bad add and indexed writes before mutation', () {
      _expectValue('''
        int main() {
          dynamic values = <int>[1, 2];
          var result = 0;
          try {
            values.add('bad');
          } on TypeError {
            if (values.length == 2) result += 1;
          }
          try {
            values[0] = 'bad';
          } on TypeError {
            if (values[0] == 1) result += 2;
          }
          return result;
        }
      ''', 3);
    });

    test('accepts subtype writes without replacing the list', () {
      _expectValue('''
        bool main() {
          dynamic values = <num>[1];
          dynamic alias = values;
          values.add(2);
          values[0] = 1.5;
          return identical(values, alias) &&
              values.length == 2 &&
              values[0] == 1.5 &&
              values[1] == 2;
        }
      ''', true);
    });

    test('validates bulk writes before changing the list', () {
      _expectValue('''
        int main() {
          dynamic values = <int>[1];
          try {
            values.addAll(<dynamic>[2, 'bad']);
          } on TypeError {
            return values.length * 10 + values[0];
          }
          return -1;
        }
      ''', 11);
    });

    test('exported host views preserve the guest element constraint', () {
      final program = Compiler().compile({
        'dynamic_fixtures': {'main.dart': 'List<int> main() => <int>[1];'},
      });
      for (final (mode, runtime) in [
        ('fresh', Runtime.ofProgram(program)),
        ('serialized', Runtime(program.write().buffer)),
      ]) {
        final values =
            runtime.executeLib(dynamicFixtureLibrary, 'main') as List;
        expect(
          () => values.add('bad'),
          throwsA(isA<TypeError>()),
          reason: mode,
        );
        expect(values, [1], reason: mode);
      }
    });

    test('typed closure lists accept and call matching closures', () {
      _expectValue('''
        int main() {
          var state = 0;
          final listeners = <void Function(int)>[];
          listeners.add((int value) { state += value; });
          listeners.add((int value) { state ^= value * 3; });
          for (var i = 0; i < 4; i++) {
            for (var j = 0; j < listeners.length; j++) {
              listeners[j](i);
            }
          }
          return state;
        }
      ''', _listenersChecksum());
    });

    test('closures stored in a nullable function-typed slot keep their '
        'signature', () {
      _expectValue('''
        void Function(int)? saved;
        int main() {
          saved = (int value) { return; };
          final value = saved;
          if (value is void Function(int)) {
            final listeners = <void Function(int)>[];
            listeners.add(value);
            listeners[0](5);
            return listeners.length;
          }
          return 0;
        }
      ''', 1);
    });
  });
}

int _listenersChecksum() {
  var state = 0;
  final listeners = <void Function(int)>[
    (int value) { state += value; },
    (int value) { state ^= value * 3; },
  ];
  for (var i = 0; i < 4; i++) {
    for (final listener in listeners) {
      listener(i);
    }
  }
  return state;
}
