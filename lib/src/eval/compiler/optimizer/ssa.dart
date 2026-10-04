import 'package:control_flow_graph/control_flow_graph.dart';

import '../context.dart';
import 'indexed_loops.dart';
import 'validate.dart';

/// Specialize and cache a function's SSA graph for backend reachability.
ControlFlowGraph prepareFunctionSSA(CompilerContext context, int id) {
  final cached = context.ssaFunctionGraphs[id];
  if (cached != null) return cached;
  final graph = context.functionGraphs[id]!;
  specializeIndexedLoops(graph);
  validateFrontendGraph(graph);
  return context.ssaFunctionGraphs[id] = buildSSA(graph);
}

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
