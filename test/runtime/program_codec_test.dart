import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';
import 'package:test/test.dart';

Program fixture() => Program(
  {
    7: {'Counter': 2},
  },
  [
    {0},
    {0, 1},
    {0, 1, 2},
  ],
  TypedProgram(
    Uint8List.fromList([TypedOp.aConstant, 0, 0, TypedOp.aReturn]),
    integers: [-9223372036854775808],
    functions: const [TypedFunction(0, resultKind: TypedArgumentKind.integer)],
    exports: [
      TypedExport('package:codec/main.dart', 'main', 0, parameters: []),
    ],
  ),
  {'package:codec/main.dart': 7},
  {
    7: {'external': 8},
  },
  [
    'héllo 🐢',
    123,
    1.25,
    true,
    <String, Object?>{
      'nested': [1, null, 'two'],
    },
  ],
  {
    7: {
      'Mode': {'active': 0},
    },
  },
  {
    'override': OverrideSpec(3, '>=1.0.0'),
    'unversioned': OverrideSpec(4, null),
  },
);

Program typedMetadataFixture(
  TypedProgram typed, {
  List<List<int>> descriptors = const [
    [0, 0],
  ],
  List<Object> constants = const [],
}) => Program(
  const {},
  [
    for (var i = 0; i < descriptors.length; i++) {i},
  ],
  typed,
  const {},
  const {},
  constants,
  const {},
  const {},
  typeDescriptors: descriptors,
);

Uint8List replaceFirstMetadata(Uint8List bytes, Object? metadata) {
  final originalLength = ByteData.sublistView(bytes).getInt32(5);
  final replacement = utf8.encode(jsonEncode(metadata));
  return (BytesBuilder()
        ..add(bytes.sublist(0, 5))
        ..add(
          (ByteData(4)..setInt32(0, replacement.length)).buffer.asUint8List(),
        )
        ..add(replacement)
        ..add(bytes.sublist(9 + originalLength)))
      .takeBytes();
}

void main() {
  test(
    'closure result type references are checked against envelope metadata',
    () {
      final typed = TypedProgram(
        Uint8List.fromList([TypedOp.returnNull]),
        functions: const [TypedFunction(0)],
        closures: [
          TypedClosureDescriptor(
            0,
            captureCount: 0,
            positionalCount: 0,
            requiredPositional: 0,
            hasEnvironment: false,
            runtimeTypeId: 1,
          ),
        ],
      );
      expect(() => typedMetadataFixture(typed), throwsFormatException);
      expect(
        () => typedMetadataFixture(typed, descriptors: const []),
        throwsFormatException,
      );
      final valid = typedMetadataFixture(
        typed,
        descriptors: const [
          [0, 0],
          [1, 0],
        ],
      );
      // Mutable public metadata can become invalid after initial construction;
      // decoding must apply the same check as fresh Program construction.
      valid.typeTypes.removeLast();
      valid.typeDescriptors = const [
        [0, 0],
      ];
      expect(() => Program.read(valid.write().buffer), throwsFormatException);
    },
  );

  test('export parameter type references are checked by the envelope', () {
    final typed = TypedProgram(
      Uint8List.fromList([TypedOp.returnNull]),
      functions: const [
        TypedFunction(0, argumentKinds: [TypedArgumentKind.object]),
      ],
      exports: [
        TypedExport(
          'test',
          'main',
          0,
          parameters: const [
            TypedExportParameter(
              'value',
              isRequired: true,
              nullable: false,
              typeName: 'Object',
              typeLibrary: 'dart:core',
              runtimeTypeId: 1,
            ),
          ],
        ),
      ],
    );
    expect(() => typedMetadataFixture(typed), throwsFormatException);

    final constructor = TypedProgram(
      Uint8List.fromList([TypedOp.returnNull]),
      functions: const [
        TypedFunction(0, argumentKinds: [TypedArgumentKind.integer]),
      ],
      exports: [
        TypedExport(
          'test',
          'Value.',
          0,
          generativeConstructorRuntimeTypeId: 1,
          parameters: const [],
        ),
      ],
    );
    expect(() => typedMetadataFixture(constructor), throwsFormatException);
  });

  test('runtime descriptor graphs and executable references are validated', () {
    expect(
      () => typedMetadataFixture(
        TypedProgram(Uint8List.fromList([TypedOp.returnNull])),
        descriptors: const [
          [0, 0, 1],
          [1, 0, 0],
        ],
      ),
      throwsFormatException,
    );
    expect(
      () => typedMetadataFixture(
        TypedProgram(
          Uint8List.fromList([TypedOp.returnNull]),
          callSites: const [
            TypedCallSite('call', argumentCount: 0, typeArguments: [1]),
          ],
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => typedMetadataFixture(
        TypedProgram(
          Uint8List.fromList([TypedOp.rBoxListTyped, 1, 0, TypedOp.returnNull]),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => typedMetadataFixture(
        TypedProgram(
          Uint8List.fromList([
            TypedOp.setCallTypeArguments,
            0,
            0,
            TypedOp.returnNull,
          ]),
        ),
        constants: const [
          <int>[1],
        ],
      ),
      throwsFormatException,
    );
  });

  test('structural descriptor names are strings, unique, and sorted', () {
    final typed = TypedProgram(Uint8List.fromList([TypedOp.returnNull]));
    void rejects(List<int> descriptor, List<Object> constants) {
      expect(
        () => typedMetadataFixture(
          typed,
          descriptors: [
            const [0, 0],
            descriptor,
          ],
          constants: constants,
        ),
        throwsFormatException,
      );
    }

    rejects(const [0, 0, -2, 0, 1, 0, 0], const [7]);
    rejects(const [0, 0, -2, 0, 2, 0, 0, 0, 0], const ['same']);
    rejects(const [0, 0, -2, 0, 2, 0, 0, 1, 0], const ['z', 'a']);
    rejects(const [0, 0, -1, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0], const ['z', 'a']);

    expect(
      () => typedMetadataFixture(
        typed,
        descriptors: const [
          [0, 0],
          [0, 0, -2, 0, 2, 0, 0, 1, 0],
        ],
        constants: const ['a', 'z'],
      ),
      returnsNormally,
    );

    final serialized = typedMetadataFixture(
      typed,
      descriptors: const [
        [0, 0],
        [0, 0, -2, 0, 2, 0, 0, 1, 0],
      ],
      constants: const ['a', 'z'],
    );
    serialized.typeDescriptors = const [
      [0, 0],
      [0, 0, -2, 0, 2, 1, 0, 0, 0],
    ];
    expect(
      () => Program.read(serialized.write().buffer),
      throwsFormatException,
    );
  });

  test(
    'round-trip preserves shared metadata and the typed executable payload',
    () {
      final original = fixture();
      final encoded = original.write();
      final decoded = Program.read(encoded.buffer);
      expect(decoded.typeIds, original.typeIds);
      expect(decoded.typeTypes, original.typeTypes);
      expect(decoded.bridgeLibraryMappings, original.bridgeLibraryMappings);
      expect(decoded.bridgeFunctionMappings, original.bridgeFunctionMappings);
      expect(decoded.constantPool, original.constantPool);
      expect(decoded.enumMappings, original.enumMappings);
      expect(decoded.overrideMap['override']!.offset, 3);
      expect(decoded.overrideMap['override']!.versionConstraint, '>=1.0.0');
      expect(decoded.overrideMap['unversioned']!.versionConstraint, isNull);
      expect(decoded.typedProgram.code, original.typedProgram.code);
      expect(decoded.typedProgram.integers, original.typedProgram.integers);
      expect(decoded.typedProgram.exports.single.name, 'main');
      expect(TypedMachine.run(decoded.typedProgram), -9223372036854775808);
      expect(decoded.write(), encoded);
    },
  );

  test('every truncated prefix is rejected with a format error', () {
    final encoded = fixture().write();
    for (var length = 0; length < encoded.length; length++) {
      expect(
        () => Program.read(
          Uint8List.fromList(encoded.take(length).toList()).buffer,
        ),
        throwsFormatException,
        reason: 'prefix length $length',
      );
    }
  });

  test('wrong magic and incompatible versions are rejected', () {
    final badMagic = fixture().write()..[0] = 0;
    expect(() => Program.read(badMagic.buffer), throwsFormatException);
    final badVersion = fixture().write();
    ByteData.sublistView(badVersion).setUint16(3, Runtime.versionCode - 1);
    expect(() => Program.read(badVersion.buffer), throwsFormatException);
  });

  test('negative or excessive lengths and trailing bytes are rejected', () {
    final negativeLength = fixture().write();
    ByteData.sublistView(negativeLength).setInt32(5, -1);
    expect(() => Program.read(negativeLength.buffer), throwsFormatException);
    final excessiveLength = fixture().write();
    ByteData.sublistView(excessiveLength).setInt32(5, 0x7fffffff);
    expect(() => Program.read(excessiveLength.buffer), throwsFormatException);
    final trailing = Uint8List.fromList([...fixture().write(), 0]);
    expect(() => Program.read(trailing.buffer), throwsFormatException);
    final badCount = fixture().write();
    final payloadOffset =
        badCount.length - fixture().typedProgram.write().lengthInBytes;
    ByteData.sublistView(badCount).setInt32(payloadOffset - 4, -1);
    expect(() => Program.read(badCount.buffer), throwsFormatException);
  });

  test('invalid metadata shape and integer values are rejected', () {
    for (final metadata in <Object?>[
      [],
      null,
      {
        '7': {'main': 'three'},
      },
      {
        'invalid': {'main': 3},
      },
    ]) {
      final encoded = replaceFirstMetadata(fixture().write(), metadata);
      expect(() => Program.read(encoded.buffer), throwsFormatException);
    }
    final invalidJson = fixture().write()..[9] = 0xff;
    expect(() => Program.read(invalidJson.buffer), throwsFormatException);
  });

  test('envelope rejects reference instruction payloads', () {
    final bytes = fixture().write();
    final payloadOffset =
        bytes.length - fixture().typedProgram.write().lengthInBytes;
    final invalid = BytesBuilder()
      ..add(bytes.sublist(0, payloadOffset - 4))
      ..add((ByteData(4)..setInt32(0, 4)).buffer.asUint8List())
      ..add([0, 0, 0, 0]);
    expect(
      () => Program.read(invalid.takeBytes().buffer),
      throwsFormatException,
    );
  });
}
