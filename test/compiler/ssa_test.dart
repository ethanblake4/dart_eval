import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/memory.dart' show LoadInt;
import 'package:test/test.dart';

void main() {
  ControlFlowGraph compileMain(String source) {
    final compiler = Compiler();
    compiler.compile({
      'ssa_test': {'main.dart': source},
    });
    final id = compiler.functionNames.entries
        .singleWhere((entry) => entry.value.startsWith('main()'))
        .key;
    return compiler.ssaFunctionGraphs[id]!;
  }

  test('validator rejects undefined values', () {
    final graph = compileMain('int main() => 1;');
    final block = graph.graph.vertices
        .map((id) => graph[id]!)
        .singleWhere((block) => block.code.any((op) => op is Return));
    final index = block.code.indexWhere((op) => op is Return);
    block.code[index] = Return(SSA('missing', version: 0));
    expect(() => validateSSA(graph), throwsStateError);
  });

  test('validator rejects duplicate definitions', () {
    final graph = compileMain('int main() => 1;');
    final block = graph.graph.vertices
        .map((id) => graph[id]!)
        .singleWhere((block) => block.code.any((op) => op is LoadInt));
    final load = block.code.whereType<LoadInt>().single;
    block.code.insert(0, LoadInt(load.target.copy(), 2));
    expect(() => validateSSA(graph), throwsStateError);
  });

  test('validator rejects a branch value used beyond its dominance', () {
    final graph = compileMain(
      'int main(bool choose) { var value = 1; if (choose) value = 2; return value; }',
    );
    final blocks = graph.graph.vertices.map((id) => graph[id]!).toList();
    final branchValue = blocks
        .expand((block) => block.code)
        .whereType<LoadInt>()
        .singleWhere((op) => op.value == 2);
    final returnBlock = blocks.singleWhere(
      (block) => block.code.any((op) => op is Return),
    );
    final index = returnBlock.code.indexWhere((op) => op is Return);
    returnBlock.code[index] = Return(branchValue.target.copy());
    expect(() => validateSSA(graph), throwsStateError);
  });

  const sources = {
    'same local assigned by both branches': '''
      int main(bool choose) {
        var result = 1;
        if (choose) { result = 2; } else { result = 3; }
        return result + 4;
      }
    ''',
    'nested loops with break and continue': '''
      int main(int limit) {
        var sum = 0;
        for (var i = 0; i < limit; i++) {
          if (i == 2) continue;
          var j = 0;
          do { j++; if (j == 3) break; sum += j; } while (j < i);
        }
        return sum;
      }
    ''',
    'mutable local captured by a closure': '''
      int main() {
        var count = 0;
        final next = () { count++; return count; };
        next();
        return next();
      }
    ''',
    'optional and named defaults': '''
      int add(int left, [int right = 2]) => left + right;
      int scale(int value, {int factor = 3}) => value * factor;
      int main() => scale(add(1));
    ''',
    'class constructor and instance method': '''
      class Counter {
        int count;
        Counter(this.count);
        int increment() { count++; return count; }
      }
      int main() => Counter(2).increment();
    ''',
    'enum instance and getter': '''
      enum State { idle, active }
      int main() => State.active.index;
    ''',
    'typed catch with local mutation': '''
      int main(bool fail) {
        var result = 0;
        try { if (fail) throw Exception('failed'); result = 1; }
        on Exception catch (error) { result = 2; }
        return result;
      }
    ''',
    'finally executes around early return': '''
      int main(bool early) {
        var result = 0;
        try { if (early) return 1; result = 2; }
        finally { result++; }
        return result;
      }
    ''',
    'async await preserves explicit results': '''
      Future<int> value() async => 3;
      Future<int> main() async {
        final result = await value();
        return result + 1;
      }
    ''',
    'nested ternary and short circuit': '''
      int main(bool left, bool right) {
        final value = left ? (right ? 1 : 2) : 3;
        return (left && right) || !left ? value : 4;
      }
    ''',
  };

  for (final entry in sources.entries) {
    test('SSA dominance: ${entry.key}', () {
      final compiler = Compiler();
      compiler.compile({
        'ssa_test': {'main.dart': entry.value},
      });
      expect(compiler.ssaFunctionGraphs, isNotEmpty);
      for (final function in compiler.ssaFunctionGraphs.entries) {
        final graph = function.value;
        expect(
          graph.inSSAForm,
          isTrue,
          reason: compiler.functionNames[function.key],
        );
        validateSSA(graph);
      }
    });
  }
}
