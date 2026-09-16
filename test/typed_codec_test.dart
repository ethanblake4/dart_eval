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
  test(
    'closure signatures and ordered calls round trip with immutable defaults',
    () {
      final names = ['z', 'a'];
      final defaults = <Object?>[null, -0.0];
      final descriptor = TypedClosureDescriptor(
        1,
        captureCount: 1,
        positionalCount: 2,
        requiredPositional: 1,
        positionalDefaults: defaults,
        namedNames: names,
        requiredNamed: ['z'],
        namedDefaults: [null, 'value'],
      );
      names.clear();
      defaults.clear();
      final p = TypedProgram(
        Uint8List.fromList([TypedOp.rReturn, TypedOp.rReturn]),
        functions: [
          const TypedFunction(0),
          TypedFunction(
            1,
            argumentKinds: List.filled(5, TypedArgumentKind.object),
            resultKind: TypedArgumentKind.object,
          ),
        ],
        closures: [descriptor],
        closureCalls: [
          TypedClosureCall(1, namedNames: ['a', 'z']),
        ],
      );
      final restored = TypedProgram.read(p.write().buffer);
      final closure = restored.closures.single;
      expect(closure.namedNames, ['z', 'a']);
      expect(closure.requiredNamed, ['z']);
      expect((closure.positionalDefaults[1] as double).isNegative, isTrue);
      expect(closure.namedDefaults, [null, 'value']);
      expect(restored.closureCalls.single.namedNames, ['a', 'z']);
      expect(restored.closureCalls.single.overflowCount, 2);
      expect(() => closure.namedNames.clear(), throwsUnsupportedError);
      expect(() => closure.positionalDefaults.clear(), throwsUnsupportedError);
      expect(() => restored.closures.clear(), throwsUnsupportedError);
    },
  );
  test(
    'closure descriptors validate signatures, flags, names and defaults',
    () {
      final function = TypedFunction(
        0,
        argumentKinds: [TypedArgumentKind.object],
      );
      for (final descriptor in [
        TypedClosureDescriptor(
          1,
          captureCount: 0,
          positionalCount: 0,
          requiredPositional: 0,
        ),
        TypedClosureDescriptor(
          0,
          captureCount: 0,
          positionalCount: 0,
          requiredPositional: 0,
          boundReceiver: true,
        ),
        TypedClosureDescriptor(
          0,
          captureCount: -1,
          positionalCount: 0,
          requiredPositional: 0,
        ),
        TypedClosureDescriptor(
          0,
          captureCount: 0,
          positionalCount: 1,
          requiredPositional: 0,
        ),
        TypedClosureDescriptor(
          0,
          captureCount: 0,
          positionalCount: 0,
          requiredPositional: 0,
          requiredNamed: ['missing'],
        ),
        TypedClosureDescriptor(
          0,
          captureCount: 0,
          positionalCount: 0,
          requiredPositional: 0,
          namedNames: ['x', 'x'],
          namedDefaults: [null, null],
        ),
        TypedClosureDescriptor(
          0,
          captureCount: 0,
          positionalCount: 0,
          requiredPositional: 0,
          namedNames: ['x'],
          namedDefaults: [<int>[]],
        ),
      ]) {
        expect(
          () => TypedProgram(
            Uint8List.fromList([TypedOp.rReturn]),
            functions: [function],
            closures: [descriptor],
          ),
          throwsFormatException,
        );
      }
      expect(
        () => TypedProgram(
          Uint8List.fromList([TypedOp.rReturn]),
          closureCalls: [
            TypedClosureCall(0, namedNames: ['x', 'x']),
          ],
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'closure instructions check capture ownership and outgoing capacity',
    () {
      final descriptor = TypedClosureDescriptor(
        1,
        captureCount: 1,
        positionalCount: 0,
        requiredPositional: 0,
      );
      final code = Uint8List.fromList([
        TypedOp.rCreateClosure,
        0,
        0,
        TypedOp.rReturn,
        TypedOp.rLoadCapture,
        0,
        0,
        TypedOp.rReturn,
      ]);
      final target = const TypedFunction(
        4,
        argumentKinds: [TypedArgumentKind.object],
      );
      final p = TypedProgram(
        code,
        functions: [const TypedFunction(0, objectOutgoingCount: 1), target],
        closures: [descriptor],
      );
      expect(TypedProgram.read(p.write().buffer).code, code);
      expect(
        () => TypedProgram(
          code,
          functions: [const TypedFunction(0), target],
          closures: [descriptor],
        ),
        throwsFormatException,
      );
      final badCapture = Uint8List.fromList(code)..[5] = 1;
      expect(
        () => TypedProgram(
          badCapture,
          functions: p.functions,
          closures: [descriptor],
        ),
        throwsFormatException,
      );
      expect(
        () => TypedProgram(
          code,
          functions: p.functions,
          closures: [
            descriptor,
            TypedClosureDescriptor(
              1,
              captureCount: 2,
              positionalCount: 0,
              requiredPositional: 0,
            ),
          ],
        ),
        throwsFormatException,
      );
      expect(
        () => TypedProgram(
          Uint8List.fromList([TypedOp.rLoadCapture, 0, 0, TypedOp.rReturn]),
        ),
        throwsFormatException,
      );
      final callCode = Uint8List.fromList([
        TypedOp.callClosure,
        0,
        0,
        TypedOp.rReturn,
      ]);
      expect(() => TypedProgram(callCode), throwsFormatException);
      expect(
        () => TypedProgram(callCode, closureCalls: [TypedClosureCall(3)]),
        throwsFormatException,
      );
      expect(
        TypedProgram(
          callCode,
          functions: const [TypedFunction(0, objectOutgoingCount: 2)],
          closureCalls: [TypedClosureCall(3)],
        ).closureCalls.single.argumentCount,
        3,
      );
    },
  );
  test('closure codec bounds counts, flags and default payloads', () {
    final p = TypedProgram(
      Uint8List.fromList([TypedOp.rReturn]),
      functions: const [
        TypedFunction(0, argumentKinds: [TypedArgumentKind.object]),
      ],
      closures: [
        TypedClosureDescriptor(
          0,
          captureCount: 0,
          positionalCount: 0,
          requiredPositional: 0,
        ),
      ],
    );
    final bytes = p.write().buffer.asUint8List();
    // One argument puts descriptor metadata at 68 + 29 + 1 = 98.
    for (final (offset, value) in [
      (56, 65537),
      (60, 65537),
      (98, 1),
      (114, 3),
      (118, 0xffffffff),
      (126, 0xffffffff),
    ]) {
      final bad = Uint8List.fromList(bytes);
      ByteData.sublistView(bad).setUint32(offset, value, Endian.little);
      expect(() => TypedProgram.read(bad.buffer), throwsFormatException);
    }
  });

  test('external call descriptors round trip and keep the table immutable', () {
    final calls = [const TypedExternalCall(0xffffffff, 4)];
    final p = TypedProgram(
      Uint8List.fromList([TypedOp.callExternal, 0, 0, TypedOp.rReturn]),
      functions: const [TypedFunction(0, objectOutgoingCount: 2)],
      externalCalls: calls,
    );
    calls.clear();
    expect(p.externalCalls.single.externalFunctionId, 0xffffffff);
    expect(() => p.externalCalls.clear(), throwsUnsupportedError);
    final restored = TypedProgram.read(p.write().buffer);
    expect(restored.externalCalls.single.externalFunctionId, 0xffffffff);
    expect(restored.externalCalls.single.argumentCount, 4);
    expect(restored.externalCalls.single.overflowCount, 2);
    expect(restored.code, p.code);
  });
  test(
    'external calls validate IDs, counts, table references and overflow',
    () {
      final code = Uint8List.fromList([
        TypedOp.callExternal,
        0,
        0,
        TypedOp.rReturn,
      ]);
      for (final count in [0, 1, 2, 3]) {
        expect(
          TypedProgram(
            code,
            externalCalls: [TypedExternalCall(0, count)],
          ).externalCalls.single.overflowCount,
          0,
        );
      }
      expect(() => TypedProgram(code), throwsFormatException);
      expect(
        () =>
            TypedProgram(code, externalCalls: [const TypedExternalCall(0, 4)]),
        throwsFormatException,
      );
      for (final call in [
        const TypedExternalCall(-1, 0),
        const TypedExternalCall(0x100000000, 0),
        const TypedExternalCall(0, -1),
        const TypedExternalCall(0, 65539),
      ]) {
        expect(
          () => TypedProgram(code, externalCalls: [call]),
          throwsFormatException,
        );
      }
      final bytes = TypedProgram(
        Uint8List.fromList([TypedOp.rReturn]),
        externalCalls: const [TypedExternalCall(0, 4)],
      ).write().buffer.asUint8List();
      // Metadata follows the 68-byte header and 29-byte function layout.
      final badArguments = Uint8List.fromList(bytes);
      ByteData.sublistView(badArguments).setUint32(101, 65539, Endian.little);
      expect(
        () => TypedProgram.read(badArguments.buffer),
        throwsFormatException,
      );
      final badCount = Uint8List.fromList(bytes);
      ByteData.sublistView(badCount).setUint32(52, 65537, Endian.little);
      expect(() => TypedProgram.read(badCount.buffer), throwsFormatException);
      final missingDescriptor = Uint8List.fromList(bytes);
      ByteData.sublistView(missingDescriptor).setUint32(52, 2, Endian.little);
      expect(
        () => TypedProgram.read(missingDescriptor.buffer),
        throwsFormatException,
      );
    },
  );
  test('export signatures preserve defaults and freeze named parameters', () {
    final parameters = [
      const TypedExportParameter(
        'count',
        isRequired: true,
        nullable: false,
        typeName: 'int',
        typeLibrary: 'dart:core',
      ),
      const TypedExportParameter(
        'label',
        isRequired: false,
        nullable: false,
        typeName: 'String',
        typeLibrary: 'dart:core',
        defaultValue: 'hello \ud800',
      ),
      const TypedExportParameter(
        'ratio',
        isRequired: false,
        nullable: false,
        typeName: 'double',
        typeLibrary: 'dart:core',
        defaultValue: -0.0,
      ),
      const TypedExportParameter(
        'enabled',
        isRequired: false,
        nullable: false,
        typeName: 'bool',
        typeLibrary: 'dart:core',
        defaultValue: true,
      ),
      const TypedExportParameter(
        'other',
        isRequired: false,
        nullable: true,
        typeName: 'Counter',
        typeLibrary: 'package:test/main.dart',
      ),
    ];
    final exports = [
      TypedExport('package:test/main.dart', 'main', 0, parameters: parameters),
    ];
    final p = TypedProgram(
      Uint8List.fromList([TypedOp.returnNull]),
      exports: exports,
      functions: const [
        TypedFunction(
          0,
          resultKind: null,
          argumentKinds: [
            TypedArgumentKind.integer,
            TypedArgumentKind.string,
            TypedArgumentKind.doublePrecision,
            TypedArgumentKind.boolean,
            TypedArgumentKind.object,
          ],
        ),
      ],
    );
    parameters.clear();
    exports.clear();
    final restored = TypedProgram.read(p.write().buffer);
    final declaration = restored.exports.single;
    expect(declaration.library, 'package:test/main.dart');
    expect(declaration.name, 'main');
    expect(declaration.functionId, 0);
    expect(
      declaration.parameters.map(
        (p) => (p.name, p.isRequired, p.nullable, p.typeName, p.typeLibrary),
      ),
      p.exports.single.parameters.map(
        (p) => (p.name, p.isRequired, p.nullable, p.typeName, p.typeLibrary),
      ),
    );
    expect(declaration.parameters[1].defaultValue, 'hello \ud800');
    expect(
      (declaration.parameters[2].defaultValue as double).isNegative,
      isTrue,
    );
    expect(declaration.parameters[3].defaultValue, isTrue);
    expect(declaration.parameters[4].defaultValue, isNull);
    expect(() => declaration.parameters.clear(), throwsUnsupportedError);
    expect(() => restored.exports.clear(), throwsUnsupportedError);
  });

  test(
    'export validation rejects ambiguous names and malformed signatures',
    () {
      const parameter = TypedExportParameter(
        'value',
        isRequired: true,
        nullable: false,
        typeName: 'int',
        typeLibrary: 'dart:core',
      );
      TypedProgram program(List<TypedExport> exports) => TypedProgram(
        Uint8List.fromList([TypedOp.returnNull]),
        exports: exports,
        functions: const [
          TypedFunction(0, argumentKinds: [TypedArgumentKind.integer]),
        ],
      );
      final valid = TypedExport('test', 'main', 0, parameters: [parameter]);
      for (final exports in [
        [valid, valid],
        [
          TypedExport('test', 'main', 1, parameters: [parameter]),
        ],
        [TypedExport('test', 'main', 0, parameters: [])],
      ]) {
        expect(() => program(exports), throwsFormatException);
      }
      expect(
        () => TypedProgram(
          Uint8List.fromList([TypedOp.returnNull]),
          functions: const [
            TypedFunction(
              0,
              argumentKinds: [
                TypedArgumentKind.integer,
                TypedArgumentKind.integer,
              ],
            ),
          ],
          exports: [
            TypedExport('test', 'main', 0, parameters: [parameter, parameter]),
          ],
        ),
        throwsFormatException,
      );
      expect(
        () => program([
          TypedExport(
            'test',
            'main',
            0,
            parameters: [
              TypedExportParameter(
                'value',
                isRequired: false,
                nullable: false,
                typeName: 'int',
                typeLibrary: 'dart:core',
                defaultValue: [],
              ),
            ],
          ),
        ]),
        throwsFormatException,
      );
    },
  );

  test('export metadata rejects incompatible scalar and nullable banks', () {
    for (final kind in TypedArgumentKind.values.where(
      (k) => k != TypedArgumentKind.object,
    )) {
      final name = switch (kind) {
        TypedArgumentKind.integer => 'int',
        TypedArgumentKind.doublePrecision => 'double',
        TypedArgumentKind.boolean => 'bool',
        TypedArgumentKind.string => 'String',
        TypedArgumentKind.object => 'Object',
      };
      for (final parameter in [
        TypedExportParameter(
          'p',
          isRequired: true,
          nullable: true,
          typeName: name,
          typeLibrary: 'dart:core',
        ),
        TypedExportParameter(
          'p',
          isRequired: true,
          nullable: false,
          typeName: 'Object',
          typeLibrary: 'dart:core',
        ),
        TypedExportParameter(
          'p',
          isRequired: true,
          nullable: false,
          typeName: name,
          typeLibrary: 'package:other/main.dart',
        ),
      ]) {
        expect(
          () => TypedProgram(
            Uint8List.fromList([TypedOp.returnNull]),
            functions: [
              TypedFunction(0, argumentKinds: [kind]),
            ],
            exports: [
              TypedExport('test', 'f', 0, parameters: [parameter]),
            ],
          ),
          throwsFormatException,
        );
      }
    }
  });

  test('export codec bounds counts, strings, flags and default payloads', () {
    final p = TypedProgram(
      Uint8List.fromList([TypedOp.returnNull]),
      functions: const [
        TypedFunction(0, argumentKinds: [TypedArgumentKind.integer]),
      ],
      exports: [
        TypedExport(
          'l',
          'f',
          0,
          parameters: [
            const TypedExportParameter(
              'p',
              isRequired: false,
              nullable: false,
              typeName: 'int',
              typeLibrary: 'dart:core',
              defaultValue: 42,
            ),
          ],
        ),
      ],
    );
    final bytes = p.write().buffer.asUint8List();
    // Metadata begins after the 68-byte header, 29-byte layout and one argument.
    const metadata = 98;
    for (final offset in [
      48,
      metadata,
      metadata + 12,
      metadata + 16,
      metadata + 20,
      metadata + 26,
      metadata + 62,
    ]) {
      final bad = Uint8List.fromList(bytes);
      ByteData.sublistView(bad).setUint32(offset, 0xffffffff, Endian.little);
      expect(() => TypedProgram.read(bad.buffer), throwsFormatException);
    }
    final oldVersion = Uint8List.fromList(bytes);
    ByteData.sublistView(oldVersion).setUint32(4, 106, Endian.little);
    expect(() => TypedProgram.read(oldVersion.buffer), throwsFormatException);
    for (var length = metadata; length < bytes.length; length++) {
      expect(
        () => TypedProgram.read(
          Uint8List.fromList(bytes.take(length).toList()).buffer,
        ),
        throwsFormatException,
      );
    }
  });

  test('codec preserves immutable classes, call sites and result kinds', () {
    final methods = <String, int>{'read': 0};
    final classes = [
      TypedClass(
        'Counter',
        library: 'package:test/counter.dart',
        valueCount: 2,
        methods: methods,
      ),
    ];
    final sites = [const TypedCallSite('read', argumentCount: 0)];
    final p = TypedProgram(
      Uint8List.fromList([TypedOp.rReturn]),
      classes: classes,
      callSites: sites,
      functions: const [
        TypedFunction(0, argumentKinds: [TypedArgumentKind.object]),
      ],
    );
    methods.clear();
    classes.clear();
    sites.clear();
    final restored = TypedProgram.read(p.write().buffer);
    expect(restored.classes.single.name, 'Counter');
    expect(restored.classes.single.library, 'package:test/counter.dart');
    expect(restored.classes.single.valueCount, 2);
    expect(restored.classes.single.methods, {'read': 0});
    expect(restored.callSites.single.name, 'read');
    expect(restored.callSites.single.argumentCount, 0);
    expect(restored.callSites.single.kind, TypedMemberKind.method);
    expect(restored.functions.single.resultKind, TypedArgumentKind.object);
    expect(
      () => restored.classes.single.methods.clear(),
      throwsUnsupportedError,
    );
    expect(() => restored.callSites.clear(), throwsUnsupportedError);
    final voidProgram = TypedProgram(
      Uint8List.fromList([TypedOp.rReturn]),
      functions: const [TypedFunction(0, resultKind: null)],
    );
    expect(
      TypedProgram.read(voidProgram.write().buffer).functions.single.resultKind,
      isNull,
    );
  });

  test('validator rejects malformed class and call site signatures', () {
    TypedProgram program({
      List<TypedClass> classes = const [],
      List<TypedCallSite> sites = const [],
      List<TypedArgumentKind> args = const [TypedArgumentKind.object],
      TypedArgumentKind? result = TypedArgumentKind.object,
    }) => TypedProgram(
      Uint8List.fromList([TypedOp.rReturn]),
      classes: classes,
      callSites: sites,
      functions: [TypedFunction(0, argumentKinds: args, resultKind: result)],
    );
    for (final type in [
      TypedClass('C', library: 'test', valueCount: -1),
      TypedClass('C', library: 'test', valueCount: 65537),
      TypedClass('C', library: 'test', valueCount: 0, methods: {'m': 1}),
      TypedClass('C', library: 'test', valueCount: 0, setters: {'m': 0}),
    ]) {
      expect(() => program(classes: [type]), throwsFormatException);
    }
    final type = TypedClass(
      'C',
      library: 'test',
      valueCount: 0,
      methods: {'m': 0},
    );
    expect(
      () => program(classes: [type], args: [TypedArgumentKind.integer]),
      throwsFormatException,
    );
    expect(
      () => program(
        sites: [
          const TypedCallSite(
            'm',
            argumentCount: 1,
            kind: TypedMemberKind.getter,
          ),
        ],
      ),
      throwsFormatException,
    );
  });

  test(
    'unrelated classes may use the same member name with different arity',
    () {
      final p = TypedProgram(
        Uint8List.fromList([TypedOp.rReturn, TypedOp.rReturn]),
        classes: [
          TypedClass(
            'One',
            library: 'test',
            valueCount: 0,
            methods: {'foo': 0},
          ),
          TypedClass(
            'Two',
            library: 'test',
            valueCount: 0,
            methods: {'foo': 1},
          ),
        ],
        callSites: const [
          TypedCallSite('foo', argumentCount: 0),
          TypedCallSite('foo', argumentCount: 1),
        ],
        functions: const [
          TypedFunction(0, argumentKinds: [TypedArgumentKind.object]),
          TypedFunction(
            1,
            argumentKinds: [TypedArgumentKind.object, TypedArgumentKind.object],
          ),
        ],
      );
      expect(TypedProgram.read(p.write().buffer).callSites.length, 2);
    },
  );

  test('class instructions validate indices and member outgoing storage', () {
    TypedProgram program(int opcode, int index, {int outgoing = 0}) =>
        TypedProgram(
          Uint8List.fromList([opcode, index, 0, TypedOp.rReturn]),
          classes: [TypedClass('C', library: 'test', valueCount: 1)],
          callSites: const [TypedCallSite('foo', argumentCount: 3)],
          functions: [TypedFunction(0, objectOutgoingCount: outgoing)],
        );
    for (final opcode in [
      TypedOp.rCreateClassR,
      TypedOp.rLoadPropertyR,
      TypedOp.setPropertyRS,
      TypedOp.callVirtual,
    ]) {
      expect(() => program(opcode, 1), throwsFormatException);
    }
    expect(
      () => program(TypedOp.callVirtual, 0, outgoing: 1),
      throwsFormatException,
    );
    expect(program(TypedOp.callVirtual, 0, outgoing: 2).callSites.length, 1);
  });

  test(
    'codec bounds class metadata before allocation and validates result tags',
    () {
      final bytes = TypedProgram(
        Uint8List.fromList([TypedOp.rReturn]),
        classes: [TypedClass('C', library: 'test', valueCount: 0)],
      ).write().buffer.asUint8List();
      for (final offset in [36, 40, 44, 48, 52, 56, 60, 64, 97]) {
        final bad = Uint8List.fromList(bytes);
        ByteData.sublistView(bad).setUint32(offset, 0xffffffff, Endian.little);
        expect(() => TypedProgram.read(bad.buffer), throwsFormatException);
      }
      final badResult = Uint8List.fromList(bytes)..[96] = 254;
      expect(() => TypedProgram.read(badResult.buffer), throwsFormatException);
      for (var length = 68; length < bytes.length; length++) {
        expect(
          () => TypedProgram.read(
            Uint8List.fromList(bytes.take(length).toList()).buffer,
          ),
          throwsFormatException,
        );
      }
    },
  );

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
    final badKind = Uint8List.fromList(bytes)..[97] = 255;
    expect(() => TypedProgram.read(badKind.buffer), throwsFormatException);
    final badCount = Uint8List.fromList(bytes);
    ByteData.sublistView(badCount).setUint32(92, 2, Endian.little);
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
    // The object pool follows the 68-byte header and 29-byte function layout.
    final badTag = Uint8List.fromList(bytes)..[97] = 255;
    expect(() => TypedProgram.read(badTag.buffer), throwsFormatException);
    final badString = Uint8List.fromList(bytes);
    ByteData.sublistView(badString).setUint32(98, 0xffffffff, Endian.little);
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
