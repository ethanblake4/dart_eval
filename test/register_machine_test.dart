import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

class _Code {
  final bytes = <int>[];
  int get length => bytes.length;
  int emit(int opcode, [int? operand]) {
    final offset = bytes.length;
    bytes.add(opcode);
    for (var i = 1; i < TypedOp.instructions[opcode].length; i++) {
      bytes.add((operand! >> (8 * (i - 1))) & 255);
    }
    return offset;
  }

  void patchBranch(int instruction, int address) {
    for (var i = 0; i < 4; i++) {
      bytes[instruction + 1 + i] = (address >> (i * 8)) & 255;
    }
  }
}

Runtime machine(TypedProgram typed, {bool encoded = false}) {
  final program = Program({}, {}, {}, [], typed, {}, {}, [], [], [], {}, {});
  return encoded ? Runtime(program.write().buffer) : Runtime.ofProgram(program);
}

void main() {
  for (final encoded in [false, true]) {
    test(
      'typed arithmetic and spill reload through Program, encoded=$encoded',
      () {
        final code = _Code()
          ..emit(TypedOp.aConstant, 0)
          ..emit(TypedOp.aSpill, 0)
          ..emit(TypedOp.aConstant, 1)
          ..emit(TypedOp.bReload, 0)
          ..emit(TypedOp.bSubA)
          ..emit(TypedOp.bReturn);
        final typed = TypedProgram(
          Uint8List.fromList(code.bytes),
          integers: [9, 4],
          functions: const [
            TypedFunction(
              0,
              intSpillCount: 1,
              resultKind: TypedArgumentKind.integer,
            ),
          ],
        );
        expect(machine(typed, encoded: encoded).execute(0), 5);
      },
    );

    test(
      'typed recursion preserves caller spills through Program, encoded=$encoded',
      () {
        final code = _Code()
          ..emit(TypedOp.aSpill, 0)
          ..emit(TypedOp.bConstant, 0)
          ..emit(TypedOp.eLteAB);
        final branch = code.emit(TypedOp.jumpETrue, 0);
        code
          ..emit(TypedOp.aDecrement)
          ..emit(TypedOp.call, 0)
          ..emit(TypedOp.bReload, 0)
          ..emit(TypedOp.aMulB)
          ..emit(TypedOp.aReturn);
        code.patchBranch(branch, code.length);
        code
          ..emit(TypedOp.aConstant, 0)
          ..emit(TypedOp.aReturn);
        final typed = TypedProgram(
          Uint8List.fromList(code.bytes),
          integers: [1],
          functions: const [
            TypedFunction(
              0,
              intSpillCount: 1,
              argumentKinds: [TypedArgumentKind.integer],
              resultKind: TypedArgumentKind.integer,
            ),
          ],
        );
        final runtime = machine(typed, encoded: encoded);
        runtime.args = [6];
        expect(runtime.execute(0), 720);
        runtime.args = [3];
        expect(runtime.execute(0), 6);
      },
    );
  }

  test(
    'invalid typed frame is rejected before execution storage allocation',
    () {
      for (final count in [-1, 65537]) {
        expect(
          () => TypedProgram(
            Uint8List.fromList([TypedOp.aReturn]),
            functions: [TypedFunction(0, intSpillCount: count)],
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => TypedProgram(
          Uint8List.fromList([TypedOp.aReload, 1, 0, TypedOp.aReturn]),
          functions: const [TypedFunction(0, intSpillCount: 1)],
        ),
        throwsFormatException,
      );
    },
  );
}
