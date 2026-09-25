import 'package:control_flow_graph/control_flow_graph.dart' as cfg;
import 'package:dart_eval/src/eval/ir/exception.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

/// Checks the frontend contract before any graph transformations run.
void validateFrontendGraph(cfg.ControlFlowGraph graph) {
  final handlers = <int>{};
  for (final id in graph.graph.vertices) {
    final block = graph[id]!;
    for (final op in block.code) {
      if (op is EnterTry) {
        for (final label in [op.catchTarget, op.finallyTarget]) {
          if (label != null) {
            final target = graph[label];
            if (target == null) throw StateError('Missing handler $label');
            handlers.add(target.id!);
          }
        }
      }
    }
  }
  cfg.validateControlFlowGraph(
    graph,
    branchTarget: (op) => switch (op) {
      Jump(:final target) ||
      JumpIfFalse(:final target) ||
      JumpIfNull(:final target) ||
      JumpIfNonNull(:final target) => target,
      _ => null,
    },
    isExit: (op) =>
        op is Return || op is ReturnAsync || op is Throw || op is Rethrow,
    isUnconditionalBranch: (op) => op is Jump,
    ignoredSuccessors: handlers,
  );
}
