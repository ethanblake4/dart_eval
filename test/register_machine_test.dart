import 'package:dart_eval/src/eval/runtime/runtime.dart' show RuntimeException;
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/ops/register_ops.dart';
import 'package:test/test.dart';

class _Code {
  final words = <int>[];
  int emit(
    RegisterOp op, {
    int result = -1,
    List<int> inputs = const [],
    List<int> data = const [],
  }) {
    final offset = words.length;
    words.addAll([
      op.index,
      result,
      inputs.length,
      ...inputs,
      data.length,
      ...data,
    ]);
    return offset;
  }

  void patch(int instruction, int index, int value) {
    words[instruction + 4 + words[instruction + 2] + index] = value;
  }
}

Runtime machine(_Code code, List<Object> constants, {bool encoded = false}) {
  final program = Program(
    {},
    {},
    {},
    [],
    code.words,
    {},
    {},
    constants,
    [],
    [],
    {},
    {},
  );
  return encoded ? Runtime(program.write().buffer) : Runtime.ofProgram(program);
}

void main() {
  for (final encoded in [false, true]) {
    test('register arithmetic and spill reload, encoded=$encoded', () {
      final code = _Code();
      code.emit(RegisterOp.entry, data: [32, 1]);
      code.emit(RegisterOp.constant, result: 0, data: [0]);
      code.emit(RegisterOp.spill, inputs: [0], data: [0]);
      code.emit(RegisterOp.constant, result: 0, data: [1]);
      code.emit(RegisterOp.reload, result: 1, data: [0]);
      code.emit(RegisterOp.intSub, result: 0, inputs: [1, 0]);
      code.emit(RegisterOp.returnValue, inputs: [0]);
      expect(machine(code, [9, 4], encoded: encoded).execute(0), 5);
    });
  }
  test('recursive calls preserve caller registers and staged arguments', () {
    final code = _Code();
    code.emit(RegisterOp.entry, data: [32, 0]);
    code.emit(RegisterOp.parameter, result: 0, data: [0]);
    code.emit(RegisterOp.constant, result: 1, data: [0]);
    code.emit(RegisterOp.intLte, result: 2, inputs: [0, 1]);
    final branch = code.emit(
      RegisterOp.jumpIfFalse,
      inputs: [2],
      data: [-1, -1],
    );
    final base = code.words.length;
    code.emit(RegisterOp.returnValue, inputs: [1]);
    final recursive = code.words.length;
    code.emit(RegisterOp.intSub, result: 3, inputs: [0, 1]);
    code.emit(RegisterOp.stageArgument, inputs: [3]);
    code.emit(RegisterOp.call, result: 4, data: [0]);
    code.emit(RegisterOp.intMul, result: 5, inputs: [0, 4]);
    code.emit(RegisterOp.returnValue, inputs: [5]);
    code.patch(branch, 0, recursive);
    code.patch(branch, 1, base);
    final runtime = machine(code, [1]);
    runtime.args = [6];
    expect(runtime.execute(0), 720);
    runtime.args = [3];
    expect(runtime.execute(0), 6);
  });
  test('return executes finally before resuming its pending completion', () {
    final code = _Code();
    code.emit(RegisterOp.entry, data: [32, 0]);
    final trap = code.emit(RegisterOp.enterTry, data: [-1, -1]);
    code.emit(RegisterOp.constant, result: 0, data: [0]);
    code.emit(RegisterOp.returnValue, inputs: [0]);
    final cleanup = code.words.length;
    code.emit(RegisterOp.constant, result: 1, data: [1]);
    code.emit(RegisterOp.setGlobal, inputs: [1], data: [0]);
    code.emit(RegisterOp.resumeCompletion);
    code.patch(trap, 1, cleanup);
    final runtime = machine(code, [4, 7]);
    expect(runtime.execute(0), 4);
    expect(runtime.globals[0], 7);
  });
  test('invalid function frame is rejected before allocating registers', () {
    final code = _Code()..emit(RegisterOp.entry, data: [33, 0]);
    expect(
      () => machine(code, []).execute(0),
      throwsA(isA<RuntimeException>()),
    );
  });
}
