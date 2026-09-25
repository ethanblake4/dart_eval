import 'package:control_flow_graph/control_flow_graph.dart';

ControlFlowGraph buildSSA(ControlFlowGraph source) {
  final graph = source.clone();
  graph.insertPhiNodes();
  // clone already gave every operand its own SSA instance, so renaming
  // can mutate versions in place without an extra deep-copy pass.
  graph.computeSemiPrunedSSA(copyOperands: false);
  validateSSA(graph);
  graph.removeUnusedDefines();
  validateSSA(graph);
  return graph;
}
