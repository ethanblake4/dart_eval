import 'package:control_flow_graph/control_flow_graph.dart' as cfg;

import '../../ir/alu.dart' as alu;
import '../../ir/exception.dart' as exceptions;
import '../../ir/flow.dart' as flow;
import '../../ir/logic.dart' as logic;
import '../../ir/memory.dart' as memory;
import '../../ir/numeric.dart';

/// Moves non-throwing primitive computations to existing loop preheaders.
/// Mutable reads, allocations and conversions from boxed values stay in place.
void hoistLoopInvariants(cfg.ControlFlowGraph graph) {
  final locations = <cfg.SSA, int>{};
  for (final id in graph.graph.vertices) {
    for (final op in graph[id]!.code) {
      if (op is exceptions.EnterTry) return;
      if (op.writesTo case final target?) locations[target] = id;
    }
  }
  final tree = graph.dominatorTree;
  var next = 0;
  final before = <int, int>{}, after = <int, int>{};
  final pending = [(graph.root.id!, false)];
  while (pending.isNotEmpty) {
    final (id, returning) = pending.removeLast();
    if (returning) {
      after[id] = next++;
    } else {
      before[id] = next++;
      pending.add((id, true));
      for (final child in tree.successorsOf(id)) {
        if (child != id) pending.add((child, false));
      }
    }
  }
  bool dominates(int ancestor, int block) =>
      before[ancestor]! <= before[block]! && after[ancestor]! >= after[block]!;

  final loops = <int, Set<int>>{};
  for (final tail in graph.graph.vertices) {
    for (final header in graph.graph.successorsOf(tail)) {
      if (!dominates(header, tail)) continue;
      final blocks = loops.putIfAbsent(header, () => {header});
      final pending = [tail];
      while (pending.isNotEmpty) {
        final block = pending.removeLast();
        if (!blocks.add(block)) continue;
        pending.addAll(graph.graph.predecessorsOf(block));
      }
    }
  }
  final ordered = loops.entries.toList()
    ..sort((a, b) => a.value.length.compareTo(b.value.length));
  var changed = false;
  for (final loop in ordered) {
    final entries = graph.graph
        .predecessorsOf(loop.key)
        .where((id) => !loop.value.contains(id))
        .toList();
    if (entries.length != 1) continue;
    final preheader = entries.single;
    if (graph.graph.successorsOf(preheader).length != 1) continue;
    final entryCode = graph[preheader]!.code;
    final hasJump = entryCode.isNotEmpty && entryCode.last is flow.Jump;
    if (entryCode.isNotEmpty &&
        (entryCode.last is flow.JumpIfFalse ||
            entryCode.last is flow.JumpIfNull ||
            entryCode.last is flow.JumpIfNonNull)) {
      continue;
    }
    final hoisted = <cfg.Operation>[];
    var progress = true;
    while (progress) {
      progress = false;
      for (final id in loop.value) {
        final code = graph[id]!.code;
        for (var i = 0; i < code.length; i++) {
          final op = code[i];
          if (!_canHoist(op) ||
              !op.readsFrom.every((input) {
                final definition = locations[input];
                return definition != null &&
                    !loop.value.contains(definition) &&
                    dominates(definition, preheader);
              })) {
            continue;
          }
          hoisted.add(op);
          locations[op.writesTo!] = preheader;
          code.removeAt(i--);
          progress = changed = true;
        }
      }
    }
    if (hoisted.isNotEmpty) {
      // A preheader can fall through or jump explicitly into the loop.
      entryCode.insertAll(entryCode.length - (hasJump ? 1 : 0), hoisted);
    }
  }
  if (changed) graph.refreshSSA();
}

bool _canHoist(cfg.Operation op) => switch (op) {
  cfg.Assign() ||
  memory.LoadInt() ||
  memory.LoadDouble() ||
  memory.LoadBool() ||
  memory.LoadString() ||
  memory.LoadNull() ||
  memory.IsNull() ||
  alu.IntAdd() ||
  alu.IntSub() ||
  alu.Increment() ||
  alu.IntLessThan() ||
  alu.IntLessThanOrEqual() ||
  alu.IntGreaterThan() ||
  alu.IntGreaterThanOrEqual() ||
  alu.IntEqual() ||
  alu.IntNotEqual() ||
  alu.Negate() ||
  logic.LogicalNot() ||
  logic.LogicalAnd() ||
  logic.LogicalOr() ||
  IntToDouble() => true,
  NumericBinary() => op.isPure,
  _ => false,
};
