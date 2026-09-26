import '../../ir/string.dart';
import 'package:control_flow_graph/control_flow_graph.dart' as cfg;
import '../invocation/deferred.dart';
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
  if (type.nullable || !type.isDartCore) {
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

/// The register bank an operation's result lands in — the output side of the
/// rules [analyzeRepresentations] applies. A [Variable] created at emission
/// uses this to name its slot's bank instead of guessing from its type.
/// Returns null for ops whose bank is context-decided (parameters, calls and
/// globals via signatures, `Assign`/`Negate`/phi inheriting the source's
/// bank) and for ops that write no value.
MachineRepresentation? outputBankOf(cfg.Operation operation) =>
    switch (operation) {
      exceptions.LoadExceptionSlot(:final slot) => slot.representation,
      StringOperation(:final operator) =>
        operator == StringOperator.length ||
                operator == StringOperator.codeUnitAt
            ? MachineRepresentation.integer
            : MachineRepresentation.string,
      StringSubstring() => MachineRepresentation.string,
      NumericBinary(:final resultRepresentation) => resultRepresentation,
      IntToDouble() => MachineRepresentation.doublePrecision,
      memory.LoadInt() ||
      collection.IterableLength() ||
      collection.ListLength() ||
      types.ResolveTypeId() => MachineRepresentation.integer,
      memory.LoadDouble() => MachineRepresentation.doublePrecision,
      alu.IntAdd() ||
      alu.IntSub() ||
      alu.Increment() => MachineRepresentation.integer,
      memory.LoadBool() ||
      alu.IntEqual() ||
      alu.IntNotEqual() ||
      alu.IntLessThan() ||
      alu.IntLessThanOrEqual() ||
      alu.IntGreaterThan() ||
      alu.IntGreaterThanOrEqual() ||
      alu.LessThan() ||
      logic.LogicalNot() ||
      logic.LogicalAnd() ||
      logic.LogicalOr() ||
      memory.IsNull() ||
      objects.DynamicEquals() ||
      collection.IsNativeList() ||
      collection.IsNativeSet() ||
      collection.IsNativeMap() ||
      types.IsType() => MachineRepresentation.boolean,
      memory.LoadString() => MachineRepresentation.string,
      primitives.Unbox(:final representation) => representation,
      closures.ReadCaptureCell(:final representation) => representation,
      primitives.BoxInt() ||
      primitives.BoxDouble() ||
      primitives.BoxBool() ||
      primitives.BoxString() ||
      primitives.BoxNum() ||
      primitives.MaybeBoxNull() ||
      primitives.BoxList() ||
      primitives.BoxMap() ||
      primitives.BoxSet() ||
      primitives.BoxNull() ||
      memory.LoadNull() ||
      objects.LoadUninitializedField() ||
      objects.InvokeDynamic() ||
      objects.LoadPropertyDynamic() ||
      objects.LoadSuper() ||
      objects.LoadThis() ||
      objects.InternConst() ||
      objects.CreateClass() ||
      bridge.InvokeExternal() ||
      bridge.PrepareBridgeArgument() ||
      bridge.BridgeInstantiate() ||
      bridge.NewBridgeSuperShim() ||
      closures.InvokeClosure() ||
      closures.CreateClosure() ||
      closures.NewCaptureCell() ||
      closures.LoadCapture() ||
      exceptions.CaughtException() ||
      exceptions.CaughtStackTrace() ||
      async.BeginAsync() ||
      async.Await() ||
      functions_ir.LoadFunctionPointer() ||
      collection.NewList() ||
      collection.NewMap() ||
      collection.NewSet() ||
      collection.IndexList() ||
      collection.IndexMap() ||
      collection.SetToList() ||
      collection.MapKeys() ||
      collection.NewRecord() ||
      types.LoadConstantType() ||
      types.LoadTypeParameter() ||
      types.LoadRuntimeType() => MachineRepresentation.object,
      objects.LoadPropertyStatic(:final rep) => rep,
      collection.SetAdd(:final target) =>
        target == null ? null : MachineRepresentation.boolean,
      _ => null,
    };

/// Computes the physical representation of each SSA version without changing
/// the graph. Assignments and phi inputs must agree; conversions stay explicit.
Map<cfg.SSA, MachineRepresentation> analyzeRepresentations(
  cfg.ControlFlowGraph graph, {
  Map<cfg.SSA, MachineRepresentation> hints = const {},
  Map<int, MachineFunctionSignature> functions = const {},
  Map<int, MachineRepresentation> globalRepresentations = const {},
  int? functionId,
  int Function(DeferredOrOffset target)? resolveFunction,
}) {
  if (!graph.inSSAForm) {
    throw StateError('Representation analysis requires SSA form');
  }
  final constraints = cfg.SSAValueConstraints<MachineRepresentation>();
  final operations = <cfg.Operation>[
    for (final id in graph.graph.vertices) ...graph[id]!.code,
  ];
  void constrain(cfg.SSA value, MachineRepresentation representation) {
    constraints.constrain(value, representation);
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
      case exceptions.LoadExceptionSlot(:final slot):
        output(operation, slot.representation);
      case exceptions.StoreExceptionSlot(:final slot):
        inputs(operation, slot.representation);
      case StringOperation(:final string, :final argument, :final operator):
        constrain(string, MachineRepresentation.string);
        if (argument != null) {
          constrain(
            argument,
            operator == StringOperator.concatenate
                ? MachineRepresentation.string
                : integer,
          );
        }
        output(
          operation,
          operator == StringOperator.length ||
                  operator == StringOperator.codeUnitAt
              ? integer
              : MachineRepresentation.string,
        );
      case StringSubstring(:final string, :final start, :final end):
        constrain(string, MachineRepresentation.string);
        constrain(start, integer);
        constrain(end, integer);
        output(operation, MachineRepresentation.string);
      case NumericBinary(
        :final operandRepresentation,
        :final resultRepresentation,
      ):
        inputs(operation, operandRepresentation);
        output(operation, resultRepresentation);
      case IntToDouble():
        inputs(operation, integer);
        output(operation, floating);
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
      case cfg.Assign(:final target, :final source):
        constraints.equate([target, source]);
      case cfg.PhiNode(:final target, :final sources):
        constraints.equate([target, ...sources]);
      case alu.Negate(:final target, :final source):
        // `-x` keeps the operand's representation — int or double.
        constraints.equate([target, source]);
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
        constraints.equate([left, right]);
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
      case primitives.Unbox(:final source, :final representation):
        constrain(source, object);
        output(operation, representation);
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
      case objects.DynamicEquals() ||
          types.IsType() ||
          collection.IsNativeList() ||
          collection.IsNativeSet() ||
          collection.IsNativeMap():
        inputs(operation, object);
        output(operation, boolean);
      case collection.IterableLength() || collection.ListLength():
        inputs(operation, object);
        output(operation, integer);
      case types.ResolveTypeId():
        output(operation, integer);
      case types.SetTypeEnvironment():
        inputs(operation, integer);
      case objects.InvokeDynamic() ||
          bridge.InvokeExternal() ||
          closures.InvokeClosure():
        inputs(operation, object);
        output(operation, object);
      case memory.LoadNull() ||
          objects.LoadUninitializedField() ||
          primitives.BoxNull() ||
          collection.NewList() ||
          collection.NewMap() ||
          collection.NewSet() ||
          bridge.NewBridgeSuperShim() ||
          functions_ir.LoadFunctionPointer() ||
          closures.LoadCapture() ||
          exceptions.CaughtException() ||
          exceptions.CaughtStackTrace() ||
          async.BeginAsync() ||
          types.LoadConstantType() ||
          types.LoadTypeParameter():
        output(operation, object);
      case primitives.MaybeBoxNull() ||
          bridge.PrepareBridgeArgument() ||
          objects.InternConst():
        inputs(operation, object);
        output(operation, object);
      case primitives.BoxList() ||
          primitives.BoxMap() ||
          primitives.BoxSet() ||
          objects.LoadPropertyDynamic() ||
          objects.LoadSuper() ||
          objects.LoadThis() ||
          collection.SetToList() ||
          collection.MapKeys() ||
          types.LoadRuntimeType() ||
          bridge.BridgeInstantiate() ||
          async.Await():
        inputs(operation, object);
        output(operation, object);
      case objects.LoadPropertyStatic(:final object, :final rep):
        constrain(object, MachineRepresentation.object);
        output(operation, rep);
      case objects.CreateClass(:final $super, :final runtimeTypeDescriptor):
        constrain($super, object);
        constrain(runtimeTypeDescriptor, integer);
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
          exceptions.CompleteJump() ||
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
          objects.SetPropertyDynamic() ||
          objects.BufferWrite() ||
          collection.MapSet() ||
          collection.ListAppend() ||
          bridge.ParentBridgeSuperShim():
        inputs(operation, object);
      case collection.SetAdd(:final target):
        inputs(operation, object);
        if (target != null) output(operation, boolean);
      case objects.SetPropertyStatic(:final object, :final value, :final rep):
        constrain(object, MachineRepresentation.object);
        constrain(value, rep);
      case collection.ListSet(:final list, :final index, :final value):
        constrain(list, object);
        constrain(index, integer);
        constrain(value, object);
      case globals.LoadGlobal(:final index):
        output(operation, globalRepresentations[index] ?? object);
      case globals.SetGlobal(:final index):
        inputs(operation, globalRepresentations[index] ?? object);
      default:
        throw UnsupportedError(
          'No representation rule for ${operation.runtimeType}',
        );
    }
  }

  final result = constraints.solve();
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
