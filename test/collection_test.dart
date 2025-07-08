import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Iterable tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Iterable.join()', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final list = [1, 2, 3, 4, 5];
              return list.join();
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'),
          $String('12345'));
    });

    test('Iterable.map()', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final list = [1, 2, 3, 4, 5];
              return list.map((e) => e * 2).join();
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'),
          $String('246810'));
    });

    test('List.length', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final list = [1, 2, 3, 4, 5];
              return list.length.toString();
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'),
          $String('5'));
    });

    test('List.add()', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final list = [1, 2, 3, 4, 5];
              list.add(6);
              return list.join();
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'),
          $String('123456'));
    });
  });

  group('Collection tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Collection if', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final i = 3, k = 2, l = 1;

              var list = [
                if (i == 3) 1, 
                if (k == 2) 2, 
                if (l == 1) 3 else if (k == 2) 4,
                if (l == 2) 5 else 6,
                if (l == 2) 7 else if (k == 2) 8,
              ];

              return list.join();
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'),
          $String('12368'));
    });

    test('Collection for', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            String main() {
              final j = 3, k = 2, l = 1;

              var list = [
                for (var i = 0; i < 3; i = i + 1) i,
                for (var i = 0; i < 3; i = i + 1) if (i == 1) i,
                for (var i = 0; i < 3; i = i + 1) if (i == 1) j else i,
                for (var i = 0; i < 3; i = i + 1) if (i == 1) k else if (i == 2) j,
                for (var i = 0; i < 3; i = i + 1) if (i == 1) i else if (i == 2) i else j,
              ];

              return list.join();
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'),
          $String('012103223312'));
    });

    test('Basic spread operator with list literal', () {
      const source = '''
        List<int> test() {
          var list1 = [1, 2, 3];
          var list2 = [0, ...list1, 4];
          return list2;
        }
      ''';

      final runtime = compiler.compileWriteAndLoad({
        'test': {'main.dart': source}
      });

      final result = runtime.executeLib('package:test/main.dart', 'test');

      expect(result, equals([0, 1, 2, 3, 4].map((e) => $int(e)).toList()));
    });

    test('Spread operator with empty list', () {
      const source = '''
        List<int> test() {
          var empty = <int>[];
          var list = [1, ...empty, 2];
          return list;
        }
      ''';

      final compiler = Compiler();
      final runtime = compiler.compileWriteAndLoad({
        'test': {'main.dart': source}
      });

      final result = runtime.executeLib('package:test/main.dart', 'test');
      expect(result, equals([1, 2].map((e) => $int(e)).toList()));
    });

    test('Multiple spread operators', () {
      const source = '''
        List<int> test() {
          var list1 = [1, 2];
          var list2 = [3, 4];
          var combined = [...list1, ...list2];
          return combined;
        }
      ''';

      final runtime = compiler.compileWriteAndLoad({
        'test': {'main.dart': source}
      });

      final result = runtime.executeLib('package:test/main.dart', 'test');

      expect(result, equals([1, 2, 3, 4].map((e) => $int(e)).toList()));
    });

  });

  group('Map tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Map.containsKey()', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            bool main() {
              final testMap = {'name': 'Jon', 'id':0};
              return testMap.containsKey('id');
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), true);
    });

    test('Empty map literal', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            bool main() {
              final testMap = {};
              return testMap.isEmpty;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), true);
    });

    test('Add key to empty map', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            bool main() {
              final testMap = <String, String>{};
              testMap['name'] = 'Jon';
              return testMap.isNotEmpty;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), true);
    });

    test('Map null values == null', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            bool main() {
              final e = [{'name': null}];
              for (var item in e) {
                bool ifNull = item['name'] == null;
                return ifNull; 
              }
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), true);
    });
  });
}
