import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';
import 'package:dart_eval/src/eval/runtime/type.dart';
import 'package:test/test.dart';

Program fixture() => Program(
  {
    7: {'main': 3},
  },
  {
    7: {
      'Counter': [
        <String, int>{'value': 4},
        <String, int>{'value': 5},
        <String, int>{'increment': 6},
        2,
      ],
    },
  },
  {
    7: {'Counter': 2},
  },
  [
    {0},
    {0, 1},
    {0, 1, 2},
  ],
  [0, 1, -1, -0x80000000, 0x7fffffff],
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
  [
    RuntimeTypeSet(
      2,
      {0, 1, 2},
      [
        RuntimeTypeSet(1, {0, 1}, []),
      ],
    ),
  ],
  [3, 4],
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

class OffsetRuntime extends Runtime {
  OffsetRuntime.ofProgram(super.program) : super.ofProgram();
  OffsetRuntime.bytes(super.buffer);

  @override
  int execute(int entrypoint) => entrypoint;
}

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
    'round-trip preserves every metadata block and signed instruction word',
    () {
      final original = fixture();
      final encoded = original.write();
      final decoded = Program.read(encoded.buffer);
      expect(decoded.topLevelDeclarations, original.topLevelDeclarations);
      expect(decoded.instanceDeclarations, original.instanceDeclarations);
      expect(decoded.typeIds, original.typeIds);
      expect(decoded.typeTypes, original.typeTypes);
      expect(decoded.bridgeLibraryMappings, original.bridgeLibraryMappings);
      expect(decoded.bridgeFunctionMappings, original.bridgeFunctionMappings);
      expect(decoded.constantPool, original.constantPool);
      expect(
        decoded.runtimeTypes.map((type) => type.toJson()),
        original.runtimeTypes.map((type) => type.toJson()),
      );
      expect(decoded.globalInitializers, original.globalInitializers);
      expect(decoded.enumMappings, original.enumMappings);
      expect(decoded.overrideMap['override']!.offset, 3);
      expect(decoded.overrideMap['override']!.versionConstraint, '>=1.0.0');
      expect(decoded.overrideMap['unversioned']!.versionConstraint, isNull);
      expect(decoded.ops, original.ops);
      expect(decoded.write(), encoded);
    },
  );

  test(
    'in-memory and serialized runtime loading populate declarations and words',
    () {
      final original = fixture();
      for (final runtime in [
        OffsetRuntime.ofProgram(original),
        OffsetRuntime.bytes(original.write().buffer),
      ]) {
        expect(runtime.executeLib('package:codec/main.dart', 'main'), 3);
        expect(runtime.pr, original.ops);
        expect(runtime.typeIds, original.typeIds);
        expect(runtime.declaredClasses[7]!.keys, ['Counter']);
        expect(runtime.overrideMap['override']!.offset, 3);
      }
    },
  );

  test('empty instruction streams round-trip', () {
    final program = fixture()..ops = [];
    expect(Program.read(program.write().buffer).ops, isEmpty);
  });

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
    ByteData.sublistView(badCount).setInt32(badCount.length - 24, -1);
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

  test('writer rejects words outside signed 32-bit range', () {
    for (final word in [-0x80000001, 0x80000000]) {
      final program = fixture()..ops = [word];
      expect(program.write, throwsRangeError);
    }
  });
}
