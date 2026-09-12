import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/ir/closures.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/src/eval/ir/memory.dart' show LoadInt;
import 'package:test/test.dart';

Compiler compileGraph(String source) {
  final compiler = Compiler();
  compiler.compile({
    'cfg_test': {'main.dart': source},
  });
  return compiler;
}

ControlFlowGraph namedGraph(Compiler compiler, String name) {
  final id = compiler.functionNames.entries
      .singleWhere((entry) => entry.value.startsWith(name))
      .key;
  return compiler.functionGraphs[id]!;
}

Iterable<Operation> operations(ControlFlowGraph graph) sync* {
  for (var id = 0; id < graph.lastBlockId; id++) {
    final block = graph[id];
    if (block != null) yield* block.code;
  }
}

void expectDefinedReads(ControlFlowGraph graph) {
  final code = operations(graph).toList();
  final definitions = code.map((op) => op.writesTo).whereType<SSA>().toSet();
  for (final op in code) {
    expect(
      definitions,
      containsAll(op.readsFrom),
      reason: '$op reads an undefined value',
    );
  }
}

void main() {
  test('function parameters and return values have explicit definitions', () {
    final graph = namedGraph(
      compileGraph('int main(int value) => value + 1;'),
      'main()',
    );
    expect(operations(graph).whereType<Parameter>(), hasLength(1));
    expect(operations(graph).whereType<Return>().single.value, isNotNull);
    expectDefinedReads(graph);
  });

  test('both branches connect to a shared continuation', () {
    final graph = namedGraph(
      compileGraph('''
      int main(bool condition) {
        var result = 0;
        if (condition) { result = 1; } else { result = 2; }
        return result;
      }
    '''),
      'main()',
    );
    expect(operations(graph).whereType<JumpIfFalse>(), hasLength(1));
    final join = graph.labels.entries.singleWhere(
      (entry) => entry.key.startsWith('if_end'),
    );
    expect(graph.graph.predecessorsOf(join.value), hasLength(2));
    expectDefinedReads(graph);
    graph.insertPhiNodes();
    graph.computeSemiPrunedSSA();
    expect(graph.inSSAForm, isTrue);
    expectDefinedReads(graph);
  });

  test('while loop has a back edge to its condition', () {
    final graph = namedGraph(
      compileGraph('''
      int main(int count) {
        var result = 0;
        while (count > 0) { result += count; count--; }
        return result;
      }
    '''),
      'main()',
    );
    final branch = operations(graph).whereType<JumpIfFalse>().single;
    expect(graph[branch.target], isNotNull);
    final jumps = operations(graph).whereType<Jump>();
    expect(
      jumps.any(
        (jump) =>
            graph.graph.predecessorsOf(graph[jump.target]!.id!).length > 1,
      ),
      isTrue,
    );
    expectDefinedReads(graph);
    graph.insertPhiNodes();
    graph.computeSemiPrunedSSA();
    expect(graph.inSSAForm, isTrue);
    expectDefinedReads(graph);
  });

  test(
    'closure captures and parameters belong to a separate function graph',
    () {
      final compiler = compileGraph('''
      int main(int base) {
        final add = (int value) => base + value;
        return add(2);
      }
    ''');
      final outer = namedGraph(compiler, 'main()');
      final inner = namedGraph(compiler, '<anonymous closure>');
      expect(operations(outer).whereType<CreateClosure>(), hasLength(1));
      expect(operations(outer).whereType<InvokeClosure>(), hasLength(1));
      expect(operations(inner).whereType<LoadCapture>(), isNotEmpty);
      expect(operations(inner).whereType<Parameter>(), hasLength(1));
      expect(operations(outer).whereType<LoadCapture>(), isEmpty);
      expectDefinedReads(outer);
      expectDefinedReads(inner);
    },
  );

  test(
    'static calls preserve argument order and define the consumed result',
    () {
      final compiler = compileGraph('''
      int subtract(int first, int second) => first - second;
      int main() => subtract(9, 4);
    ''');
      final graph = namedGraph(compiler, 'main()');
      final call = operations(graph).whereType<Call>().single;
      expect(call.arguments, hasLength(2));
      final constants = {
        for (final load in operations(graph).whereType<LoadInt>())
          load.target: load.value,
      };
      expect(call.arguments.map((argument) => constants[argument]), [9, 4]);
      expect(call.writesTo, isNotNull);
      expect(operations(graph).whereType<Return>().single.value, call.writesTo);
      expectDefinedReads(graph);
    },
  );
}
