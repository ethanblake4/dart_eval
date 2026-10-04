import 'package:control_flow_graph/control_flow_graph.dart' as cfg;

import '../../ir/async.dart' as async_ir;
import '../../ir/bridge.dart' as bridge;
import '../../ir/collection.dart' as collection;
import '../../ir/exception.dart' as exceptions;
import '../../ir/flow.dart' as flow;
import '../../ir/generators.dart' as generators;
import '../../ir/memory.dart' as memory;
import '../../ir/primitives.dart' as primitives;
import '../../ir/representation.dart';
import '../../ir/string.dart';
import 'loop_invariants.dart';

/// Reuses reads of fresh guest list storage within a block and along a forward
/// edge with one predecessor. Reads never move, and mutations clear all facts.
void reuseFreshNativeListReads(
  cfg.ControlFlowGraph graph, {
  int? filledListConstructorId,
}) {
  var indexedReads = 0;
  var hasFreshAllocation = false;
  for (final id in graph.graph.vertices) {
    for (final op in graph[id]!.code) {
      if (op is exceptions.EnterTry ||
          op is async_ir.BeginAsync ||
          op is async_ir.Await ||
          op is generators.BeginGenerator ||
          op is generators.YieldGenerator) {
        return;
      }
      if (op is collection.IndexList) indexedReads++;
      if (op is collection.NewList ||
          op is bridge.BridgeInstantiate &&
              filledListConstructorId != null &&
              op.externalFunctionId == filledListConstructorId) {
        hasFreshAllocation = true;
      }
    }
  }
  if (indexedReads < 2 || !hasFreshAllocation) return;
  final definitions = cfg.SSADefinitions(graph);
  final allocations = <cfg.SSA, cfg.SSA?>{};
  cfg.SSA? allocation(cfg.SSA value) {
    if (allocations.containsKey(value)) return allocations[value];
    final original = value;
    final seen = <cfg.SSA>{};
    cfg.SSA? result;
    while (seen.add(value)) {
      final op = definitions[value];
      if (op is collection.NewList ||
          op is bridge.BridgeInstantiate &&
              filledListConstructorId != null &&
              op.externalFunctionId == filledListConstructorId &&
              definitions.throughCopies(op.subclass) is memory.LoadNull) {
        result = value;
        break;
      }
      value = switch (op) {
        cfg.Assign(:final source) ||
        primitives.BoxList(:final source) => source,
        primitives.Unbox(:final source, :final representation)
            when representation == MachineRepresentation.object =>
          source,
        _ => value,
      };
    }
    return allocations[original] = result;
  }

  cfg.SSA canonical(cfg.SSA value) =>
      definitions.throughCopies(value)?.writesTo ?? value;
  bool preservesReads(cfg.Operation op) => switch (op) {
    flow.Jump() ||
    flow.JumpIfFalse() ||
    flow.JumpIfNull() ||
    flow.JumpIfNonNull() ||
    primitives.BoxInt() ||
    primitives.BoxDouble() ||
    primitives.BoxBool() ||
    primitives.BoxString() ||
    primitives.BoxNull() ||
    primitives.BoxList() ||
    StringOperation() ||
    StringSubstring() => true,
    primitives.Unbox(:final source, :final representation) =>
      representation != MachineRepresentation.object ||
          allocation(source) != null,
    collection.ListLength(:final list) => allocation(list) != null,
    _ => isNonThrowingPrimitive(op),
  };

  final exits = <int, Map<(cfg.SSA, cfg.SSA), cfg.SSA>>{};
  final dominators = graph.dominators;
  final tree = graph.dominatorTree;
  final pending = [graph.root.id!];
  while (pending.isNotEmpty) {
    final id = pending.removeLast();
    pending.addAll(tree.successorsOf(id).where((child) => child != id));
    final predecessors = graph.graph.predecessorsOf(id).toList();
    final inherited =
        predecessors.length == 1 && dominators[id] == predecessors.single
        ? exits[predecessors.single]
        : null;
    final reads = <(cfg.SSA, cfg.SSA), cfg.SSA>{...?inherited};
    final code = graph[id]!.code;
    for (var i = 0; i < code.length; i++) {
      final op = code[i];
      if (op is collection.IndexList) {
        final owner = allocation(op.list);
        if (owner == null) {
          reads.clear();
          continue;
        }
        final key = (owner, canonical(op.index));
        final previous = reads[key];
        if (previous == null) {
          reads[key] = op.target;
        } else {
          code[i] = cfg.Assign(op.target, previous);
        }
      } else if (reads.isNotEmpty && !preservesReads(op)) {
        reads.clear();
      }
    }
    exits[id] = reads;
  }
}
