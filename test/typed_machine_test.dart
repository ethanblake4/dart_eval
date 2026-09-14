import 'dart:io';
import 'dart:typed_data';

import 'package:dart_eval/src/eval/runtime/typed/typed.dart';
import 'package:test/test.dart';

TypedProgram program(
  List<int> code, {
  List<int> integers = const [],
  List<double> doubles = const [],
  int intSpills = 0,
  int doubleSpills = 0,
  int boolSpills = 0,
  List<TypedArgumentKind> arguments = const [],
}) => TypedProgram(
  Uint8List.fromList(code),
  integers: integers,
  doubles: doubles,
  intSpillCount: intSpills,
  doubleSpillCount: doubleSpills,
  boolSpillCount: boolSpills,
  functions: [
    TypedFunction(
      0,
      argumentKinds: arguments,
      intSpillCount: intSpills,
      doubleSpillCount: doubleSpills,
      boolSpillCount: boolSpills,
    ),
  ],
);

void main() {
  test('single specification regenerates both checked-in outputs exactly', () {
    final result = Process.runSync(Platform.resolvedExecutable, [
      'run',
      'tool/generate_typed_machine.dart',
      '--check',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });
  for (final (opcode, expected) in [
    (TypedOp.aAddB, 13),
    (TypedOp.aSubB, 5),
    (TypedOp.bSubA, -5),
    (TypedOp.aMulB, 36),
    (TypedOp.bDivA, 0),
    (TypedOp.aDivB, 2),
    (TypedOp.aModB, 1),
    (TypedOp.aXorB, 13),
  ]) {
    test('operand order for ${TypedOp.instructions[opcode].name}', () {
      final output = TypedOp.instructions[opcode].outputs.single;
      expect(
        TypedMachine.run(
          program(
            [
              TypedOp.aConstant,
              0,
              0,
              TypedOp.bConstant,
              1,
              0,
              opcode,
              output == TypedRegister.a ? TypedOp.aReturn : TypedOp.bReturn,
            ],
            integers: [9, 4],
          ),
        ),
        expected,
      );
    });
  }
  test('signed integer overflow, typed spill and reload preserve all bits', () {
    expect(
      TypedMachine.run(
        program(
          [
            TypedOp.aConstant,
            0,
            0,
            TypedOp.aIncrement,
            TypedOp.aSpill,
            0,
            0,
            TypedOp.aConstant,
            1,
            0,
            TypedOp.bReload,
            0,
            0,
            TypedOp.bReturn,
          ],
          integers: [0x7fffffffffffffff, 0],
          intSpills: 1,
        ),
      ),
      -0x8000000000000000,
    );
  });
  test('double values remain double across arithmetic and typed spills', () {
    expect(
      TypedMachine.run(
        program(
          [
            TypedOp.fConstant,
            0,
            0,
            TypedOp.gConstant,
            1,
            0,
            TypedOp.gSubF,
            TypedOp.gSpill,
            0,
            0,
            TypedOp.fReload,
            0,
            0,
            TypedOp.fReturn,
          ],
          doubles: [1.25, 0.5],
          doubleSpills: 1,
        ),
      ),
      -0.75,
    );
  });
  test('IEEE NaN and negative zero follow Dart double semantics', () {
    expect(
      TypedMachine.run(
        program(
          [
            TypedOp.fConstant,
            0,
            0,
            TypedOp.gConstant,
            1,
            0,
            TypedOp.eEqFG,
            TypedOp.eReturn,
          ],
          doubles: [double.nan, double.nan],
        ),
      ),
      false,
    );
    final result =
        TypedMachine.run(
              program(
                [
                  TypedOp.fConstant,
                  0,
                  0,
                  TypedOp.fSpill,
                  0,
                  0,
                  TypedOp.gReload,
                  0,
                  0,
                  TypedOp.gReturn,
                ],
                doubles: [-0.0],
                doubleSpills: 1,
              ),
            )
            as double;
    expect(result.isNegative, true);
  });
  test('boolean banks swap and spill independently', () {
    expect(
      TypedMachine.run(
        program([
          TypedOp.eTrue,
          TypedOp.xFalse,
          TypedOp.eXSwap,
          TypedOp.xSpill,
          0,
          0,
          TypedOp.eReload,
          0,
          0,
          TypedOp.eReturn,
        ], boolSpills: 1),
      ),
      true,
    );
  });
  test('typed argument banks do not alias', () {
    expect(
      TypedMachine.run(
        program(
          [
            TypedOp.gFromF,
            TypedOp.aSubB,
            TypedOp.fFromA,
            TypedOp.fAddG,
            TypedOp.fReturn,
          ],
          arguments: [
            TypedArgumentKind.integer,
            TypedArgumentKind.integer,
            TypedArgumentKind.doublePrecision,
          ],
        ),
        intArguments: [10, 2],
        doubleArguments: [0.5],
      ),
      8.5,
    );
    expect(
      TypedMachine.run(
        program([TypedOp.eReturn], arguments: [TypedArgumentKind.boolean]),
        boolArguments: [true],
      ),
      true,
    );
  });
  test('branches execute loop back edges without decoding objects', () {
    expect(
      TypedMachine.run(
        program(
          [
            TypedOp.bFromA,
            TypedOp.aConstant,
            0,
            0,
            TypedOp.aAddB,
            TypedOp.bDecrement,
            TypedOp.eBPositive,
            TypedOp.jumpETrue,
            4,
            0,
            0,
            0,
            TypedOp.aReturn,
          ],
          integers: [0],
          arguments: [TypedArgumentKind.integer],
        ),
        intArguments: [100],
      ),
      5050,
    );
  });
  test('typed division retains runtime failures', () {
    expect(
      () => TypedMachine.run(
        program(
          [
            TypedOp.aConstant,
            0,
            0,
            TypedOp.bConstant,
            1,
            0,
            TypedOp.aDivB,
            TypedOp.aReturn,
          ],
          integers: [1, 0],
        ),
      ),
      throwsA(isA<UnsupportedError>()),
    );
  });
  test('validation rejects truncated inputs and jumps into operand bytes', () {
    expect(() => program([TypedOp.aConstant, 0]), throwsFormatException);
    expect(() => program([TypedOp.jump, 1, 0, 0, 0]), throwsFormatException);
    expect(() => program([255]), throwsFormatException);
    expect(
      () => program([TypedOp.aSpill, 0, 0, TypedOp.aReturn]),
      throwsFormatException,
    );
    expect(() => program([TypedOp.eTrue]), throwsFormatException);
  });
  test('validated code and pools cannot be changed through caller aliases', () {
    final code = Uint8List.fromList([TypedOp.aConstant, 0, 0, TypedOp.aReturn]);
    final constants = [7];
    final compiled = TypedProgram(code, integers: constants);
    code[0] = 255;
    constants[0] = 99;
    expect(TypedMachine.run(compiled), 7);
    expect(() => compiled.code[0] = 255, throwsUnsupportedError);
  });
}
