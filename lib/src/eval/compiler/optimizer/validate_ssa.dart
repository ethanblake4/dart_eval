import 'package:control_flow_graph/control_flow_graph.dart';

/// Checks definitions and dominance after SSA conversion.
///
/// Phi inputs are read on incoming edges. The graph's branch marker is a
/// control-flow output rather than a value definition and remains unversioned.
void validateSSA(ControlFlowGraph graph) {
  if (!graph.inSSAForm) {
    throw StateError('SSA validation requires an SSA graph');
  }
  final reachable = <int>{};
  final pending = <int>[graph.root.id!];
  while (pending.isNotEmpty) {
    final id = pending.removeLast();
    if (reachable.add(id)) pending.addAll(graph.graph.successorsOf(id));
  }

  final definitions = <SSA, (int, int)>{};
  for (final id in reachable) {
    final block = graph[id]!;
    for (var index = 0; index < block.code.length; index++) {
      final target = block.code[index].writesTo;
      if (target == null || target == ControlFlowGraph.branch) continue;
      if (target.version < 0) {
        throw StateError('B$id: unversioned definition $target');
      }
      if (definitions.containsKey(target)) {
        throw StateError('B$id: $target has multiple definitions');
      }
      definitions[target] = (id, index);
    }
  }

  bool dominates(int definition, int use) {
    var current = use;
    while (current != definition) {
      final parent = graph.dominators[current];
      if (parent == null || parent == current) return false;
      current = parent;
    }
    return true;
  }

  for (final id in reachable) {
    final block = graph[id]!;
    for (var index = 0; index < block.code.length; index++) {
      final operation = block.code[index];
      for (final source in operation.readsFrom) {
        final definition = definitions[source];
        if (definition == null) {
          throw StateError('B$id: $operation reads undefined $source');
        }
        final (definitionBlock, definitionIndex) = definition;
        if (operation is PhiNode) {
          if (!graph.graph
              .predecessorsOf(id)
              .any((predecessor) => dominates(definitionBlock, predecessor))) {
            throw StateError(
              'B$id: phi input $source does not dominate an incoming edge',
            );
          }
        } else if (!dominates(definitionBlock, id) ||
            (definitionBlock == id && definitionIndex >= index)) {
          throw StateError('B$id: $source does not dominate $operation');
        }
      }
    }
  }
}
