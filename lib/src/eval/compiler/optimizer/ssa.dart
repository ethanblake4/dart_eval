import 'package:control_flow_graph/control_flow_graph.dart';
import 'validate_ssa.dart';

/// Keeps the frontend graph available for diagnostics while passes own copies.
ControlFlowGraph copyGraph(ControlFlowGraph source) {
  final result = ControlFlowGraph();
  final blocks = <int, BasicBlock>{};
  for (final id in source.graph.vertices) {
    final original = source[id]!;
    final block = BasicBlock<Operation>([
      for (final operation in original.code)
        operation.copyWith(
          readsFrom: {for (final input in operation.readsFrom) input.copy()},
          writesTo: operation.writesTo?.copy(),
        ),
    ], label: original.label)..id = id;
    result.append(block);
    blocks[id] = block;
  }
  result.lastBlockId = source.lastBlockId;
  result.root = blocks[source.root.id]!;
  for (final id in source.graph.vertices) {
    for (final successor in source.graph.successorsOf(id)) {
      result.link(blocks[id]!, blocks[successor]!);
    }
  }
  return result;
}

ControlFlowGraph buildSSA(ControlFlowGraph source) {
  final graph = copyGraph(source);
  graph.insertPhiNodes();
  graph.computeSemiPrunedSSA();
  validateSSA(graph);
  graph.removeUnusedDefines();
  validateSSA(graph);
  return graph;
}
