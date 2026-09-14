import 'package:control_flow_graph/control_flow_graph.dart' as cfg;
import '../context.dart';
import '../offset_tracker.dart';
import '../optimizer/ssa.dart';
import '../../ir/operands.dart';
import '../../runtime/ops/register_ops.dart';
import '../../ir/alu.dart' as alu;
import '../../ir/async.dart' as async;
import '../../ir/bridge.dart' as bridge;
import '../../ir/closures.dart' as closures;
import '../../ir/collection.dart' as collection;
import '../../ir/exception.dart' as exception;
import '../../ir/flow.dart' as flow;
import '../../ir/function.dart' as function_ir;
import '../../ir/globals.dart' as globals;
import '../../ir/logic.dart' as logic;
import '../../ir/memory.dart' as memory;
import '../../ir/objects.dart' as objects;
import '../../ir/primitives.dart' as primitives;
import '../../ir/types.dart' as types;
import '../../ir/numeric.dart';
import '../../ir/representation.dart';

sealed class Relocation {
  const Relocation();
}

final class BlockAddress extends Relocation {
  final int function;
  final int block;
  const BlockAddress(this.function, this.block);
}

final class FunctionAddress extends Relocation {
  final DeferredOrOffset target;
  const FunctionAddress(this.target);
}

final class MachineOperation extends cfg.Operation {
  final RegisterOp opcode;
  final cfg.SSA? result;
  final List<cfg.SSA> inputs;
  final List<Object> data;
  final bool pure;
  MachineOperation(
    this.opcode,
    this.result,
    this.inputs,
    this.data, {
    this.pure = false,
  });
  @override
  cfg.SSA? get writesTo => result;
  @override
  Set<cfg.SSA> get readsFrom => inputs.toSet();
  @override
  bool get isPure => pure;
  @override
  bool get isTerminator => switch (opcode) {
    RegisterOp.jump ||
    RegisterOp.jumpIfFalse ||
    RegisterOp.jumpIfNull ||
    RegisterOp.jumpIfNonNull ||
    RegisterOp.returnValue ||
    RegisterOp.returnAsync ||
    RegisterOp.throwValue ||
    RegisterOp.rethrowValue => true,
    _ => false,
  };
  @override
  cfg.Operation copyWith({cfg.SSA? writesTo, Set<cfg.SSA>? readsFrom}) =>
      MachineOperation(
        opcode,
        writesTo ?? result,
        renameOperands(inputs, this.readsFrom, readsFrom),
        data,
        pure: pure,
      );
  @override
  String toString() => '$result = ${opcode.name} $inputs $data';
}

final class WordInstruction extends cfg.Instruction {
  final List<Object> words;
  WordInstruction(
    RegisterOp opcode,
    int result,
    List<int> inputs,
    List<Object> data,
  ) : words = [
        opcode.index,
        result,
        inputs.length,
        ...inputs,
        data.length,
        ...data,
      ];
}

class BackendResult {
  final List<int> words;
  final Map<int, int> functionOffsets;
  BackendResult(this.words, this.functionOffsets);
}

class RegisterBackend {
  final CompilerContext context;
  final int registerCount;
  RegisterBackend(this.context, {this.registerCount = 32});

  int constant(Object value) => context.constantPool.addOrGet(value);
  cfg.SSA value(cfg.SSA input) => cfg.SSA(input.name, type: 0);

  List<cfg.Operation> lower(
    cfg.Operation op,
    cfg.ControlFlowGraph graph,
    int function,
    int blockId,
  ) {
    final result = op.writesTo == null ? null : value(op.writesTo!);
    MachineOperation make(
      RegisterOp code,
      List<cfg.SSA> args, [
      List<Object> data = const [],
    ]) => MachineOperation(
      code,
      result,
      args.map(value).toList(),
      data,
      pure: op.isPure,
    );
    List<cfg.Operation> staged(
      RegisterOp code,
      List<cfg.SSA> args,
      List<Object> data,
    ) => [
      for (final arg in args)
        MachineOperation(RegisterOp.stageArgument, null, [value(arg)], []),
      MachineOperation(code, result, [], data),
    ];
    BlockAddress address(String label) =>
        BlockAddress(function, graph[label]!.id!);
    List<Object> targets(String label) {
      final target = graph[label]!.id!;
      final others = graph.graph
          .successorsOf(blockId)
          .where((id) => id != target)
          .toList();
      // Exception destinations are represented by enterTry; choose normal fallthrough first.
      return [
        BlockAddress(function, target),
        BlockAddress(function, others.first),
      ];
    }

    return switch (op) {
      NumericBinary(
        :final left,
        :final right,
        :final operandRepresentation,
        :final operator,
      ) =>
        [
          make(
            switch (operator) {
              NumericOperator.add =>
                operandRepresentation == MachineRepresentation.integer
                    ? RegisterOp.intAdd
                    : RegisterOp.doubleAdd,
              NumericOperator.subtract =>
                operandRepresentation == MachineRepresentation.integer
                    ? RegisterOp.intSub
                    : RegisterOp.doubleSub,
              NumericOperator.multiply =>
                operandRepresentation == MachineRepresentation.integer
                    ? RegisterOp.intMul
                    : RegisterOp.doubleMul,
              NumericOperator.divide => RegisterOp.doubleDiv,
              NumericOperator.truncatingDivide => RegisterOp.intDiv,
              NumericOperator.modulo => RegisterOp.numericMod,
              NumericOperator.lessThan => RegisterOp.numericLt,
              NumericOperator.lessThanOrEqual => RegisterOp.numericLte,
              NumericOperator.greaterThan => RegisterOp.numericGt,
              NumericOperator.greaterThanOrEqual => RegisterOp.numericGte,
              NumericOperator.equal => RegisterOp.numericEq,
              NumericOperator.notEqual => RegisterOp.numericNe,
            },
            [left, right],
          ),
        ],
      memory.LoadInt(:final value) => [
        make(RegisterOp.constant, [], [constant(value)]),
      ],
      memory.LoadDouble(:final value) => [
        make(RegisterOp.constant, [], [constant(value)]),
      ],
      memory.LoadString(:final value) => [
        make(RegisterOp.constant, [], [constant(value)]),
      ],
      memory.LoadBool(:final value) => [
        make(RegisterOp.constant, [], [constant(value)]),
      ],
      memory.LoadNull() => [
        make(RegisterOp.constant, [], [-1]),
      ],
      cfg.Assign(:final target, :final source) => [
        cfg.Assign(value(target), value(source)),
      ],
      memory.Assign(:final target, :final source) => [
        cfg.Assign(value(target), value(source)),
      ],
      alu.IntAdd(:final left, :final right) => [
        make(RegisterOp.intAdd, [left, right]),
      ],
      alu.IntSub(:final left, :final right) => [
        make(RegisterOp.intSub, [left, right]),
      ],
      alu.IntLessThan(:final left, :final right) => [
        make(RegisterOp.intLt, [left, right]),
      ],
      alu.IntLessThanOrEqual(:final left, :final right) => [
        make(RegisterOp.intLte, [left, right]),
      ],
      alu.IntGreaterThan(:final left, :final right) => [
        make(RegisterOp.intGt, [left, right]),
      ],
      alu.IntGreaterThanOrEqual(:final left, :final right) => [
        make(RegisterOp.intGte, [left, right]),
      ],
      alu.IntEqual(:final left, :final right) => [
        make(RegisterOp.intEq, [left, right]),
      ],
      alu.IntNotEqual(:final left, :final right) => [
        make(RegisterOp.intNe, [left, right]),
      ],
      alu.LessThan(:final left, :final right) => [
        make(RegisterOp.lessThan, [left, right]),
      ],
      objects.DynamicEquals(:final left, :final right) => [
        make(RegisterOp.dynamicEquals, [left, right]),
      ],
      logic.LogicalAnd(:final left, :final right) => [
        make(RegisterOp.logicalAnd, [left, right]),
      ],
      logic.LogicalOr(:final left, :final right) => [
        make(RegisterOp.logicalOr, [left, right]),
      ],
      alu.Increment(:final source) => [
        make(RegisterOp.increment, [source]),
      ],
      memory.IsNull(:final object) => [
        make(RegisterOp.isNull, [object]),
      ],
      logic.LogicalNot(:final source) => [
        make(RegisterOp.logicalNot, [source]),
      ],
      objects.LoadSuper(:final object) => [
        make(RegisterOp.loadSuper, [object]),
      ],
      types.LoadRuntimeType(:final object) => [
        make(RegisterOp.loadRuntimeType, [object]),
      ],
      primitives.BoxInt(:final source) => [
        make(RegisterOp.boxInt, [source]),
      ],
      primitives.BoxDouble(:final source) => [
        make(RegisterOp.boxDouble, [source]),
      ],
      primitives.BoxNum(:final source) => [
        make(RegisterOp.boxNum, [source]),
      ],
      primitives.BoxBool(:final source) => [
        make(RegisterOp.boxBool, [source]),
      ],
      primitives.BoxString(:final source) => [
        make(RegisterOp.boxString, [source]),
      ],
      primitives.BoxList(:final source) => [
        make(RegisterOp.boxList, [source]),
      ],
      primitives.BoxMap(:final source) => [
        make(RegisterOp.boxMap, [source]),
      ],
      primitives.BoxSet(:final source) => [
        make(RegisterOp.boxSet, [source]),
      ],
      primitives.MaybeBoxNull(:final source) => [
        make(RegisterOp.maybeBoxNull, [source]),
      ],
      primitives.Unbox(:final source) => [
        make(RegisterOp.unbox, [source]),
      ],
      primitives.BoxNull() => [make(RegisterOp.boxNull, [])],
      flow.Jump(:final target) => [
        make(RegisterOp.jump, [], [address(target)]),
      ],
      flow.JumpIfFalse(:final condition, :final target) => [
        make(RegisterOp.jumpIfFalse, [condition], targets(target)),
      ],
      flow.JumpIfNull(:final condition, :final target) => [
        make(RegisterOp.jumpIfNull, [condition], targets(target)),
      ],
      flow.JumpIfNonNull(:final condition, :final target) => [
        make(RegisterOp.jumpIfNonNull, [condition], targets(target)),
      ],
      flow.Call(:final target, :final arguments) => staged(
        RegisterOp.call,
        arguments,
        [FunctionAddress(target)],
      ),
      bridge.InvokeExternal(:final externalFunctionId, :final args) => staged(
        RegisterOp.invokeExternal,
        args,
        [externalFunctionId],
      ),
      objects.InvokeDynamic(:final object, :final name, :final args) => staged(
        RegisterOp.invokeDynamic,
        [object, ...args],
        [constant(name)],
      ),
      closures.InvokeClosure(:final closure, :final positional, :final named) =>
        staged(
          RegisterOp.invokeClosure,
          [closure, ...positional, ...named.values],
          [positional.length, constant(named.keys.toList())],
        ),
      flow.Return(:final value) => [
        make(RegisterOp.returnValue, [if (value != null) value]),
      ],
      flow.ReturnAsync(:final value, :final completer) => [
        make(RegisterOp.returnAsync, [if (value != null) value, completer]),
      ],
      closures.CreateClosure(
        :final target,
        :final captures,
        :final requiredPositional,
        :final positionalTypes,
        :final namedNames,
        :final namedTypes,
        :final boundReceiver,
        :final positionalUnboxed,
        :final namedUnboxed,
      ) =>
        staged(RegisterOp.createClosure, captures, [
          FunctionAddress(target),
          constant({
            'requiredPositional': requiredPositional,
            'positionalTypes': positionalTypes,
            'namedNames': namedNames,
            'namedTypes': namedTypes,
            'boundReceiver': boundReceiver,
            'positionalUnboxed': positionalUnboxed,
            'namedUnboxed': namedUnboxed,
          }),
        ]),
      closures.LoadCapture(:final index) => [
        make(RegisterOp.loadCapture, [], [index]),
      ],
      function_ir.Parameter(:final index) => [
        make(RegisterOp.parameter, [], [index]),
      ],
      function_ir.LoadFunctionPointer(:final target) => [
        make(RegisterOp.loadFunctionPointer, [], [
          FunctionAddress(
            DeferredOrOffset(
              offset: context.functionNames.entries
                  .firstWhere((entry) => entry.value == target)
                  .key,
            ),
          ),
        ]),
      ],
      objects.CreateClass(
        :final library,
        :final name,
        :final $super,
        :final valuesLength,
      ) =>
        [
          make(
            RegisterOp.createClass,
            [$super],
            [library, constant(name), valuesLength],
          ),
        ],
      objects.LoadPropertyStatic(:final object, :final index) => [
        make(RegisterOp.loadPropertyStatic, [object], [index]),
      ],
      objects.SetPropertyStatic(:final object, :final value, :final index) => [
        make(RegisterOp.setPropertyStatic, [object, value], [index]),
      ],
      objects.LoadPropertyDynamic(:final object, :final name) => [
        make(RegisterOp.loadPropertyDynamic, [object], [constant(name)]),
      ],
      objects.SetPropertyDynamic(:final object, :final variable, :final name) =>
        [
          make(
            RegisterOp.setPropertyDynamic,
            [object, variable],
            [constant(name)],
          ),
        ],
      bridge.NewBridgeSuperShim() => [make(RegisterOp.newBridgeSuperShim, [])],
      bridge.ParentBridgeSuperShim(:final shim, :final parent) => [
        make(RegisterOp.parentBridgeSuperShim, [shim, parent]),
      ],
      bridge.BridgeInstantiate(
        :final subclass,
        :final args,
        :final externalFunctionId,
      ) =>
        staged(
          RegisterOp.bridgeInstantiate,
          [subclass, ...args],
          [externalFunctionId],
        ),
      globals.LoadGlobal(:final index) => [
        make(RegisterOp.loadGlobal, [], [index]),
      ],
      globals.SetGlobal(:final index, :final source) => [
        make(RegisterOp.setGlobal, [source], [index]),
      ],
      collection.NewList() => [make(RegisterOp.newList, [])],
      collection.NewMap() => [make(RegisterOp.newMap, [])],
      collection.NewSet() => [make(RegisterOp.newSet, [])],
      collection.IndexList(:final list, :final index) => [
        make(RegisterOp.indexList, [list, index]),
      ],
      collection.IndexMap(:final map, :final key) => [
        make(RegisterOp.mapIndex, [map, key]),
      ],
      collection.ListSet(:final list, :final index, :final value) => [
        make(RegisterOp.listSet, [list, index, value]),
      ],
      collection.MapSet(:final map, :final key, :final value) => [
        make(RegisterOp.mapSet, [map, key, value]),
      ],
      collection.ListAppend(:final list, :final value) => [
        make(RegisterOp.listAppend, [list, value]),
      ],
      collection.SetAdd(:final set, :final value) => [
        make(RegisterOp.setAdd, [set, value]),
      ],
      collection.IterableLength(:final iterable) => [
        make(RegisterOp.iterableLength, [iterable]),
      ],
      collection.NewRecord(:final fields, :final fieldIndices, :final typeId) =>
        [
          make(RegisterOp.newRecord, [fields], [fieldIndices, typeId]),
        ],
      types.AssertType(:final object, :final typeId) => [
        make(RegisterOp.assertType, [object], [typeId]),
      ],
      types.IsType(:final object, :final typeId, :final not) => [
        make(RegisterOp.isType, [object], [typeId, not ? 1 : 0]),
      ],
      types.LoadConstantType(:final typeId) => [
        make(RegisterOp.loadConstantType, [], [typeId]),
      ],
      flow.Assert(:final condition, :final errorMessage) => [
        make(RegisterOp.assertValue, [condition, errorMessage]),
      ],
      flow.Throw(:final value) => [
        make(RegisterOp.throwValue, [value]),
      ],
      flow.Rethrow(:final value) => [
        make(RegisterOp.rethrowValue, [value]),
      ],
      exception.EnterTry(:final catchTarget, :final finallyTarget) => [
        make(RegisterOp.enterTry, [], [
          catchTarget == null ? -1 : address(catchTarget),
          finallyTarget == null ? -1 : address(finallyTarget),
        ]),
      ],
      exception.LeaveTry() => [make(RegisterOp.leaveTry, [])],
      exception.CaughtException() => [make(RegisterOp.caughtException, [])],
      exception.CaughtStackTrace() => [make(RegisterOp.caughtStackTrace, [])],
      exception.ResumeCompletion() => [make(RegisterOp.resumeCompletion, [])],
      async.Await(:final completer, :final subject) => [
        make(RegisterOp.awaitValue, [completer, subject]),
      ],
      _ => throw UnsupportedError('No register lowering for ${op.runtimeType}'),
    };
  }

  BackendResult compile() {
    final emitted = <int, Map<int, List<cfg.Instruction>>>{};
    final spillCounts = <int, int>{};
    for (final entry in context.functionGraphs.entries) {
      final functionId = entry.key;
      final graph = copyGraph(entry.value);
      for (final blockId in graph.graph.vertices.toList()) {
        final block = graph[blockId]!;
        final lowered = [
          for (final op in block.code) ...lower(op, graph, functionId, blockId),
        ];
        block.code
          ..clear()
          ..addAll(lowered);
      }
      graph.insertPhiNodes();
      graph.computeSemiPrunedSSA();
      graph.removeUnusedDefines();
      final registers = cfg.RegisterGroup({
        for (var i = 0; i < registerCount; i++) i,
      });
      graph.registerRegType(0, cfg.RegType(0, 'value', {registers}));
      graph.opCreators[MachineOperation] = cfg.Creator<MachineOperation, void>(
        variants: {},
        create: (op, _) => WordInstruction(
          op.opcode,
          op.result == null || op.result!.name == '@branch'
              ? -1
              : op.result!.alloc.register,
          op.inputs.map((input) => input.alloc.register).toList(),
          op.data,
        ),
      );
      graph.spillReloadVariables({registers: registerCount});
      graph.removePhiNodes(
        cfg.Assign.new,
        onSplitEdge: (predecessor, oldTarget, newTarget) {
          final block = graph[predecessor]!;
          for (var i = 0; i < block.code.length; i++) {
            final op = block.code[i];
            if (op is MachineOperation) {
              block.code[i] =
                  MachineOperation(op.opcode, op.result, op.inputs, [
                    for (final datum in op.data)
                      if (datum is BlockAddress && datum.block == oldTarget)
                        BlockAddress(functionId, newTarget)
                      else
                        datum,
                  ], pure: op.pure);
            }
          }
        },
      );
      graph.performRegisterAllocation();
      var spills = 0;
      emitted[functionId] = graph.assembleToInstructions(
        cfg.AssemblerConfig<void>(
          contextData: null,
          onSpill: (variable, slot, _) {
            if (slot + 1 > spills) spills = slot + 1;
            return WordInstruction(
              RegisterOp.spill,
              -1,
              [variable.register],
              [slot],
            );
          },
          onReload: (variable, slot, _) {
            if (slot + 1 > spills) spills = slot + 1;
            return WordInstruction(RegisterOp.reload, variable.register, [], [
              slot,
            ]);
          },
          onMove: (target, source, _) => WordInstruction(
            RegisterOp.move,
            target.register,
            [source.register],
            [],
          ),
          onSwap: (a, b, _) => WordInstruction(RegisterOp.swap, -1, [
            a.register,
            b.register,
          ], []),
          onJump: (target, _) => WordInstruction(RegisterOp.jump, -1, [], [
            BlockAddress(functionId, target),
          ]),
        ),
      );
      spillCounts[functionId] = spills;
    }
    final offsets = <int, int>{};
    final blockOffsets = <(int, int), int>{};
    final words = <Object>[];
    for (final function in emitted.entries) {
      offsets[function.key] = words.length;
      final signature = context.functionSignatures[function.key];
      words.addAll(
        WordInstruction(RegisterOp.entry, -1, [], [
          registerCount,
          spillCounts[function.key]!,
          if (signature != null) ...[
            104,
            signature.parameters.length,
            for (final parameter in signature.parameters) parameter.index,
            signature.result?.index ?? -1,
          ],
        ]).words,
      );
      for (final block in function.value.entries) {
        blockOffsets[(function.key, block.key)] = words.length;
        for (final instruction in block.value) {
          words.addAll((instruction as WordInstruction).words);
        }
      }
    }
    int resolveFunction(DeferredOrOffset target) {
      if (target.offset != null) return offsets[target.offset]!;
      final library = target.file;
      final className = target.className;
      int? id;
      if (className != null) {
        final methods =
            context.instanceDeclarationPositions[library]?[className];
        if (methods != null) {
          for (var kind = 0; kind < 3; kind++) {
            id ??= (methods[kind] as Map).cast<String, int>()[target.name];
          }
        }
      }
      id ??= context.topLevelDeclarationPositions[library]?[target.name];
      if (id == null || offsets[id] == null)
        throw StateError('Unresolved function $target');
      return offsets[id]!;
    }

    return BackendResult([
      for (final word in words)
        switch (word) {
          int() => word,
          BlockAddress(:final function, :final block) =>
            blockOffsets[(function, block)]!,
          FunctionAddress(:final target) => resolveFunction(target),
          _ => throw StateError('Invalid instruction operand $word'),
        },
    ], offsets);
  }
}
