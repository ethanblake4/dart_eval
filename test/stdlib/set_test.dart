import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  group('Set tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Set.of copies with guest equality, order, and generic types', () {
      for (final (mode, result) in runDynamicFixture(r'''
        class Key {
          Key(this.value);
          final int value;

          @override
          bool operator ==(Object other) =>
              other is Key && other.value == value;

          @override
          int get hashCode => value;
        }

        bool main() {
          final scalars = Set.of([2, 1, 2]);
          if (scalars is! Set<int> || scalars.join(',') != '2,1') {
            return false;
          }

          final strings = Set<String>.of(['a', 'b', 'a']);
          if (strings is! Set<String> || strings.join(',') != 'a,b') {
            return false;
          }

          final first = Key(1);
          final keys = Set<Key>.of([first, Key(1), Key(2)]);
          if (keys.length != 2 ||
              !identical(keys.first, first) ||
              !keys.contains(Key(1)) ||
              keys.map((key) => key.value).join(',') != '1,2') {
            return false;
          }

          final explicit = Set<Object>.of([1, 'one']);
          explicit.add(true);
          if (explicit is! Set<Object> || explicit.length != 3) return false;

          Set<num> contextual = Set.of([1]);
          contextual.add(2.5);
          if (contextual is! Set<num> || contextual.length != 2) return false;

          final source = <int>{3, 4};
          final copy = Set.of(source);
          source.add(5);
          copy.add(6);
          return copy.join(',') == '3,4,6' &&
              source.join(',') == '3,4,5';
        }
      ''')) {
        expect(result, const DynamicFixtureResult.value(true), reason: mode);
      }
    });

    test('Set.of rejects elements incompatible with its type argument', () {
      expect(
        () => compiler.compile({
          'eval_test': {
            'main.dart': '''
              Set<int> main() => Set<int>.of(<String>['wrong']);
            ''',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    });

    test('Creating a set', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final set = {1, 2, 3, 4, 5};
              return set.contains(3).toString();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), 'true');
    });

    test('Adding elements to a set', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final set = <int>{};
              set.add(1);
              set.add(2);
              return set.contains(2).toString();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), 'true');
    });

    test('Removing elements from a set', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final set = {1, 2, 3};
              set.remove(2);
              return set.contains(2).toString();
            }
          ''',
        },
      });

      expect(
        runtime.executeLib('package:eval_test/main.dart', 'main'),
        'false',
      );
    });

    test('Set union operation', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final set1 = {1, 2, 3};
              final set2 = {3, 4, 5};
              final unionSet = set1.union(set2);
              return unionSet.toString();
            }
          ''',
        },
      });

      expect(
        runtime.executeLib('package:eval_test/main.dart', 'main'),
        '{1, 2, 3, 4, 5}',
      );
    });

    test('Set intersection operation', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final set1 = {1, 2, 3};
              final set2 = {2, 3, 4};
              final intersectionSet = set1.intersection(set2);
              return intersectionSet.toString();
            }
          ''',
        },
      });

      expect(
        runtime.executeLib('package:eval_test/main.dart', 'main'),
        '{2, 3}',
      );
    });

    test('Nested set', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final s = {2, 3};
              final nestedSet = {{1, 2}, s, {3, 4}};
              return nestedSet.contains(s).toString();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), 'true');
    });

    test('Set with type parameters', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final set = <double>{1};
              return set.contains(1.0).toString();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), 'true');
    });

    test(
      'containsAll handles guest equality, empty input, and early misses',
      () {
        for (final (mode, result) in runDynamicFixture(r'''
        class Key {
          Key(this.value);
          final int value;

          @override
          bool operator ==(Object other) =>
              other is Key && other.value == value;

          @override
          int get hashCode => value;
        }

        bool main() {
          final values = <Object?>{1, Key(7)};
          var visits = 0;
          final candidates = <int>[2, 1].where((value) {
            visits++;
            return true;
          });

          return values.containsAll([1]) &&
              values.containsAll(<Object?>[]) &&
              values.containsAll([Key(7)]) &&
              !values.containsAll([2]) &&
              !values.containsAll([Key(8)]) &&
              !values.containsAll(candidates) &&
              visits == 1;
        }
      ''')) {
          expect(result, const DynamicFixtureResult.value(true), reason: mode);
        }
      },
    );

    test(
      'removeWhere calls guest predicates with scalar and object elements',
      () {
        for (final (mode, result) in runDynamicFixture(r'''
        class Counter {
          Counter(this.value);
          int value;
        }

        bool main() {
          final values = <int>{1, 2, 3, 4};
          var visits = 0;
          values.removeWhere((value) {
            visits++;
            return value.isEven;
          });

          final counters = <Counter>{Counter(0), Counter(1)};
          counters.removeWhere((counter) {
            counter.value++;
            return counter.value == 1;
          });

          return visits == 4 &&
              values.join(',') == '1,3' &&
              counters.length == 1 &&
              counters.single.value == 2;
        }
      ''')) {
          expect(result, const DynamicFixtureResult.value(true), reason: mode);
        }
      },
    );

    test(
      'retainWhere calls typed guest predicates with scalar and object elements',
      () {
        for (final (mode, result) in runDynamicFixture(r'''
        class Counter {
          Counter(this.value);
          int value;
        }

        bool main() {
          final values = <int>{1, 2, 3, 4};
          var visits = 0;
          values.retainWhere((int value) {
            visits++;
            return value.isEven;
          });

          final counters = <Counter>{Counter(0), Counter(1)};
          counters.retainWhere((Counter counter) {
            counter.value++;
            return counter.value == 2;
          });

          return visits == 4 &&
              values.join(',') == '2,4' &&
              counters.length == 1 &&
              counters.single.value == 2;
        }
      ''')) {
          expect(result, const DynamicFixtureResult.value(true), reason: mode);
        }
      },
    );
  });
}
