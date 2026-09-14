import 'dart:typed_data';

import 'typed_function.dart';
import 'typed_program.dart';

/// Versioned little-endian format, separate from the generic register format.
abstract final class TypedCodec {
  static const magic = 0x54564544; // DEVT
  static const version = 102;

  static ByteData write(TypedProgram program) {
    final result = ByteData(
      28 +
          program.functions.length * 40 +
          program.integers.length * 8 +
          program.doubles.length * 8 +
          program.code.length,
    );
    var offset = 0;
    void u32(int value) {
      result.setUint32(offset, value, Endian.little);
      offset += 4;
    }

    u32(magic);
    u32(version);
    u32(program.entryFunction);
    u32(program.functions.length);
    u32(program.integers.length);
    u32(program.doubles.length);
    u32(program.code.length);
    for (final function in program.functions) {
      for (final value in function.layout) {
        u32(value);
      }
    }
    for (final value in program.integers) {
      result.setInt64(offset, value, Endian.little);
      offset += 8;
    }
    for (final value in program.doubles) {
      result.setFloat64(offset, value, Endian.little);
      offset += 8;
    }
    result.buffer.asUint8List(offset).setAll(0, program.code);
    return result;
  }

  static TypedProgram read(ByteBuffer buffer) {
    final input = ByteData.view(buffer);
    if (input.lengthInBytes < 28) {
      throw const FormatException('Truncated typed program header');
    }
    var offset = 0;
    int u32() {
      final value = input.getUint32(offset, Endian.little);
      offset += 4;
      return value;
    }

    if (u32() != magic || u32() != version) {
      throw const FormatException('Unsupported typed bytecode format');
    }
    final entry = u32();
    final functionCount = u32(), integerCount = u32(), doubleCount = u32();
    final codeLength = u32();
    final expected =
        28 +
        functionCount * 40 +
        integerCount * 8 +
        doubleCount * 8 +
        codeLength;
    if (expected != input.lengthInBytes) {
      throw const FormatException('Invalid typed bytecode section lengths');
    }
    final functions = <TypedFunction>[];
    for (var i = 0; i < functionCount; i++) {
      functions.add(
        TypedFunction(
          u32(),
          intSpillCount: u32(),
          doubleSpillCount: u32(),
          boolSpillCount: u32(),
          intArgumentCount: u32(),
          doubleArgumentCount: u32(),
          boolArgumentCount: u32(),
          intOutgoingCount: u32(),
          doubleOutgoingCount: u32(),
          boolOutgoingCount: u32(),
        ),
      );
    }
    final integers = List.generate(integerCount, (_) {
      final value = input.getInt64(offset, Endian.little);
      offset += 8;
      return value;
    });
    final doubles = List.generate(doubleCount, (_) {
      final value = input.getFloat64(offset, Endian.little);
      offset += 8;
      return value;
    });
    return TypedProgram(
      buffer.asUint8List(offset, codeLength),
      integers: integers,
      doubles: doubles,
      functions: functions,
      entryFunction: entry,
    );
  }
}
