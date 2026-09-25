import 'package:control_flow_graph/control_flow_graph.dart' as cfg;
import '../../ir/alu.dart' as alu;
import '../../ir/collection.dart' as collection;
import '../../ir/memory.dart' as memory;
import '../../ir/objects.dart' as objects;
import '../../ir/primitives.dart' as primitives;
import '../../ir/representation.dart';

/// Simplifies proven primitive conversions on a private SSA graph.
void optimizePrimitives(cfg.ControlFlowGraph graph) {
  Iterable<cfg.Operation> operations() sync* {
    for (final id in graph.graph.vertices) {
      yield* graph[id]!.code;
    }
  }

  final nativeLists = <cfg.SSA>{};
  var changed = true;
  while (changed) {
    changed = false;
    for (final op in operations()) {
      final target = op.writesTo;
      if (target == null || nativeLists.contains(target)) continue;
      final proven = switch (op) {
        collection.NewList() => true,
        primitives.BoxList(:final source) ||
        memory.Assign(:final source) ||
        cfg.Assign(:final source) => nativeLists.contains(source),
        cfg.PhiNode(:final sources) =>
          sources.isNotEmpty && sources.every(nativeLists.contains),
        _ => false,
      };
      if (proven) changed |= nativeLists.add(target);
    }
  }
  var next = 0;
  for (final id in graph.graph.vertices) {
    final code = graph[id]!.code;
    final rewritten = <cfg.Operation>[];
    for (final op in code) {
      if (op is objects.LoadPropertyDynamic &&
          op.name == 'length' &&
          nativeLists.contains(op.object)) {
        final length = cfg.SSA('optimized:listLength${next++}', version: 0);
        rewritten.add(collection.ListLength(length, op.object));
        rewritten.add(primitives.BoxInt(op.target, length));
      } else {
        rewritten.add(op);
      }
    }
    code
      ..clear()
      ..addAll(rewritten);
  }
  final definitions = {for (final op in operations()) ?op.writesTo: op};
  cfg.Operation? definition(cfg.SSA value) {
    final seen = <cfg.SSA>{};
    while (seen.add(value)) {
      final op = definitions[value];
      final source = switch (op) {
        memory.Assign(:final source) || cfg.Assign(:final source) => source,
        _ => null,
      };
      if (source == null) return op;
      value = source;
    }
    return null;
  }

  for (final id in graph.graph.vertices) {
    final code = graph[id]!.code;
    for (var i = 0; i < code.length; i++) {
      final op = code[i];
      if (op is primitives.Unbox) {
        final source = switch ((definition(op.source), op.representation)) {
          (primitives.BoxInt(:final source), MachineRepresentation.integer) =>
            source,
          (
            primitives.BoxDouble(:final source),
            MachineRepresentation.doublePrecision,
          ) =>
            source,
          (primitives.BoxBool(:final source), MachineRepresentation.boolean) =>
            source,
          (primitives.BoxString(:final source), MachineRepresentation.string) =>
            source,
          _ => null,
        };
        if (source != null) code[i] = cfg.Assign(op.target, source);
      } else if (op is alu.IntAdd) {
        final left = definition(op.left), right = definition(op.right);
        if (right is memory.LoadInt && right.value == 1) {
          code[i] = alu.Increment(op.writesTo!, op.left);
        } else if (left is memory.LoadInt && left.value == 1) {
          code[i] = alu.Increment(op.writesTo!, op.right);
        }
      }
    }
  }
  // Keep escaped wrappers, arbitrary unboxing, and potentially effectful reads.
  changed = true;
  while (changed) {
    changed = false;
    final used = {for (final op in operations()) ...op.readsFrom};
    for (final id in graph.graph.vertices) {
      graph[id]!.code.removeWhere((op) {
        final removable =
            op is primitives.BoxInt ||
            op is primitives.BoxDouble ||
            op is primitives.BoxBool ||
            op is primitives.BoxString ||
            op is memory.Assign ||
            op is cfg.Assign ||
            op is memory.LoadInt;
        final dead =
            removable && op.writesTo != null && !used.contains(op.writesTo);
        changed |= dead;
        return dead;
      });
    }
  }
}
