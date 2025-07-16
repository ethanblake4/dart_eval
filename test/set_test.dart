import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:test/test.dart';

void main() {
  group('Set tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Creating a set', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final set = {1, 2, 3, 4, 5};
              return set.contains(3).toString();
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'),
          $String('true'));
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
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'),
          $String('true'));
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
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'),
          $String('false'));
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
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'),
          $String('{1, 2, 3, 4, 5}'));
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
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'),
          $String('{2, 3}'));
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
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'),
          $String('true'));
    });

    test('Set with type parameters', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final set = <double>{1};
              return set.contains(1.0).toString();
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'),
          $String('true'));
    });
  });
}
