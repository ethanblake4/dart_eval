import 'package:control_flow_graph/control_flow_graph.dart' as cfg;

import '../../ir/async.dart' as async_ir;
import '../../ir/collection.dart' as collection;
import '../../ir/exception.dart' as exceptions;
import '../../ir/flow.dart' as flow;
import '../../ir/objects.dart' as objects;
import '../../ir/primitives.dart' as primitives;

/// Gives small indexed loops a direct path for canonical native list storage.
/// The original loop retains guest and external wrapper operator dispatch.
void specializeIndexedLoops(cfg.ControlFlowGraph graph) {
  if (graph.graph.vertices.length > 64) return;
  final definitions = <cfg.SSA, List<(int, cfg.Operation)>>{};
  var hasIndex = false;
  for (final id in graph.graph.vertices) {
    for (final op in graph[id]!.code) {
      if (op is exceptions.EnterTry || op is async_ir.BeginAsync) return;
      hasIndex |= op is objects.InvokeDynamic && op.name == '[]';
      if (op.writesTo case final target?) {
        definitions.putIfAbsent(target, () => []).add((id, op));
      }
    }
  }
  if (!hasIndex) return;
  final dominators = graph.dominators;
  bool dominates(int header, int block) {
    while (block != header) {
      final parent = dominators[block];
      if (parent == null || parent == block) return false;
      block = parent;
    }
    return true;
  }

  final loops = <int, Set<int>>{};
  for (final tail in graph.graph.vertices) {
    for (final header in graph.graph.successorsOf(tail)) {
      if (!dominates(header, tail)) continue;
      final blocks = loops.putIfAbsent(header, () => {header});
      final pending = [tail];
      while (pending.isNotEmpty) {
        final id = pending.removeLast();
        if (blocks.add(id)) pending.addAll(graph.graph.predecessorsOf(id));
      }
    }
  }
  final ordered = loops.entries.toList()
    ..sort((a, b) => a.value.length.compareTo(b.value.length));
  final changed = <int>{};
  for (final loop in ordered) {
    final blocks = loop.value;
    if (blocks.any(changed.contains) ||
        blocks.fold<int>(0, (n, id) => n + graph[id]!.code.length) > 96) {
      continue;
    }
    final entries = graph.graph
        .predecessorsOf(loop.key)
        .where((id) => !blocks.contains(id))
        .toList();
    if (entries.length != 1 ||
        graph.graph.successorsOf(entries.single).length != 1 ||
        graph[loop.key]!.label == null) {
      continue;
    }
    final entryCode = graph[entries.single]!.code;
    if (entryCode.isNotEmpty &&
        (entryCode.last is flow.JumpIfFalse ||
            entryCode.last is flow.JumpIfNull ||
            entryCode.last is flow.JumpIfNonNull)) {
      continue;
    }
    cfg.SSA? invariantReceiver(cfg.SSA value) {
      final seen = <cfg.SSA>{};
      while (seen.add(value)) {
        final writes = definitions[value] ?? const [];
        if (writes.every((entry) => !blocks.contains(entry.$1))) return value;
        if (writes.length != 1 || writes.single.$2 is! cfg.Assign) return null;
        value = (writes.single.$2 as cfg.Assign).source;
      }
      return null;
    }

    final reads = <objects.InvokeDynamic, (cfg.SSA, primitives.BoxInt)>{};
    for (final id in blocks) {
      final boxedIndices = <cfg.SSA, primitives.BoxInt>{};
      for (final op in graph[id]!.code) {
        if (op is objects.InvokeDynamic &&
            op.name == '[]' &&
            op.positionalCount == 1 &&
            op.args.length == 1 &&
            op.namedNames.isEmpty &&
            op.typeArguments.isEmpty) {
          final index = boxedIndices[op.args.single];
          final receiver = invariantReceiver(op.object);
          if (index != null && receiver != null) reads[op] = (receiver, index);
        }
        if (op.writesTo case final target?) {
          boxedIndices.remove(target);
          if (op is primitives.BoxInt) boxedIndices[target] = op;
        }
      }
    }
    final receivers = reads.values.map((read) => read.$1).toSet();
    if (reads.isEmpty || receivers.length > 3) continue;
    final lengths = <objects.LoadPropertyDynamic, cfg.SSA>{};
    for (final id in blocks) {
      for (final op in graph[id]!.code) {
        if (op is objects.LoadPropertyDynamic && op.name == 'length') {
          final receiver = invariantReceiver(op.object);
          if (receiver != null && receivers.contains(receiver)) {
            lengths[op] = receiver;
          }
        }
      }
    }
    if (lengths.isEmpty) continue;
    _versionLoop(
      graph,
      loop.key,
      blocks,
      entries.single,
      reads,
      receivers,
      lengths,
    );
    changed.addAll(blocks);
  }
}

void _versionLoop(
  cfg.ControlFlowGraph graph,
  int header,
  Set<int> blocks,
  int preheader,
  Map<objects.InvokeDynamic, (cfg.SSA, primitives.BoxInt)> reads,
  Set<cfg.SSA> receivers,
  Map<objects.LoadPropertyDynamic, cfg.SSA> lengths,
) {
  final prefix = '#indexed_${graph.lastBlockId}';
  final copies = {
    for (final id in blocks)
      id: cfg.BasicBlock<cfg.Operation>([], label: '${prefix}_$id'),
  };
  final labels = {
    for (final id in blocks)
      if (graph[id]!.label case final label?) label: copies[id]!.label!,
  };
  final indices = {
    for (final box in reads.values.map((read) => read.$2).toSet())
      box: cfg.SSA('${prefix}_index_${box.target.name}'),
  };
  cfg.Operation copy(cfg.Operation op) => switch (op) {
    flow.Jump(:final target) => flow.Jump(labels[target] ?? target),
    flow.JumpIfFalse(:final condition, :final target) => flow.JumpIfFalse(
      condition,
      labels[target] ?? target,
    ),
    flow.JumpIfNull(:final condition, :final target) => flow.JumpIfNull(
      condition,
      labels[target] ?? target,
    ),
    flow.JumpIfNonNull(:final condition, :final target) => flow.JumpIfNonNull(
      condition,
      labels[target] ?? target,
    ),
    _ => op.copyWith(),
  };
  for (final id in blocks) {
    final code = copies[id]!.code;
    for (final op in graph[id]!.code) {
      if (lengths[op] case final receiver?) {
        final length = cfg.SSA('${prefix}_length_${op.writesTo!.name}');
        code.add(collection.ListLength(length, receiver));
        code.add(primitives.BoxInt(op.writesTo!, length));
        continue;
      }
      if (indices[op] case final index?) {
        code.add(cfg.Assign(index, (op as primitives.BoxInt).source));
      }
      final read = reads[op];
      code.add(
        read == null
            ? copy(op)
            : collection.IndexList(op.writesTo!, read.$1, indices[read.$2]!),
      );
    }
    graph.append(copies[id]!);
  }
  for (final id in blocks) {
    for (final next in graph.graph.successorsOf(id).toList()) {
      graph.link(copies[id]!, copies[next] ?? graph[next]!);
    }
  }
  cfg.BasicBlock<cfg.Operation>? firstGuard, lastGuard;
  var guardIndex = 0;
  for (final receiver in receivers) {
    final guard = cfg.BasicBlock<cfg.Operation>(
      [],
      label: '${prefix}_guard_${guardIndex++}',
    );
    final check = cfg.SSA('${prefix}_check_${receiver.name}');
    guard.code.add(collection.IsCanonicalList(check, receiver));
    guard.code.add(flow.JumpIfFalse(check, graph[header]!.label!));
    graph.link(guard, graph[header]!);
    if (lastGuard != null) graph.link(lastGuard, guard);
    firstGuard ??= guard;
    lastGuard = guard;
  }
  final nativeEntry = cfg.BasicBlock<cfg.Operation>([
    flow.Jump(copies[header]!.label!),
  ], label: '${prefix}_entry');
  graph.link(lastGuard!, nativeEntry);
  graph.link(nativeEntry, copies[header]!);
  final entryCode = graph[preheader]!.code;
  if (entryCode.isNotEmpty && entryCode.last is flow.Jump) {
    entryCode.removeLast();
  }
  entryCode.add(flow.Jump(firstGuard!.label!));
  graph.graph.removeEdge(preheader, header);
  graph.link(graph[preheader]!, firstGuard);
}
