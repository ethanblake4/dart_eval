import 'dart:typed_data';

import 'package:dart_eval/src/eval/runtime/typed/typed.dart';
import 'package:test/test.dart';

class _Assembly {
  final bytes = <int>[];
  int get pc => bytes.length;
  void op(int opcode, [int? operand]) {
    bytes.add(opcode);
    final length = TypedOp.instructions[opcode].length;
    for (var i = 1; i < length; i++) {
      bytes.add((operand! >> (8 * (i - 1))) & 255);
    }
  }

  void address(int instruction, int target) {
    for (var i = 0; i < 4; i++) {
      bytes[instruction + 1 + i] = (target >> (8 * i)) & 255;
    }
  }
}

TypedProgram _recursive() {
  final a = _Assembly();
  a.op(TypedOp.aArgument, 0);
  a.op(TypedOp.aOutgoing, 0);
  a.op(TypedOp.callInt, 1);
  a.op(TypedOp.aReturn);
  final factorial = a.pc;
  a.op(TypedOp.aArgument, 0);
  a.op(TypedOp.aSpill, 0);
  a.op(TypedOp.bConstant, 0);
  a.op(TypedOp.eLteAB);
  final branch = a.pc;
  a.op(TypedOp.jumpETrue, 0);
  a.op(TypedOp.aDecrement);
  a.op(TypedOp.aOutgoing, 0);
  a.op(TypedOp.callInt, 1);
  a.op(TypedOp.bReload, 0);
  a.op(TypedOp.aMulB);
  a.op(TypedOp.aReturn);
  a.address(branch, a.pc);
  a.op(TypedOp.aConstant, 0);
  a.op(TypedOp.aReturn);
  return TypedProgram(
    Uint8List.fromList(a.bytes),
    integers: [1],
    functions: [
      const TypedFunction(0, intArgumentCount: 1, intOutgoingCount: 1),
      TypedFunction(
        factorial,
        intArgumentCount: 1,
        intOutgoingCount: 1,
        intSpillCount: 1,
      ),
    ],
  );
}

void main() {
  for (final encoded in [false, true]) {
    test(
      'recursive calls preserve private typed spill banks, encoded=$encoded',
      () {
        var p = _recursive();
        if (encoded) p = TypedProgram.read(p.write().buffer);
        expect(TypedMachine.run(p, intArguments: [10]), 3628800);
        expect(TypedMachine.run(p, intArguments: [1]), 1);
      },
    );
  }
  test(
    'double and bool returns restore callers with separate argument banks',
    () {
      final a = _Assembly();
      a.op(TypedOp.fConstant, 0);
      a.op(TypedOp.fOutgoing, 0);
      a.op(TypedOp.callDouble, 1);
      a.op(TypedOp.fSpill, 0);
      a.op(TypedOp.eTrue);
      a.op(TypedOp.eOutgoing, 0);
      a.op(TypedOp.callBool, 2);
      final branch = a.pc;
      a.op(TypedOp.jumpETrue, 0);
      a.op(TypedOp.fConstant, 1);
      a.op(TypedOp.fReturn);
      a.address(branch, a.pc);
      a.op(TypedOp.fReload, 0);
      a.op(TypedOp.fReturn);
      final doubleEntry = a.pc;
      a.op(TypedOp.gArgument, 0);
      a.op(TypedOp.fFromG);
      a.op(TypedOp.fAddG);
      a.op(TypedOp.fReturn);
      final boolEntry = a.pc;
      a.op(TypedOp.xArgument, 0);
      a.op(TypedOp.xReturn);
      final p = TypedProgram(
        Uint8List.fromList(a.bytes),
        doubles: [1.25, -1.0],
        functions: [
          const TypedFunction(
            0,
            doubleSpillCount: 1,
            doubleOutgoingCount: 1,
            boolOutgoingCount: 1,
          ),
          TypedFunction(doubleEntry, doubleArgumentCount: 1),
          TypedFunction(boolEntry, boolArgumentCount: 1),
        ],
      );
      expect(TypedMachine.run(TypedProgram.read(p.write().buffer)), 2.5);
    },
  );
  test(
    'codec preserves signed limits, IEEE values and inferred entry arguments',
    () {
      final p = TypedProgram(
        Uint8List.fromList([TypedOp.fArgument, 0, 0, TypedOp.fReturn]),
        integers: [-9223372036854775808, 9223372036854775807],
        doubles: [double.nan, -0.0, double.infinity],
      );
      final restored = TypedProgram.read(p.write().buffer);
      expect(restored.integers, p.integers);
      expect(restored.doubles[0].isNaN, isTrue);
      expect(restored.doubles[1].isNegative, isTrue);
      expect(restored.doubles[2], double.infinity);
      expect(TypedMachine.run(restored, doubleArguments: [3.5]), 3.5);
    },
  );
  test('codec rejects corruption before allocating section arrays', () {
    final bytes = _recursive().write().buffer.asUint8List();
    for (final size in [0, 12, bytes.length - 1]) {
      expect(
        () => TypedProgram.read(
          Uint8List.fromList(bytes.take(size).toList()).buffer,
        ),
        throwsFormatException,
      );
    }
    final bad = Uint8List.fromList(bytes);
    bad[4] = 255;
    expect(() => TypedProgram.read(bad.buffer), throwsFormatException);
    final length = Uint8List.fromList(bytes);
    ByteData.sublistView(length).setUint32(12, 0xffffffff, Endian.little);
    expect(() => TypedProgram.read(length.buffer), throwsFormatException);
  });
  test(
    'validator rejects crossing function boundaries and missing outgoing slots',
    () {
      expect(
        () => TypedProgram(
          Uint8List.fromList([TypedOp.jump, 5, 0, 0, 0, TypedOp.aReturn]),
          functions: [const TypedFunction(0), const TypedFunction(5)],
        ),
        throwsFormatException,
      );
      expect(
        () => TypedProgram(
          Uint8List.fromList([
            TypedOp.callInt,
            1,
            0,
            TypedOp.aReturn,
            TypedOp.aReturn,
          ]),
          functions: [
            const TypedFunction(0),
            const TypedFunction(4, intArgumentCount: 1),
          ],
        ),
        throwsFormatException,
      );
    },
  );
}
