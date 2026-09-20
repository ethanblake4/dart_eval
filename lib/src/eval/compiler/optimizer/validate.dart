import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/ir/exception.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

/// Checks the frontend contract before any graph transformations run.
void validateControlFlowGraph(ControlFlowGraph graph) {
  final blocks = [for (var id = 0; id < graph.lastBlockId; id++) ?graph[id]];
  final handlers = <int>{};
  final definitions = <String>{};
  for (final block in blocks) {
    for (final op in block.code) {
      if (op.writesTo case final result?) definitions.add(result.name);
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
  for (final block in blocks) {
    for (var i = 0; i < block.code.length; i++) {
      final op = block.code[i];
      for (final input in op.readsFrom) {
        if (!definitions.contains(input.name)) {
          throw StateError(
            '${block.label ?? block.id}: $op reads undefined $input',
          );
        }
      }
      final target = switch (op) {
        Jump(:final target) ||
        JumpIfFalse(:final target) ||
        JumpIfNull(:final target) ||
        JumpIfNonNull(:final target) => target,
        _ => null,
      };
      final exits =
          op is Return || op is ReturnAsync || op is Throw || op is Rethrow;
      if (target == null && !exits) continue;
      if (i != block.code.length - 1) {
        throw StateError(
          '${block.label ?? block.id}: operation follows terminator $op',
        );
      }
      final successors = graph.graph.successorsOf(block.id!).toSet();
      if (target != null) {
        final destination = graph[target];
        if (destination == null || !successors.contains(destination.id)) {
          throw StateError(
            '${block.label ?? block.id}: missing edge to $target',
          );
        }
        if (op is Jump &&
            successors.difference({...handlers, destination.id!}).isNotEmpty) {
          throw StateError(
            '${block.label ?? block.id}: unconditional jump has fallthrough',
          );
        }
      } else if (successors.difference(handlers).isNotEmpty) {
        throw StateError(
          '${block.label ?? block.id}: return/throw has fallthrough',
        );
      }
    }
  }
}
