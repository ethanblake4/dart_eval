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
  test('codec preserves object layout and scalar object constants', () {
    final p = TypedProgram(
      Uint8List.fromList([TypedOp.aReturn]),
      objects: [
        null,
        false,
        true,
        -9223372036854775808,
        1.5,
        double.nan,
        -0.0,
        double.infinity,
        'hello \u{1f600}',
        '\ud800',
      ],
      functions: const [
        TypedFunction(
          0,
          objectSpillCount: 3,
          objectArgumentCount: 2,
          objectOutgoingCount: 4,
        ),
      ],
    );
    final restored = TypedProgram.read(p.write().buffer);
    expect(restored.functions.single.layout, p.functions.single.layout);
    expect(restored.objectSpillCount, 3);
    expect(restored.objects.take(5), p.objects.take(5));
    expect((restored.objects[5] as double).isNaN, isTrue);
    expect((restored.objects[6] as double).isNegative, isTrue);
    expect(restored.objects.skip(7), p.objects.skip(7));
  });
  test('object pools retain live identity but reject live serialization', () {
    final live = <int>[1];
    final source = <Object?>[live];
    final p = TypedProgram(
      Uint8List.fromList([TypedOp.aReturn]),
      objects: source,
    );
    source.clear();
    live.add(2);
    expect(identical(p.objects.single, live), isTrue);
    expect(() => p.objects.add(null), throwsUnsupportedError);
    expect(
      () => p.write(),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains('objectArguments'),
        ),
      ),
    );
  });
  test('codec rejects malformed object sections', () {
    final bytes = TypedProgram(
      Uint8List.fromList([TypedOp.aReturn]),
      objects: ['abc'],
    ).write().buffer.asUint8List();
    // The object pool follows the 36-byte header and 52-byte function layout.
    final badTag = Uint8List.fromList(bytes)..[88] = 255;
    expect(() => TypedProgram.read(badTag.buffer), throwsFormatException);
    final badString = Uint8List.fromList(bytes);
    ByteData.sublistView(badString).setUint32(89, 0xffffffff, Endian.little);
    expect(() => TypedProgram.read(badString.buffer), throwsFormatException);
    final badCount = Uint8List.fromList(bytes);
    ByteData.sublistView(badCount).setUint32(28, 0, Endian.little);
    expect(() => TypedProgram.read(badCount.buffer), throwsFormatException);
  });
  test('short branches preserve signed displacement endpoints', () {
    final forward = Uint8List(32771)..fillRange(0, 32771, TypedOp.eTrue);
    forward.setAll(0, [TypedOp.jumpShort, 255, 127]);
    forward[32770] = TypedOp.aReturn;
    final p = TypedProgram(forward);
    expect(TypedProgram.read(p.write().buffer).code, forward);
    expect(TypedMachine.run(p), 0);

    final backward = Uint8List(32768)..fillRange(0, 32768, TypedOp.eTrue);
    backward.setAll(32765, [TypedOp.jumpShort, 0, 128]);
    expect(TypedProgram(backward).code, backward);
  });
  test('short branches reject invalid targets and truncated operands', () {
    for (final code in [
      [TypedOp.jumpShort, 0],
      [TypedOp.jumpShort, 255, 127],
      [TypedOp.jumpShort, 0, 128],
      [TypedOp.jumpShort, 254, 255], // Into the displacement itself.
    ]) {
      expect(
        () => TypedProgram(Uint8List.fromList(code)),
        throwsFormatException,
      );
    }
    expect(
      () => TypedProgram(
        Uint8List.fromList([TypedOp.jumpShort, 0, 0, TypedOp.aReturn]),
        functions: const [TypedFunction(0), TypedFunction(3)],
      ),
      throwsFormatException,
    );
    expect(
      () => TypedProgram(
        Uint8List.fromList([TypedOp.aReturn, TypedOp.jumpShort, 252, 255]),
        functions: const [TypedFunction(0), TypedFunction(1)],
      ),
      throwsFormatException,
    );
  });
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
