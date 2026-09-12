import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/ir/alu.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:test/test.dart';

void main() {
  final value = SSA('value');
  final renamed = SSA('renamed');
  final result = SSA('result');
  final output = SSA('output');

  test('binary renaming preserves repeated operands', () {
    final op =
        IntSub(
              result,
              value,
              value,
            ).copyWith(readsFrom: {renamed}, writesTo: output)
            as IntSub;
    expect(op.left, renamed);
    expect(op.right, renamed);
    expect(op.writesTo, output);
  });

  test('dynamic calls retain receiver and repeated argument positions', () {
    final receiver = SSA('receiver');
    final newReceiver = SSA('new_receiver');
    final original = InvokeDynamic(result, receiver, 'call', [
      value,
      receiver,
      value,
    ]);
    final op =
        original.copyWith(readsFrom: {renamed, newReceiver}, writesTo: output)
            as InvokeDynamic;
    expect(op.object, newReceiver);
    expect(op.args, [renamed, newReceiver, renamed]);
    expect(op.writesTo, output);
  });

  test(
    'bridge calls preserve duplicate inputs across subclass and arguments',
    () {
      final bridge =
          BridgeInstantiate(result, 7, value, [
                value,
                value,
              ]).copyWith(readsFrom: {renamed}, writesTo: output)
              as BridgeInstantiate;
      expect(bridge.subclass, renamed);
      expect(bridge.args, [renamed, renamed]);
      expect(bridge.externalFunctionId, 7);
      expect(bridge.writesTo, output);
      final external =
          InvokeExternal(result, 7, [
                value,
                value,
              ]).copyWith(readsFrom: {renamed})
              as InvokeExternal;
      expect(external.args, [renamed, renamed]);
    },
  );

  test('static property stores follow declared input order', () {
    final object = SSA('object');
    final newObject = SSA('new_object');
    final original = SetPropertyStatic(object, 3, value);
    expect(original.readsFrom.toList(), [value, object]);
    final op =
        original.copyWith(readsFrom: {renamed, newObject}) as SetPropertyStatic;
    expect(op.object, newObject);
    expect(op.value, renamed);
    expect(op.writesTo, isNull);
  });

  test('collection stores never replace stored value with an SSA output', () {
    final op =
        ListSet(
              value,
              value,
              value,
            ).copyWith(readsFrom: {renamed}, writesTo: output)
            as ListSet;
    expect([op.list, op.index, op.value], [renamed, renamed, renamed]);
    expect(op.writesTo, isNull);
    final map =
        MapSet(
              value,
              value,
              value,
            ).copyWith(readsFrom: {renamed}, writesTo: output)
            as MapSet;
    expect([map.map, map.key, map.value], [renamed, renamed, renamed]);
    expect(map.writesTo, isNull);
  });

  test(
    'increment source and destination may receive different SSA versions',
    () {
      final op =
          Increment(value).copyWith(readsFrom: {renamed}, writesTo: output)
              as Increment;
      expect(op.readsFrom, {renamed});
      expect(op.writesTo, output);
    },
  );

  test('list append and record creation expose their data dependencies', () {
    final append =
        ListAppend(value, value).copyWith(readsFrom: {renamed}) as ListAppend;
    expect([append.list, append.value], [renamed, renamed]);
    expect(append.writesTo, isNull);
    final record =
        NewRecord(
              result,
              value,
              4,
              8,
            ).copyWith(readsFrom: {renamed}, writesTo: output)
            as NewRecord;
    expect(record.readsFrom, {renamed});
    expect(record.writesTo, output);
    expect((record.fieldIndices, record.typeId), (4, 8));
  });
}
