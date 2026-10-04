import 'package:control_flow_graph/control_flow_graph.dart' as cfg;
import '../../ir/alu.dart' as alu;
import '../../ir/collection.dart' as collection;
import '../../ir/exception.dart' as exceptions;
import '../../ir/memory.dart' as memory;
import '../../ir/objects.dart' as objects;
import '../../ir/primitives.dart' as primitives;
import '../../ir/representation.dart';
import '../../ir/string.dart';
import 'loop_invariants.dart';
import 'native_list_read_reuse.dart';

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
void optimizePrimitives(
  cfg.ControlFlowGraph graph, {
  int? filledListConstructorId,
}) {
  Iterable<cfg.Operation> operations() sync* {
    for (final id in graph.graph.vertices) {
      yield* graph[id]!.code;
    }
  }

  final nativeLists = inferNativeListValues(operations());
  var next = 0;
  if (nativeLists.isNotEmpty) {
    for (final id in graph.graph.vertices) {
      final code = graph[id]!.code;
      List<cfg.Operation>? rewritten;
      for (var i = 0; i < code.length; i++) {
        final op = code[i];
        if (op is objects.LoadPropertyDynamic &&
            op.name == 'length' &&
            nativeLists.contains(op.object)) {
          rewritten ??= code.sublist(0, i);
          final length = cfg.SSA('optimized:listLength${next++}', version: 0);
          rewritten.add(collection.ListLength(length, op.object));
          rewritten.add(primitives.BoxInt(op.target, length));
        } else {
          rewritten?.add(op);
        }
      }
      if (rewritten != null) {
        code
          ..clear()
          ..addAll(rewritten);
      }
    }
  }
  final definitions = cfg.SSADefinitions(graph);
  cfg.Operation? definition(cfg.SSA value) => definitions.throughCopies(value);

  for (final id in graph.graph.vertices) {
    final code = graph[id]!.code;
    for (var i = 0; i < code.length; i++) {
      final op = code[i];
      if (op is primitives.Unbox) {
        final primitive = _primitiveBox(definition(op.source));
        if (primitive != null &&
            primitive.representation == op.representation) {
          code[i] = cfg.Assign(op.target, primitive.source);
        }
      } else if (op is objects.SetPropertyStatic &&
          !op.isLateFinal &&
          op.rep == MachineRepresentation.object) {
        final primitive = _primitiveBox(definition(op.value));
        if (primitive != null &&
            primitive.representation != MachineRepresentation.string) {
          code[i] = objects.SetPropertyStatic(
            op.object,
            op.index,
            primitive.source,
            fieldName: op.fieldName,
            isLateInitialization: op.isLateInitialization,
            rep: primitive.representation,
          );
        }
      } else if (op is alu.IntAdd) {
        final left = definition(op.left), right = definition(op.right);
        if (right is memory.LoadInt && right.value == 1) {
          code[i] = alu.Increment(op.writesTo!, op.left);
        } else if (left is memory.LoadInt && left.value == 1) {
          code[i] = alu.Increment(op.writesTo!, op.right);
        }
      } else if (op is objects.InvokeDynamic &&
          op.name == '[]' &&
          op.args.length == 1 &&
          op.positionalCount == 1 &&
          op.namedNames.isEmpty &&
          op.typeArguments.isEmpty) {
        final box = definition(op.args.single);
        if (box is primitives.BoxInt) {
          code[i] = op.withUnboxedIndex(box.source);
        }
      }
    }
  }
  reuseFreshNativeListReads(
    graph,
    filledListConstructorId: filledListConstructorId,
  );
  _reuseNativeFieldReads(graph, definitions);
  _fuseStringConcatenations(graph);
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
      // Dead-code removal immediately rebuilds SSA metadata after this pass.
      refresh: false,
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
  hoistLoopInvariants(graph);
}

/// Combines a single-consumer concatenation pair without moving its operands'
/// evaluations or conversions. Calls and unknown operations end a candidate's
/// lifetime, and a fused triple cannot become another pair's first operation.
void _fuseStringConcatenations(cfg.ControlFlowGraph graph) {
  final hasPair = graph.graph.vertices.any((id) {
    var count = 0;
    for (final op in graph[id]!.code) {
      if (op is StringOperation &&
          op.operator == StringOperator.concatenate &&
          ++count == 2) {
        return true;
      }
    }
    return false;
  });
  if (!hasPair) return;
  final consumers = <cfg.SSA, int>{};
  for (final id in graph.graph.vertices) {
    for (final op in graph[id]!.code) {
      for (final input in op.readsFrom) {
        consumers.update(input, (count) => count + 1, ifAbsent: () => 1);
      }
    }
  }
  for (final id in graph.graph.vertices) {
    final code = graph[id]!.code;
    final candidates = <cfg.SSA, (int, StringOperation)>{};
    final removed = <int>{};
    for (var i = 0; i < code.length; i++) {
      final op = code[i];
      if (op is StringOperation &&
          op.operator == StringOperator.concatenate &&
          op.argument != null) {
        final previous = candidates.remove(op.string);
        if (previous != null &&
            consumers[op.string] == 1 &&
            op.argument != op.string) {
          final (index, first) = previous;
          code[i] = StringConcat3(
            op.target,
            first.string,
            first.argument!,
            op.argument!,
          );
          removed.add(index);
        } else {
          candidates[op.target] = (i, op);
        }
      } else if (!_preservesNativeFieldReads(op)) {
        candidates.clear();
      }
    }
    if (removed.isNotEmpty) {
      final rewritten = [
        for (var i = 0; i < code.length; i++)
          if (!removed.contains(i)) code[i],
      ];
      code
        ..clear()
        ..addAll(rewritten);
    }
  }
}

/// Reuses a numeric or bool slot read while no intervening operation can mutate
/// guest state. Reads stay at their original positions and never cross blocks.
void _reuseNativeFieldReads(
  cfg.ControlFlowGraph graph,
  cfg.SSADefinitions definitions,
) {
  cfg.SSA receiver(cfg.SSA value) =>
      definitions.throughCopies(value)?.writesTo ?? value;
  for (final id in graph.graph.vertices) {
    final code = graph[id]!.code;
    final reads = <(cfg.SSA, int, MachineRepresentation), cfg.SSA>{};
    for (var i = 0; i < code.length; i++) {
      final op = code[i];
      if (op is objects.LoadPropertyStatic &&
          !op.isLate &&
          (op.rep == MachineRepresentation.integer ||
              op.rep == MachineRepresentation.doublePrecision ||
              op.rep == MachineRepresentation.boolean)) {
        final key = (receiver(op.object), op.index, op.rep);
        final previous = reads[key];
        if (previous == null) {
          reads[key] = op.target;
        } else {
          code[i] = cfg.Assign(op.target, previous);
        }
      } else if (reads.isNotEmpty && !_preservesNativeFieldReads(op)) {
        reads.clear();
      }
    }
  }
}

bool _preservesNativeFieldReads(cfg.Operation op) => switch (op) {
  primitives.BoxInt() ||
  primitives.BoxDouble() ||
  primitives.BoxBool() ||
  primitives.BoxString() ||
  primitives.BoxNull() ||
  StringOperation() ||
  StringSubstring() ||
  StringConcat3() ||
  PrimitiveToString() => true,
  _ => isNonThrowingPrimitive(op),
};

({cfg.SSA source, MachineRepresentation representation})? _primitiveBox(
  cfg.Operation? operation,
) => switch (operation) {
  primitives.BoxInt(:final source) => (
    source: source,
    representation: MachineRepresentation.integer,
  ),
  primitives.BoxDouble(:final source) => (
    source: source,
    representation: MachineRepresentation.doublePrecision,
  ),
  primitives.BoxBool(:final source) => (
    source: source,
    representation: MachineRepresentation.boolean,
  ),
  primitives.BoxString(:final source) => (
    source: source,
    representation: MachineRepresentation.string,
  ),
  _ => null,
};
