import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

void main() {
  group('SpreadElement tests', () {
    late Program program;

    test('Basic spread operator with list literal', () {
      const source = '''
        List<int> test() {
          var list1 = [1, 2, 3];
          var list2 = [0, ...list1, 4];
          return list2;
        }
      ''';

      final compiler = Compiler();
      program = compiler.compile({
        'test': {'main.dart': source}
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:test/main.dart', 'test');

      // Converte os valores boxed para valores primitivos para comparação
      final unboxedResult =
          (result as List).map((e) => e is $Value ? e.$reified : e).toList();
      expect(unboxedResult, equals([0, 1, 2, 3, 4]));
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
      program = compiler.compile({
        'test': {'main.dart': source}
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:test/main.dart', 'test');

      // Converte os valores boxed para valores primitivos para comparação
      final unboxedResult =
          (result as List).map((e) => e is $Value ? e.$reified : e).toList();
      expect(unboxedResult, equals([1, 2]));
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

      final compiler = Compiler();
      program = compiler.compile({
        'test': {'main.dart': source}
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:test/main.dart', 'test');

      // Converte os valores boxed para valores primitivos para comparação
      final unboxedResult =
          (result as List).map((e) => e is $Value ? e.$reified : e).toList();
      expect(unboxedResult, equals([1, 2, 3, 4]));
    });
  });
}
