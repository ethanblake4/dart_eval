import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void _expectValue(String source, Object? expected) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, DynamicFixtureResult.value(expected), reason: mode);
  }
}

void main() {
  group('reified dynamic map writes', () {
    test('rejects indexed key and value mismatches before mutation', () {
      _expectValue('''
        int main() {
          dynamic values = <String, int>{'a': 1};
          var result = 0;
          try {
            values[2] = 2;
          } on TypeError {
            if (values.length == 1) result += 1;
          }
          try {
            values['b'] = 'bad';
          } on TypeError {
            if (!values.containsKey('b')) result += 2;
          }
          return result;
        }
      ''', 3);
    });

    test('validates addAll atomically and accepts subtype entries', () {
      _expectValue('''
        int main() {
          dynamic values = <Object, num>{'a': 1};
          dynamic alias = values;
          values.addAll(<String, int>{'b': 2});
          try {
            values.addAll(<dynamic, dynamic>{'c': 3, 'd': 'bad'});
          } on TypeError {
            if (!identical(values, alias)) return -2;
            if (values.length != 2) return -3;
            if (values.containsKey('c')) return -4;
            if (values is! Map<Object, num>) return -5;
            return 120;
          }
          return -1;
        }
      ''', 120);
    });

    test('exported views do not apply write checks to queries', () {
      final program = Compiler().compile({
        'dynamic_fixtures': {
          'main.dart': '''
            Map<String, int> mapValue() => <String, int>{'a': 1};
            Set<int> setValue() => <int>{1};
          ''',
        },
      });
      for (final (mode, runtime) in [
        ('fresh', Runtime.ofProgram(program)),
        ('serialized', Runtime(program.write().buffer)),
      ]) {
        final map =
            runtime.executeLib(dynamicFixtureLibrary, 'mapValue') as Map;
        expect(map[2], isNull, reason: mode);
        expect(map.containsKey(2), isFalse, reason: mode);
        expect(map.remove(2), isNull, reason: mode);

        final set =
            runtime.executeLib(dynamicFixtureLibrary, 'setValue') as Set;
        expect(set.contains('bad'), isFalse, reason: mode);
        expect(set.lookup('bad'), isNull, reason: mode);
        expect(set.remove('bad'), isFalse, reason: mode);
      }
    });
  });

  group('reified dynamic set writes', () {
    test('rejects add and addAll atomically', () {
      _expectValue('''
        int main() {
          dynamic values = <int>{1};
          var result = 0;
          try {
            values.add('bad');
          } on TypeError {
            if (values.length == 1) result += 1;
          }
          try {
            values.addAll(<dynamic>{2, 'bad'});
          } on TypeError {
            if (values.length == 1 && !values.contains(2)) result += 2;
          }
          return result;
        }
      ''', 3);
    });

    test('derived set wrappers retain their element type', () {
      _expectValue('''
        int main() {
          dynamic values = <num>{1};
          var rejected = false;
          try {
            values.union(<dynamic>{'bad'});
          } on TypeError {
            rejected = true;
            if (values.length != 1) return -3;
          }
          if (!rejected) return -4;
          dynamic combined = values.union(<num>{2});
          if (combined is! Set<num>) return -2;
          combined.add(3);
          try {
            combined.add('bad');
          } on TypeError {
            return combined.length;
          }
          return -1;
        }
      ''', 3);
    });
  });
}
