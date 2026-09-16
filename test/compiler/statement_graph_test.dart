import 'package:dart_eval/src/eval/ir/exception.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:test/test.dart';

import 'control_flow_graph_test.dart'
    show compileGraph, namedGraph, operations, expectDefinedReads;

void main() {
  test('break inside an if targets the surrounding loop exit', () {
    final graph = namedGraph(
      compileGraph('''
      int main(bool stop) {
        while (true) { if (stop) { break; } }
        return 7;
      }
    '''),
      'main()',
    );
    expect(
      operations(
        graph,
      ).whereType<Jump>().any((jump) => jump.target.startsWith('loop_exit')),
      isTrue,
    );
    expect(operations(graph).whereType<Return>(), hasLength(1));
    expectDefinedReads(graph);
  });

  test('do while break preserves the continuation after the loop', () {
    final graph = namedGraph(
      compileGraph('''
      int main() { do { break; } while (true); return 7; }
    '''),
      'main()',
    );
    expect(operations(graph).whereType<Return>(), hasLength(1));
    expectDefinedReads(graph);
  });

  test('returns in both branches have no fallthrough successors', () {
    final graph = namedGraph(
      compileGraph('''
      int main(bool condition) {
        if (condition) { return 1; } else { return 2; }
      }
    '''),
      'main()',
    );
    for (var id = 0; id < graph.lastBlockId; id++) {
      final block = graph[id];
      if (block == null) continue;
      if (block.code.isNotEmpty && block.code.last is Return) {
        expect(graph.graph.successorsOf(id), isEmpty);
      }
    }
  });

  test('try finally handler is reachable without a self edge', () {
    final graph = namedGraph(
      compileGraph('''
      int main() {
        var result = 0;
        try { result = 1; } finally { result = 2; }
        return result;
      }
    '''),
      'main()',
    );
    final handler = operations(
      graph,
    ).whereType<EnterTry>().single.finallyTarget!;
    final id = graph[handler]!.id!;
    expect(graph.graph.predecessorsOf(id), isNotEmpty);
    expect(graph.graph.successorsOf(id), isNot(contains(id)));
    expect(operations(graph).whereType<ResumeCompletion>(), hasLength(1));
    expectDefinedReads(graph);
  });
}
