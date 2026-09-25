import 'dart:typed_data';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_codec.dart';
import 'package:test/test.dart';

void main() {
  test('global opcodes validate slot indices and physical banks', () {
    final operations = {
      TypedArgumentKind.integer: [TypedOp.aLoadGlobal, TypedOp.aSetGlobal],
      TypedArgumentKind.doublePrecision: [
        TypedOp.fLoadGlobal,
        TypedOp.fSetGlobal,
      ],
      TypedArgumentKind.boolean: [TypedOp.eLoadGlobal, TypedOp.eSetGlobal],
      TypedArgumentKind.object: [TypedOp.rLoadGlobal, TypedOp.rSetGlobal],
      TypedArgumentKind.string: [TypedOp.rLoadGlobal, TypedOp.rSetGlobal],
    };
    for (final entry in operations.entries) {
      for (final opcode in entry.value) {
        final code = Uint8List.fromList([opcode, 0, 0, TypedOp.returnNull]);
        final program = TypedProgram(
          code,
          globals: [TypedGlobal(kind: entry.key, isLate: true)],
        );
        expect(
          TypedProgram.read(program.write().buffer).globals.single.kind,
          entry.key,
        );
        expect(() => TypedProgram(code), throwsFormatException);
        final other = entry.key == TypedArgumentKind.integer
            ? TypedArgumentKind.object
            : TypedArgumentKind.integer;
        expect(
          () => TypedProgram(
            code,
            globals: [TypedGlobal(kind: other, isLate: true)],
          ),
          throwsFormatException,
        );
      }
    }
  });
  test(
    'global descriptors round trip every representation and storage flag',
    () {
      final globals = <TypedGlobal>[
        for (var i = 0; i < TypedArgumentKind.values.length; i++)
          TypedGlobal(
            initializerFunction: i,
            kind: TypedArgumentKind.values[i],
            isLate: i.isOdd,
            isFinal: i.isEven,
            name: 'global_$i',
          ),
        const TypedGlobal(),
        const TypedGlobal(
          kind: TypedArgumentKind.string,
          isLate: true,
          isFinal: true,
          name: 'late_name',
        ),
      ];
      final program = TypedProgram(
        Uint8List.fromList([
          TypedOp.aReturn,
          TypedOp.fReturn,
          TypedOp.eReturn,
          TypedOp.rReturn,
          TypedOp.rReturn,
        ]),
        functions: [
          for (var i = 0; i < 5; i++)
            TypedFunction(i, resultKind: TypedArgumentKind.values[i]),
        ],
        globals: globals,
      );
      globals.clear();
      expect(program.globals, hasLength(7));
      expect(
        () => program.globals.add(const TypedGlobal()),
        throwsUnsupportedError,
      );
      final bytes = program.write();
      expect(bytes.getUint32(4, Endian.little), 124);
      expect(bytes.getUint32(64, Endian.little), 7);
      final decoded = TypedProgram.read(bytes.buffer);
      expect(
        decoded.globals.map(
          (g) => (g.initializerFunction, g.kind, g.isLate, g.isFinal, g.name),
        ),
        program.globals.map(
          (g) => (g.initializerFunction, g.kind, g.isLate, g.isFinal, g.name),
        ),
      );
      expect(decoded.globals[5].initializerFunction, -1);
      expect(decoded.globals[5].kind, TypedArgumentKind.object);
    },
  );

  test(
    'global initializer indices, argument signatures and results are validated',
    () {
      TypedProgram make(
        TypedGlobal global, {
        TypedFunction function = const TypedFunction(0),
      }) => TypedProgram(
        Uint8List.fromList([TypedOp.rReturn]),
        functions: [function],
        globals: [global],
      );
      for (final index in [-2, 1, 0xffffffff]) {
        expect(
          () => make(TypedGlobal(initializerFunction: index)),
          throwsFormatException,
        );
      }
      expect(
        () => make(
          const TypedGlobal(initializerFunction: 0),
          function: const TypedFunction(
            0,
            argumentKinds: [TypedArgumentKind.object],
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => make(
          const TypedGlobal(initializerFunction: 0),
          function: const TypedFunction(0, resultKind: null),
        ),
        throwsFormatException,
      );
      expect(
        () => make(
          const TypedGlobal(
            initializerFunction: 0,
            kind: TypedArgumentKind.integer,
          ),
        ),
        throwsFormatException,
      );
      for (final kind in TypedArgumentKind.values.where(
        (kind) => kind != TypedArgumentKind.object,
      )) {
        expect(() => make(TypedGlobal(kind: kind)), throwsFormatException);
        expect(
          make(
            TypedGlobal(kind: kind, isLate: true),
          ).globals.single.initializerFunction,
          -1,
        );
      }
      expect(
        () => TypedProgram(
          Uint8List.fromList([TypedOp.rReturn]),
          globals: List.filled(65537, const TypedGlobal()),
        ),
        throwsFormatException,
      );
    },
  );

  test('codec rejects malformed global fields and truncated metadata', () {
    final bytes = TypedProgram(
      Uint8List.fromList([TypedOp.rReturn]),
      globals: const [TypedGlobal(name: 'state')],
    ).write().buffer.asUint8List();
    const global = 76 + 29;
    for (final (offset, value) in [
      (64, 65537),
      (global, 2),
      (global + 4, 255),
      (global + 8, 4),
      (global + 12, 0xffffffff),
    ]) {
      final corrupted = Uint8List.fromList(bytes);
      ByteData.sublistView(corrupted).setUint32(offset, value, Endian.little);
      expect(() => TypedProgram.read(corrupted.buffer), throwsFormatException);
    }
    for (var length = global; length < bytes.length; length++) {
      final truncated = Uint8List.fromList(bytes.take(length).toList());
      expect(() => TypedProgram.read(truncated.buffer), throwsFormatException);
    }
    expect(TypedCodec.version, 124);
  });
}
