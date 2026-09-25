import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/invocation/deferred.dart';
import 'package:dart_eval/src/eval/ir/alu.dart';
import 'package:dart_eval/src/eval/ir/async.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/closures.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/src/eval/ir/globals.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:test/test.dart';

void main() {
  final input = SSA('input');
  final second = SSA('second');
  final result = SSA('result');
  final target = DeferredOrOffset(name: 'target');
  final pure = <Operation>[
    LoadInt(result, 1),
    LoadDouble(result, 1.5),
    LoadString(result, 'text'),
    LoadBool(result, true),
    LoadNull(result),
    Assign(result, input),
    IsNull(result, input),
    IntAdd(result, input, second),
    IntSub(result, input, second),
    IntLessThan(result, input, second),
    IntEqual(result, input, second),
    IntNotEqual(result, input, second),
    IntLessThanOrEqual(result, input, second),
    IntGreaterThan(result, input, second),
    IntGreaterThanOrEqual(result, input, second),

    LogicalNot(result, input),
    LogicalAnd(result, input, second),
    LogicalOr(result, input, second),
  ];
  for (final op in pure) {
    test('${op.runtimeType} can be removed when unused after SSA renaming', () {
      final renamed = op.copyWith(
        readsFrom: {for (final value in op.readsFrom) SSA('${value.name}_new')},
        writesTo: SSA('new_result'),
      );
      expect(renamed.isPure, isTrue);
      final block = BasicBlock<Operation>([
        for (final value in renamed.readsFrom) Parameter(value, 0),
        renamed,
        Return(null),
      ]);
      final cfg = ControlFlowGraph.builder().root(block).build();
      cfg.insertPhiNodes();
      cfg.computeSemiPrunedSSA();
      cfg.removeUnusedDefines();
      expect(
        block.code.where((value) => value.runtimeType == op.runtimeType),
        isEmpty,
      );
      expect(block.code.whereType<Return>(), hasLength(1));
    });
  }
  final effects = <Operation>[
    Call(target, [input], result: result),
    InvokeDynamic(result, input, 'method', [input]),
    InvokeExternal(result, 0, [input]),
    InvokeClosure(result, input, [input], {'named': input}),
    DynamicEquals(result, input, second),
    LessThan(result, input, second),
    Increment(result, input),
    AssertType(input, 0),
    LoadPropertyDynamic(result, input, 'getter'),
    IndexList(result, input, second),
    IndexMap(result, input, second),
    LoadGlobal(result, 0),
    LoadRuntimeType(result, input),
    NewList(result),
    NewMap(result),
    NewSet(result),
    BoxInt(result, input),
    BoxBool(result, input),
    BoxNull(result),
    BoxList(result, input),
    BoxMap(result, input, runtimeTypeId: 0),
    BoxSet(result, input, runtimeTypeId: 0),
    Unbox(result, input, MachineRepresentation.integer),
    CreateClosure(result, target, [input]),
    Await(result, input, second),
    SetGlobal(0, input),
    SetPropertyDynamic(input, 'setter', second),
    ListAppend(input, second),
    MapSet(input, second, second),
  ];
  for (final op in effects) {
    test('${op.runtimeType} survives DCE when its result is unused', () {
      final block = BasicBlock<Operation>([
        for (final value in op.readsFrom) Parameter(value, 0),
        op,
        Return(null),
      ]);
      final cfg = ControlFlowGraph.builder().root(block).build();
      cfg.insertPhiNodes();
      cfg.computeSemiPrunedSSA();
      cfg.removeUnusedDefines();
      final surviving = block.code.where(
        (value) => value.runtimeType == op.runtimeType,
      );
      expect(surviving, hasLength(1));
      expect(surviving.single.isPure, isFalse);
    });
  }
  test('DCE removes an entire unused arithmetic dependency chain', () {
    final block = BasicBlock<Operation>([
      LoadInt(input, 1),
      LoadInt(second, 2),
      IntAdd(result, input, second),
      Return(null),
    ]);
    final cfg = ControlFlowGraph.builder().root(block).build();
    cfg.insertPhiNodes();
    cfg.computeSemiPrunedSSA();
    cfg.removeUnusedDefines();
    expect(block.code, hasLength(1));
    expect(block.code.single, isA<Return>());
  });
}
