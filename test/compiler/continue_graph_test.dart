import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/alu.dart' show IntAdd;
import 'package:dart_eval/src/eval/ir/memory.dart' show LoadInt;
import 'package:test/test.dart';

ControlFlowGraph compileLoop(String body) {
  final compiler = Compiler();
  compiler.compile({
    'continue_test': {'main.dart': 'void main(int count) { $body }'},
  });
  final id = compiler.functionNames.entries
      .singleWhere((entry) => entry.value.startsWith('main()'))
      .key;
  return compiler.functionGraphs[id]!;
}

Iterable<Operation> code(ControlFlowGraph graph) sync* {
  for (var id = 0; id < graph.lastBlockId; id++) {
    final block = graph[id];
    if (block != null) yield* block.code;
  }
}

void validateSSA(ControlFlowGraph graph) {
  graph.insertPhiNodes();
  graph.computeSemiPrunedSSA();
  final defined = code(graph).map((op) => op.writesTo).whereType<SSA>().toSet();
  for (final op in code(graph)) {
    expect(defined, containsAll(op.readsFrom), reason: '$op');
  }
}

void main() {
  test(
    'while continue returns to the condition and skips following statements',
    () {
      final graph = compileLoop(
        'while (count > 0) { count--; continue; count = 99; }',
      );
      final header = graph.labels.keys.singleWhere(
        (name) => name.startsWith('loop_header'),
      );
      expect(
        code(graph).whereType<Jump>().map((jump) => jump.target),
        contains(header),
      );
      expect(
        code(graph).whereType<LoadInt>().map((load) => load.value),
        isNot(contains(99)),
      );
      validateSSA(graph);
    },
  );

  test('for continue reaches the updater even with no body fallthrough', () {
    final graph = compileLoop('for (var i = 0; i < count; i++) { continue; }');
    final update = graph.labels.keys.singleWhere(
      (name) => name.startsWith('loop_update'),
    );
    final header = graph.labels.keys.singleWhere(
      (name) => name.startsWith('loop_header'),
    );
    expect(
      code(graph).whereType<Jump>().map((jump) => jump.target),
      containsAll([update, header]),
    );
    expect(graph.graph.predecessorsOf(graph[update]!.id!), hasLength(1));
    final updaterTail =
        graph[graph.graph.successorsOf(graph[update]!.id!).single]!;
    expect(updaterTail.code.whereType<IntAdd>(), hasLength(1));
    expect(updaterTail.code.whereType<Jump>().single.target, header);
    validateSSA(graph);
  });

  test('do-while continue reaches a condition emitted after the body', () {
    final graph = compileLoop('do { count--; continue; } while (count > 0);');
    final header = graph.labels.keys.singleWhere(
      (name) => name.startsWith('loop_header'),
    );
    expect(code(graph).whereType<Jump>().single.target, header);
    expect(code(graph).whereType<JumpIfFalse>(), hasLength(1));
    final headerId = graph[header]!.id!;
    expect(graph.graph.predecessorsOf(headerId), hasLength(1));
    final conditionTail = graph[graph.graph.successorsOf(headerId).single]!;
    expect(conditionTail.code.whereType<JumpIfFalse>(), hasLength(1));
    validateSSA(graph);
  });

  test('continue inside a switch targets the enclosing loop', () {
    final graph = compileLoop('''
      while (count > 0) {
        count--;
        switch (count) { case 1: continue; default: break; }
      }
    ''');
    final header = graph.labels.keys.singleWhere(
      (name) => name.startsWith('loop_header'),
    );
    expect(
      code(graph).whereType<Jump>().where((jump) => jump.target == header),
      hasLength(2),
    );
    validateSSA(graph);
  });

  test('nested continue targets the innermost loop', () {
    final graph = compileLoop(
      'while (count > 0) { while (count > 1) { count--; continue; } break; }',
    );
    final headers = graph.labels.keys
        .where((name) => name.startsWith('loop_header'))
        .toList();
    expect(headers, hasLength(2));
    expect(
      code(
        graph,
      ).whereType<Jump>().where((jump) => jump.target == headers.last),
      hasLength(1),
    );
    expect(
      code(
        graph,
      ).whereType<Jump>().where((jump) => jump.target == headers.first),
      isEmpty,
    );
    validateSSA(graph);
  });

  test('for-in continue advances the iterator before re-entering the body', () {
    final graph = compileLoop('for (final value in [1, 2]) { continue; }');
    final bodies = graph.labels.keys
        .where((name) => name.startsWith('loop_body'))
        .toList();
    expect(bodies, isNotEmpty);
    final jumps = code(graph).whereType<Jump>().toList();
    for (final body in bodies) {
      final suffix = body.substring('loop_body'.length);
      expect(
        jumps.any(
          (jump) =>
              jump.target == 'loop_update$suffix' ||
              jump.target == 'loop_header$suffix',
        ),
        isTrue,
        reason: 'continue in $body returns to the loop advance',
      );
    }
    validateSSA(graph);
  });

  test('continue outside a loop is rejected', () {
    expect(() => compileLoop('continue;'), throwsA(isA<CompileError>()));
  });
}
