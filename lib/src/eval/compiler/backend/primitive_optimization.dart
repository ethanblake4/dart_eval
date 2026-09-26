import 'package:control_flow_graph/control_flow_graph.dart' as cfg;
import '../../ir/alu.dart' as alu;
import '../../ir/collection.dart' as collection;
import '../../ir/exception.dart' as exceptions;
import '../../ir/memory.dart' as memory;
import '../../ir/objects.dart' as objects;
import '../../ir/primitives.dart' as primitives;
import '../../ir/representation.dart';
import '../../ir/string.dart';

/// Values proven to contain a native list before any list operation is lowered.
/// Boxing and copies preserve that property; a phi does so only when all of
/// its inputs do. Unboxing is included by the later lowering stage.
Set<cfg.SSA> inferNativeListValues(
  Iterable<cfg.Operation> operations, {
  bool throughUnbox = false,
}) {
  final code = operations.toList();
  final nativeLists = <cfg.SSA>{};
  var changed = true;
  while (changed) {
    changed = false;
    for (final op in code) {
      final target = op.writesTo;
      if (target == null || nativeLists.contains(target)) continue;
      final proven = switch (op) {
        collection.NewList() => true,
        primitives.BoxList(:final source) ||
        cfg.Assign(:final source) => nativeLists.contains(source),
        primitives.Unbox(:final source) when throughUnbox =>
          nativeLists.contains(source),
        cfg.PhiNode(:final sources) =>
          sources.isNotEmpty && sources.every(nativeLists.contains),
        _ => false,
      };
      if (proven) changed |= nativeLists.add(target);
    }
  }
  return nativeLists;
}

/// Simplifies proven primitive conversions on a private SSA graph.
void optimizePrimitives(cfg.ControlFlowGraph graph) {
  Iterable<cfg.Operation> operations() sync* {
    for (final id in graph.graph.vertices) {
      yield* graph[id]!.code;
    }
  }

  final nativeLists = inferNativeListValues(operations());
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
  final definitions = cfg.SSADefinitions(graph);
  cfg.Operation? definition(cfg.SSA value) => definitions.throughCopies(value);

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
  // Catch edges can leave before a block's last definition has executed.
  // Normal block dominance is sufficient only without these edges.
  if (!operations().any((op) => op is exceptions.EnterTry)) {
    cfg.eliminateCommonExpressions(
      graph,
      (op, resolve) => switch (op) {
        StringOperation(:final operator, :final string, :final argument)
            when operator != StringOperator.concatenate =>
          (
            operator,
            resolve(string),
            argument == null ? null : resolve(argument),
          ),
        primitives.Unbox(:final source, :final representation)
            when representation != MachineRepresentation.object =>
          (primitives.Unbox, resolve(source), representation),
        _ => null,
      },
    );
  }
  // Keep escaped wrappers, arbitrary unboxing, and potentially effectful reads.
  graph.removeUnusedDefines(
    canRemove: (op) =>
        op is primitives.BoxInt ||
        op is primitives.BoxDouble ||
        op is primitives.BoxBool ||
        op is primitives.BoxString ||
        op is cfg.Assign ||
        op is memory.LoadInt,
  );
}
