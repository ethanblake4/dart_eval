import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:test/test.dart';

void main() {
  test('call renaming keeps repeated argument slots and explicit result', () {
    final input = SSA('x');
    final renamed = SSA('x', version: 1);
    final result = SSA('result', version: 1);
    final call = Call(DeferredOrOffset(name: 'f'), [
      input,
      input,
    ], result: SSA('result'));
    final copy = call.copyWith(readsFrom: {renamed}, writesTo: result) as Call;
    expect(copy.arguments, [renamed, renamed]);
    expect(copy.writesTo, result);
    expect(call, isNot(Call(call.target, [input], result: call.result)));
  });

  test('branch renaming uses the renamed condition and preserves target', () {
    final renamed = SSA('condition', version: 3);
    final branch = JumpIfFalse(SSA('condition'), 'else');
    final copy = branch.copyWith(readsFrom: {renamed}) as JumpIfFalse;
    expect(copy.condition, renamed);
    expect(copy.target, 'else');
  });

  test('void return can be renamed with an empty input set', () {
    expect((Return(null).copyWith(readsFrom: {}) as Return).value, isNull);
  });

  test('async return preserves duplicate value and completer inputs', () {
    final input = SSA('x');
    final renamed = SSA('x', version: 2);
    final result =
        ReturnAsync(input, input).copyWith(readsFrom: {renamed}) as ReturnAsync;
    expect(result.value, renamed);
    expect(result.completer, renamed);
  });
}
