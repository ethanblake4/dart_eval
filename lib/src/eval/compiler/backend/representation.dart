import '../../ir/string.dart';
import 'package:control_flow_graph/control_flow_graph.dart' as cfg;
import '../offset_tracker.dart';
import '../builtins.dart' show dartCoreFile;
import '../type.dart';
import '../../ir/alu.dart' as alu;
import '../../ir/async.dart' as async;
import '../../ir/bridge.dart' as bridge;
import '../../ir/closures.dart' as closures;
import '../../ir/collection.dart' as collection;
import '../../ir/exception.dart' as exceptions;
import '../../ir/flow.dart' as flow;
import '../../ir/function.dart' as functions_ir;
import '../../ir/globals.dart' as globals;
import '../../ir/logic.dart' as logic;
import '../../ir/memory.dart' as memory;
import '../../ir/numeric.dart';
import '../../ir/objects.dart' as objects;
import '../../ir/primitives.dart' as primitives;
import '../../ir/representation.dart';
import '../../ir/types.dart' as types;

export '../../ir/representation.dart';

MachineRepresentation representationForType(TypeRef type) {
  if (type.boxed || type.nullable || type.file != dartCoreFile) {
    return MachineRepresentation.object;
  }
  return switch (type.name) {
    'int' => MachineRepresentation.integer,
    'double' => MachineRepresentation.doublePrecision,
    'bool' => MachineRepresentation.boolean,
    'String' => MachineRepresentation.string,
    _ => MachineRepresentation.object,
  };
}

/// Computes the physical representation of each SSA version without changing
/// the graph. Assignments and phi inputs must agree; conversions stay explicit.
Map<cfg.SSA, MachineRepresentation> analyzeRepresentations(
  cfg.ControlFlowGraph graph, {
  Map<cfg.SSA, MachineRepresentation> hints = const {},
  Map<int, MachineFunctionSignature> functions = const {},
  int? functionId,
  int Function(DeferredOrOffset target)? resolveFunction,
}) {
  if (!graph.inSSAForm) {
    throw StateError('Representation analysis requires SSA form');
  }
  final result = <cfg.SSA, MachineRepresentation>{};
  final equalities = <List<cfg.SSA>>[];
  final operations = <cfg.Operation>[
    for (final id in graph.graph.vertices) ...graph[id]!.code,
  ];
  final definitions = {
    for (final operation in operations)
      if (operation.writesTo != null) operation.writesTo!: operation,
  };

  void constrain(cfg.SSA value, MachineRepresentation representation) {
    final previous = result[value];
    if (previous != null && previous != representation) {
      throw StateError(
        'Incompatible representations for $value: '
        '${previous.name} and ${representation.name}; an explicit conversion is required',
      );
    }
    result[value] = representation;
  }

  void output(cfg.Operation operation, MachineRepresentation representation) {
    final target = operation.writesTo;
    if (target != null && target != cfg.ControlFlowGraph.branch) {
      constrain(target, representation);
    }
  }

  void inputs(cfg.Operation operation, MachineRepresentation representation) {
    for (final input in operation.readsFrom) {
      constrain(input, representation);
    }
  }

  const integer = MachineRepresentation.integer;
  const floating = MachineRepresentation.doublePrecision;
  const boolean = MachineRepresentation.boolean;
  const string = MachineRepresentation.string;
  const object = MachineRepresentation.object;
  hints.forEach(constrain);
  for (final operation in operations) {
    switch (operation) {
      case StringOperation(:final string, :final argument, :final operator):
        constrain(string, MachineRepresentation.string);
        if (argument != null)
          constrain(
            argument,
            operator == StringOperator.concatenate
                ? MachineRepresentation.string
                : integer,
          );
        output(
          operation,
          operator == StringOperator.length ||
                  operator == StringOperator.codeUnitAt
              ? integer
              : MachineRepresentation.string,
        );
      case NumericBinary(
        :final operandRepresentation,
        :final resultRepresentation,
      ):
        inputs(operation, operandRepresentation);
        output(operation, resultRepresentation);
      case memory.LoadInt():
        output(operation, integer);
      case memory.LoadDouble():
        output(operation, floating);
      case memory.LoadBool():
        output(operation, boolean);
      case memory.LoadString():
        output(operation, string);
      case functions_ir.Parameter(:final index, :final representation):
        final signature = functions[functionId];
        if (signature != null && index >= signature.parameters.length) {
          throw StateError(
            'Parameter $index is outside function $functionId signature',
          );
        }
        output(operation, signature?.parameters[index] ?? representation);
      case memory.Assign(:final target, :final source):
        equalities.add([target, source]);
      case cfg.Assign(:final target, :final source):
        equalities.add([target, source]);
      case cfg.PhiNode(:final target, :final sources):
        equalities.add([target, ...sources]);
      case alu.IntAdd() || alu.IntSub() || alu.Increment():
        inputs(operation, integer);
        output(operation, integer);
      case alu.IntEqual() ||
          alu.IntNotEqual() ||
          alu.IntLessThan() ||
          alu.IntLessThanOrEqual() ||
          alu.IntGreaterThan() ||
          alu.IntGreaterThanOrEqual():
        inputs(operation, integer);
        output(operation, boolean);
      case alu.LessThan(:final left, :final right):
        equalities.add([left, right]);
        output(operation, boolean);
      case logic.LogicalNot() || logic.LogicalAnd() || logic.LogicalOr():
        inputs(operation, boolean);
        output(operation, boolean);
      case primitives.BoxInt():
        inputs(operation, integer);
        output(operation, object);
      case primitives.BoxDouble():
        inputs(operation, floating);
        output(operation, object);
      case primitives.BoxBool():
        inputs(operation, boolean);
        output(operation, object);
      case primitives.BoxString():
        inputs(operation, string);
        output(operation, object);
      case primitives.BoxNum():
        output(operation, object);
      case primitives.Unbox(:final source):
        constrain(source, object);
        final producer = definitions[source];
        final primitive = switch (producer) {
          primitives.BoxInt() => integer,
          primitives.BoxDouble() => floating,
          primitives.BoxBool() => boolean,
          primitives.BoxString() => string,
          _ => null,
        };
        if (primitive != null) output(operation, primitive);
      case flow.Call(:final target, :final arguments):
        final callee = resolveFunction?.call(target) ?? target.offset;
        final signature = functions[callee];
        if (signature == null) {
          throw StateError('Missing machine signature for call $target');
        }
        if (arguments.length != signature.parameters.length) {
          throw StateError(
            'Call $target has ${arguments.length} arguments, '
            'expected ${signature.parameters.length}',
          );
        }
        for (var index = 0; index < arguments.length; index++) {
          constrain(arguments[index], signature.parameters[index]);
        }
        output(operation, signature.result ?? object);
      case flow.Return(:final value):
        final signature = functions[functionId];
        if (signature != null && value != null) {
          if (signature.result == null) {
            throw StateError('Void function $functionId returns a value');
          }
          constrain(value, signature.result!);
        }
      case flow.JumpIfFalse(:final condition):
        constrain(condition, boolean);
      case flow.JumpIfNull(:final condition) ||
          flow.JumpIfNonNull(:final condition):
        constrain(condition, object);
      case memory.IsNull():
        output(operation, boolean);
      case objects.DynamicEquals() || types.IsType():
        inputs(operation, object);
        output(operation, boolean);
      case collection.IterableLength() || collection.ListLength():
        inputs(operation, object);
        output(operation, integer);
      case objects.InvokeDynamic() ||
          bridge.InvokeExternal() ||
          closures.InvokeClosure():
        inputs(operation, object);
        output(operation, object);
      case memory.LoadNull() ||
          primitives.BoxNull() ||
          collection.NewList() ||
          collection.NewMap() ||
          collection.NewSet() ||
          bridge.NewBridgeSuperShim() ||
          functions_ir.LoadFunctionPointer() ||
          closures.LoadCapture() ||
          exceptions.CaughtException() ||
          exceptions.CaughtStackTrace() ||
          types.LoadConstantType() ||
          globals.LoadGlobal():
        output(operation, object);
      case primitives.MaybeBoxNull() || bridge.PrepareBridgeArgument():
        inputs(operation, object);
        output(operation, object);
      case primitives.BoxList() ||
          primitives.BoxMap() ||
          primitives.BoxSet() ||
          objects.CreateClass() ||
          objects.LoadPropertyStatic() ||
          objects.LoadPropertyDynamic() ||
          objects.LoadSuper() ||
          objects.LoadThis() ||
          types.LoadRuntimeType() ||
          bridge.BridgeInstantiate() ||
          async.Await():
        inputs(operation, object);
        output(operation, object);
      case closures.CreateClosure():
        inputs(operation, object);
        output(operation, object);
      case closures.NewCaptureCell(:final value, :final representation):
        constrain(value, representation);
        output(operation, object);
      case closures.ReadCaptureCell(:final cell, :final representation):
        constrain(cell, object);
        output(operation, representation);
      case closures.WriteCaptureCell(
        :final cell,
        :final value,
        :final representation,
      ):
        constrain(cell, object);
        constrain(value, representation);
      case collection.IndexList(:final list, :final index):
        constrain(list, object);
        constrain(index, integer);
        output(operation, object);
      case collection.IndexMap():
        inputs(operation, object);
        output(operation, object);
      case collection.NewRecord():
        inputs(operation, object);
        output(operation, object);
      case flow.Jump() ||
          exceptions.EnterTry() ||
          exceptions.LeaveTry() ||
          exceptions.ResumeCompletion():
        break;
      case flow.Assert(:final condition, :final errorMessage):
        constrain(condition, boolean);
        constrain(errorMessage, object);
      case flow.Throw() ||
          flow.Rethrow() ||
          flow.ReturnAsync() ||
          types.AssertType() ||
          objects.SetPropertyStatic() ||
          objects.SetPropertyDynamic() ||
          collection.MapSet() ||
          collection.ListAppend() ||
          collection.SetAdd() ||
          bridge.ParentBridgeSuperShim():
        inputs(operation, object);
      case collection.ListSet(:final list, :final index, :final value):
        constrain(list, object);
        constrain(index, integer);
        constrain(value, object);
      case globals.SetGlobal():
        break;
      default:
        throw UnsupportedError(
          'No representation rule for ${operation.runtimeType}',
        );
    }
  }

  var changed = true;
  while (changed) {
    changed = false;
    for (final equality in equalities) {
      final known = equality.map((value) => result[value]).nonNulls.toSet();
      if (known.length > 1) {
        throw StateError(
          'Assignment or phi has incompatible representations: '
          '${equality.join(', ')} (${known.map((value) => value.name).join(', ')})',
        );
      }
      if (known.isEmpty) continue;
      for (final value in equality) {
        if (!result.containsKey(value)) changed = true;
        constrain(value, known.single);
      }
    }
  }
  for (final operation in operations) {
    if (operation is primitives.BoxNum || operation is alu.LessThan) {
      for (final source in operation.readsFrom) {
        if (result[source] != integer && result[source] != floating) {
          throw StateError(
            '$operation requires a known numeric representation',
          );
        }
      }
    }
    for (final value in [
      ...operation.readsFrom,
      if (operation.writesTo != null &&
          operation.writesTo != cfg.ControlFlowGraph.branch)
        operation.writesTo!,
    ]) {
      if (!result.containsKey(value)) {
        throw StateError(
          'Cannot determine machine representation of $value in $operation',
        );
      }
    }
  }
  return Map.unmodifiable(result);
}
