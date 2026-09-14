import 'dart:typed_data';

import 'typed_function.dart';
import 'typed_program.dart';

/// Versioned little-endian format, separate from the generic register format.
abstract final class TypedCodec {
  static const magic = 0x54564544; // DEVT
  static const version = 103;

  static ByteData write(TypedProgram program) {
    final objects = _writeObjects(program.objects);
    final result = ByteData(
      36 +
          program.functions.length * 52 +
          program.integers.length * 8 +
          program.doubles.length * 8 +
          objects.length +
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
    u32(program.objects.length);
    u32(objects.length);
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
    result.buffer.asUint8List(offset, objects.length).setAll(0, objects);
    offset += objects.length;
    result.buffer.asUint8List(offset).setAll(0, program.code);
    return result;
  }

  static TypedProgram read(ByteBuffer buffer) {
    final input = ByteData.view(buffer);
    if (input.lengthInBytes < 36) {
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
    final objectCount = u32(), objectLength = u32();
    final expected =
        36 +
        functionCount * 52 +
        integerCount * 8 +
        doubleCount * 8 +
        objectLength +
        codeLength;
    if (expected != input.lengthInBytes || objectCount > objectLength) {
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
          objectSpillCount: u32(),
          intArgumentCount: u32(),
          doubleArgumentCount: u32(),
          boolArgumentCount: u32(),
          objectArgumentCount: u32(),
          intOutgoingCount: u32(),
          doubleOutgoingCount: u32(),
          boolOutgoingCount: u32(),
          objectOutgoingCount: u32(),
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
    final objects = _readObjects(
      ByteData.view(buffer, offset, objectLength),
      objectCount,
    );
    offset += objectLength;
    return TypedProgram(
      buffer.asUint8List(offset, codeLength),
      integers: integers,
      doubles: doubles,
      objects: objects,
      functions: functions,
      entryFunction: entry,
    );
  }

  // Tags: null, false, true, int64, float64, UTF-16 string. Live objects
  // belong in runtime arguments; serializing them would lose their identity.
  static Uint8List _writeObjects(List<Object?> objects) {
    final bytes = BytesBuilder(copy: false);
    for (final value in objects) {
      switch (value) {
        case null:
          bytes.addByte(0);
        case bool():
          bytes.addByte(value ? 2 : 1);
        case int():
          bytes.addByte(3);
          final data = ByteData(8)..setInt64(0, value, Endian.little);
          bytes.add(data.buffer.asUint8List());
        case double():
          bytes.addByte(4);
          final data = ByteData(8)..setFloat64(0, value, Endian.little);
          bytes.add(data.buffer.asUint8List());
        case String():
          bytes.addByte(5);
          final data = ByteData(4 + value.length * 2)
            ..setUint32(0, value.length, Endian.little);
          for (var i = 0; i < value.length; i++) {
            data.setUint16(4 + i * 2, value.codeUnitAt(i), Endian.little);
          }
          bytes.add(data.buffer.asUint8List());
        default:
          throw UnsupportedError(
            'Typed bytecode cannot serialize ${value.runtimeType} object '
            'constants. Pass live objects through objectArguments instead.',
          );
      }
    }
    return bytes.takeBytes();
  }

  static List<Object?> _readObjects(ByteData input, int count) {
    var offset = 0;
    void require(int size) {
      if (size > input.lengthInBytes - offset) {
        throw const FormatException('Truncated typed object constant');
      }
    }

    final objects = <Object?>[];
    for (var i = 0; i < count; i++) {
      require(1);
      final tag = input.getUint8(offset++);
      switch (tag) {
        case 0:
          objects.add(null);
        case 1:
          objects.add(false);
        case 2:
          objects.add(true);
        case 3:
          require(8);
          objects.add(input.getInt64(offset, Endian.little));
          offset += 8;
        case 4:
          require(8);
          objects.add(input.getFloat64(offset, Endian.little));
          offset += 8;
        case 5:
          require(4);
          final length = input.getUint32(offset, Endian.little);
          offset += 4;
          require(length * 2);
          objects.add(
            String.fromCharCodes(
              List.generate(
                length,
                (i) => input.getUint16(offset + i * 2, Endian.little),
              ),
            ),
          );
          offset += length * 2;
        default:
          throw FormatException('Unknown typed object constant tag $tag');
      }
    }
    if (offset != input.lengthInBytes) {
      throw const FormatException('Invalid typed object section length');
    }
    return objects;
  }
}
