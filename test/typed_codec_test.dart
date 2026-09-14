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
  a.op(TypedOp.call, 1);
  a.op(TypedOp.aReturn);
  final factorial = a.pc;
  a.op(TypedOp.aSpill, 0);
  a.op(TypedOp.bConstant, 0);
  a.op(TypedOp.eLteAB);
  final branch = a.pc;
  a.op(TypedOp.jumpETrue, 0);
  a.op(TypedOp.aDecrement);
  a.op(TypedOp.call, 1);
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
      const TypedFunction(0, argumentKinds: [TypedArgumentKind.integer]),
      TypedFunction(
        factorial,
        argumentKinds: [TypedArgumentKind.integer],
        intSpillCount: 1,
      ),
    ],
  );
}

void main() {
  test('program freezes argument signatures before validation', () {
    final kinds = [TypedArgumentKind.integer];
    final function = TypedFunction(0, argumentKinds: kinds);
    final p = TypedProgram(
      Uint8List.fromList([TypedOp.aReturn]),
      functions: [function],
    );
    kinds[0] = TypedArgumentKind.object;
    kinds.add(TypedArgumentKind.string);
    expect(p.functions.single.argumentKinds, [TypedArgumentKind.integer]);
    expect(
      p.functions.single.callLayout.arguments.single.bank,
      TypedRegisterBank.integer,
    );
    expect(TypedMachine.run(p, intArguments: [42]), 42);
    expect(
      () => p.functions.single.argumentKinds.add(TypedArgumentKind.object),
      throwsUnsupportedError,
    );
  });
  test(
    'argument layout gives primitive registers priority and preserves remainder order',
    () {
      const kinds = [
        TypedArgumentKind.object,
        TypedArgumentKind.integer,
        TypedArgumentKind.string,
        TypedArgumentKind.integer,
        TypedArgumentKind.integer,
        TypedArgumentKind.doublePrecision,
        TypedArgumentKind.boolean,
        TypedArgumentKind.object,
      ];
      final layout = TypedCallLayout(kinds);
      expect(layout.arguments.map((a) => (a.bank, a.index, a.overflowIndex)), [
        (TypedRegisterBank.object, 0, null),
        (TypedRegisterBank.integer, 0, null),
        (TypedRegisterBank.object, 1, null),
        (TypedRegisterBank.integer, 1, null),
        (TypedRegisterBank.object, 2, 0),
        (TypedRegisterBank.doublePrecision, 0, null),
        (TypedRegisterBank.boolean, 0, null),
        (TypedRegisterBank.object, 2, 1),
      ]);
      expect(layout.overflowCount, 2);
      final registersOnly = TypedCallLayout(kinds.take(7).toList());
      expect(registersOnly.arguments[4].index, 2);
      expect(registersOnly.arguments[4].overflowIndex, isNull);
      expect(registersOnly.overflowCount, 0);
    },
  );
  test(
    'codec retains source order for native values in the C overflow list',
    () {
      final p = TypedProgram(
        Uint8List.fromList([
          TypedOp.rOverflow,
          0,
          0,
          TypedOp.aNativeFromR,
          TypedOp.aReturn,
        ]),
        functions: const [
          TypedFunction(
            0,
            argumentKinds: [
              TypedArgumentKind.string,
              TypedArgumentKind.integer,
              TypedArgumentKind.object,
              TypedArgumentKind.integer,
              TypedArgumentKind.integer,
              TypedArgumentKind.integer,
            ],
          ),
        ],
      );
      expect(
        TypedMachine.run(
          TypedProgram.read(p.write().buffer),
          intArguments: [11, 22, 33, 44],
          objectArguments: ['hello', null],
        ),
        33,
      );
    },
  );
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
      a.op(TypedOp.call, 1);
      a.op(TypedOp.fSpill, 0);
      a.op(TypedOp.eTrue);
      a.op(TypedOp.call, 2);
      final branch = a.pc;
      a.op(TypedOp.jumpETrue, 0);
      a.op(TypedOp.fConstant, 1);
      a.op(TypedOp.fReturn);
      a.address(branch, a.pc);
      a.op(TypedOp.fReload, 0);
      a.op(TypedOp.fReturn);
      final doubleEntry = a.pc;
      a.op(TypedOp.gFromF);
      a.op(TypedOp.fFromG);
      a.op(TypedOp.fAddG);
      a.op(TypedOp.fReturn);
      final boolEntry = a.pc;
      a.op(TypedOp.xFromE);
      a.op(TypedOp.xReturn);
      final p = TypedProgram(
        Uint8List.fromList(a.bytes),
        doubles: [1.25, -1.0],
        functions: [
          const TypedFunction(0, doubleSpillCount: 1),
          TypedFunction(
            doubleEntry,
            argumentKinds: [TypedArgumentKind.doublePrecision],
          ),
          TypedFunction(boolEntry, argumentKinds: [TypedArgumentKind.boolean]),
        ],
      );
      expect(TypedMachine.run(TypedProgram.read(p.write().buffer)), 2.5);
    },
  );
  test(
    'codec preserves signed limits, IEEE values and explicit entry arguments',
    () {
      final p = TypedProgram(
        Uint8List.fromList([TypedOp.fReturn]),
        integers: [-9223372036854775808, 9223372036854775807],
        doubles: [double.nan, -0.0, double.infinity],
        functions: const [
          TypedFunction(0, argumentKinds: [TypedArgumentKind.doublePrecision]),
        ],
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
          argumentKinds: [TypedArgumentKind.object, TypedArgumentKind.string],
          objectOutgoingCount: 4,
        ),
      ],
    );
    final restored = TypedProgram.read(p.write().buffer);
    expect(restored.functions.single.layout, p.functions.single.layout);
    expect(
      restored.functions.single.argumentKinds,
      p.functions.single.argumentKinds,
    );
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
  test('codec rejects malformed argument representation metadata', () {
    final bytes = TypedProgram(
      Uint8List.fromList([TypedOp.aReturn]),
      functions: const [
        TypedFunction(0, argumentKinds: [TypedArgumentKind.string]),
      ],
    ).write().buffer.asUint8List();
    final badKind = Uint8List.fromList(bytes)..[64] = 255;
    expect(() => TypedProgram.read(badKind.buffer), throwsFormatException);
    final badCount = Uint8List.fromList(bytes);
    ByteData.sublistView(badCount).setUint32(60, 2, Endian.little);
    expect(() => TypedProgram.read(badCount.buffer), throwsFormatException);
  });
  test('calls need outgoing storage only beyond the register capacity', () {
    final code = Uint8List.fromList([
      TypedOp.call,
      1,
      0,
      TypedOp.aReturn,
      TypedOp.aReturn,
    ]);
    final p = TypedProgram(
      code,
      functions: const [
        TypedFunction(0),
        TypedFunction(
          4,
          argumentKinds: [
            TypedArgumentKind.integer,
            TypedArgumentKind.integer,
            TypedArgumentKind.doublePrecision,
            TypedArgumentKind.doublePrecision,
            TypedArgumentKind.boolean,
            TypedArgumentKind.boolean,
            TypedArgumentKind.object,
            TypedArgumentKind.object,
            TypedArgumentKind.string,
          ],
        ),
      ],
    );
    expect(TypedProgram.read(p.write().buffer).functions.length, 2);
    expect(
      () => TypedProgram(
        Uint8List.fromList([TypedOp.rOverflow, 0, 0, TypedOp.aReturn]),
        functions: const [
          TypedFunction(
            0,
            argumentKinds: [
              TypedArgumentKind.integer,
              TypedArgumentKind.integer,
            ],
          ),
        ],
      ),
      throwsFormatException,
    );
  });
  test('codec rejects malformed object sections', () {
    final bytes = TypedProgram(
      Uint8List.fromList([TypedOp.aReturn]),
      objects: ['abc'],
    ).write().buffer.asUint8List();
    // The object pool follows the 36-byte header and 28-byte function layout.
    final badTag = Uint8List.fromList(bytes)..[64] = 255;
    expect(() => TypedProgram.read(badTag.buffer), throwsFormatException);
    final badString = Uint8List.fromList(bytes);
    ByteData.sublistView(badString).setUint32(65, 0xffffffff, Endian.little);
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
            TypedOp.call,
            1,
            0,
            TypedOp.aReturn,
            TypedOp.aReturn,
          ]),
          functions: [
            const TypedFunction(0),
            const TypedFunction(
              4,
              argumentKinds: [
                TypedArgumentKind.object,
                TypedArgumentKind.object,
                TypedArgumentKind.object,
                TypedArgumentKind.object,
              ],
            ),
          ],
        ),
        throwsFormatException,
      );
    },
  );
}
