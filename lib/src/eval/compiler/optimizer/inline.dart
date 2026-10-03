import 'package:control_flow_graph/control_flow_graph.dart' as cfg;

import '../../ir/alu.dart' as alu;
import '../../ir/exception.dart' as exceptions;
import '../../ir/flow.dart' as flow;
import '../../ir/function.dart' as functions;
import '../../ir/logic.dart' as logic;
import '../../ir/memory.dart' as memory;
import '../../ir/numeric.dart';
import '../../ir/objects.dart' as objects;
import '../../ir/primitives.dart' as primitives;
import '../../ir/string.dart';
import '../context.dart';

/// Expands short leaf bodies before SSA construction. Argument binding and
/// representation conversions have already happened at the original call site.
void inlineLeafCalls(CompilerContext context) {
  const maxBodyOperations = 12;
  final candidates = <int, List<cfg.Operation>>{};
  for (final entry in context.functionGraphs.entries) {
    final graph = entry.value;
    final signature = context.functionSignatures[entry.key];
    // The frontend can put an empty entry block before the executable body.
    final blocks = [
      for (final id in graph.graph.vertices)
        if (graph[id]!.code.isNotEmpty) graph[id]!,
    ];
    if (blocks.length != 1 ||
        graph.graph.vertices.any(
          (id) => graph.graph.successorsOf(id).length > 1,
        ) ||
        graph.graph.successorsOf(blocks.single.id!).isNotEmpty ||
        signature == null ||
        signature.result == null ||
        (context.functionTypeParameters[entry.key]?.isNotEmpty ?? false)) {
      continue;
    }
    final code = blocks.single.code;
    if (code.isEmpty || code.last is! flow.Return) continue;
    final returned = code.last as flow.Return;
    if (returned.value == null) continue;
    final defined = <cfg.SSA>{};
    var parameters = 0;
    var bodyOperations = 0;
    var valid = true;
    for (final op in code.take(code.length - 1)) {
      if (op is functions.Parameter) {
        if (bodyOperations != 0 ||
            op.index != parameters ||
            parameters >= signature.parameters.length ||
            op.representation != signature.parameters[parameters]) {
          valid = false;
          break;
        }
        parameters++;
      } else if (!_canInline(op) ||
          ++bodyOperations > maxBodyOperations ||
          !op.readsFrom.every(defined.contains)) {
        valid = false;
        break;
      }
      final target = op.writesTo;
      if (target != null) defined.add(target);
    }
    if (valid &&
        parameters == signature.parameters.length &&
        defined.contains(returned.value)) {
      // Freeze the original leaf body so rewriting another function cannot
      // expand our candidates or make the result depend on traversal order.
      candidates[entry.key] = List.of(code);
    }
  }

  var nextCall = 0;
  for (final entry in context.functionGraphs.entries) {
    final graph = entry.value;
    // Catch edges can leave a block before all its definitions have executed.
    if (graph.graph.vertices.any(
      (id) => graph[id]!.code.any((op) => op is exceptions.EnterTry),
    )) {
      continue;
    }
    final names = <String>{
      for (final id in graph.graph.vertices)
        for (final op in graph[id]!.code) ...[
          if (op.writesTo != null) op.writesTo!.name,
          for (final input in op.readsFrom) input.name,
        ],
    };
    for (final id in graph.graph.vertices) {
      final code = graph[id]!.code;
      final rewritten = <cfg.Operation>[];
      for (final op in code) {
        if (op is! flow.Call ||
            op.typeArguments.isNotEmpty ||
            op.typeEnvironmentReceiver != null) {
          rewritten.add(op);
          continue;
        }
        final callee = op.target.resolveFunctionId(context);
        final body = candidates[callee];
        if (callee == entry.key ||
            body == null ||
            op.arguments.length !=
                context.functionSignatures[callee]!.parameters.length) {
          rewritten.add(op);
          continue;
        }
        final prefix = 'inline${nextCall++}';
        final locals = <cfg.SSA, cfg.SSA>{};
        cfg.SSA local(cfg.SSA value) => locals.putIfAbsent(value, () {
          var name = '$prefix:${value.name}';
          while (!names.add(name)) {
            name = '$name:';
          }
          return cfg.SSA(name, type: value.type);
        });
        for (final instruction in body) {
          if (instruction is functions.Parameter) {
            // Parameters are writable locals. Copying them prevents callee
            // assignments from changing a caller local passed as an argument.
            rewritten.add(
              cfg.Assign(
                local(instruction.target),
                op.arguments[instruction.index],
              ),
            );
          } else if (instruction is flow.Return) {
            if (op.result != null) {
              rewritten.add(cfg.Assign(op.result!, local(instruction.value!)));
            }
          } else {
            rewritten.add(
              instruction.copyWith(
                writesTo: instruction.writesTo == null
                    ? null
                    : local(instruction.writesTo!),
                readsFrom: {
                  for (final input in instruction.readsFrom) local(input),
                },
              ),
            );
          }
        }
      }
      code
        ..clear()
        ..addAll(rewritten);
    }
    graph.invalidate();
  }
}

// An explicit allowlist keeps frame-dependent operations, calls, allocations,
// and runtime type environments out of this deliberately small transformation.
bool _canInline(cfg.Operation op) => switch (op) {
  cfg.Assign() ||
  memory.LoadInt() ||
  memory.LoadDouble() ||
  memory.LoadString() ||
  memory.LoadBool() ||
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
  NumericBinary() ||
  IntToDouble() ||
  logic.LogicalNot() ||
  logic.LogicalAnd() ||
  logic.LogicalOr() ||
  primitives.BoxInt() ||
  primitives.BoxDouble() ||
  primitives.BoxBool() ||
  primitives.BoxString() ||
  primitives.BoxNull() ||
  primitives.Unbox() ||
  objects.LoadPropertyStatic() ||
  objects.SetPropertyStatic() ||
  StringOperation() ||
  StringSubstring() => true,
  _ => false,
};
