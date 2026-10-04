import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('generated float lists preserve buffer views when serialized', () {
    final program = Compiler().compile({
      'example': {
        'main.dart': '''
          import 'dart:typed_data';

          int main() {
            final bytes = Uint8List(16);
            final float32 = bytes.buffer.asFloat32List(0, 1);
            final float64 = bytes.buffer.asFloat64List(8, 1);
            float32[0] = 1.5;
            float64[0] = 4294967297.25;

            final float32View = Float32List.view(bytes.buffer, 0, 1);
            final float64View = Float64List.view(bytes.buffer, 8, 1);
            if (float32View[0] != 1.5) return 1;
            if (float64View[0] != 4294967297.25) return 2;

            if (float32.lengthInBytes != 4 ||
                float32.offsetInBytes != 0 ||
                float32.elementSizeInBytes != 4 ||
                float32.buffer.lengthInBytes != 16) {
              return 3;
            }
            if (float64.lengthInBytes != 8 ||
                float64.offsetInBytes != 8 ||
                float64.elementSizeInBytes != 8 ||
                float64.buffer.lengthInBytes != 16) {
              return 4;
            }
            return 0;
          }
        ''',
      },
    });

    for (final (kind, candidate) in [
      ('fresh', program),
      ('serialized', Program.read(program.write().buffer)),
    ]) {
      final runtime = Runtime.ofProgram(candidate);
      expect(
        runtime.executeLib('package:example/main.dart', 'main'),
        0,
        reason: kind,
      );
    }
  });

  test(
    'generated typed lists preserve values and buffer views when serialized',
    () {
      final program = Compiler().compile({
        'example': {
          'main.dart': '''
          import 'dart:typed_data';

          int checkTypedData(
            TypedData value,
            int lengthInBytes,
            int offsetInBytes,
            int elementSizeInBytes,
          ) {
            if (value.lengthInBytes != lengthInBytes ||
                value.offsetInBytes != offsetInBytes ||
                value.elementSizeInBytes != elementSizeInBytes ||
                value.buffer.lengthInBytes != 16) {
              return 1;
            }
            return 0;
          }

          int main() {
            final bytes = Uint8List(16);
            final int32 = bytes.buffer.asInt32List(0, 1);
            final uint16 = bytes.buffer.asUint16List(4, 1);
            final int64 = bytes.buffer.asInt64List(8, 1);

            int32[0] = -2147483648;
            uint16[0] = 65537;
            int64[0] = 4294967297;

            final int32View = Int32List.view(bytes.buffer, 0, 1);
            final uint16View = Uint16List.view(bytes.buffer, 4, 1);
            final int64View = Int64List.view(bytes.buffer, 8, 1);

            if (int32View[0] != -2147483648) return 1;
            if (uint16View[0] != 1) return 2;
            if (int64View[0] != 4294967297) return 3;

            int32View[0] = 2147483647;
            if (int32[0] != 2147483647) return 4;

            if (checkTypedData(int32, 4, 0, 4) != 0) return 5;
            if (checkTypedData(uint16, 2, 4, 2) != 0) return 6;
            if (checkTypedData(int64, 8, 8, 8) != 0) return 7;
            return 0;
          }
        ''',
        },
      });

      for (final (kind, candidate) in [
        ('fresh', program),
        ('serialized', Program.read(program.write().buffer)),
      ]) {
        final runtime = Runtime.ofProgram(candidate);
        expect(
          runtime.executeLib('package:example/main.dart', 'main'),
          0,
          reason: kind,
        );
      }
    },
  );

  test('ByteData inherits TypedData properties', () {
    final runtime = Compiler().compileWriteAndLoad({
      'example': {
        'main.dart': '''
          import 'dart:typed_data';

          int main() {
            final data = ByteData(4);
            return data.buffer.lengthInBytes + data.offsetInBytes;
          }
        ''',
      },
    });
    expect(runtime.executeLib('package:example/main.dart', 'main'), 4);
  });

  test(
    'generated typed lists preserve narrow buffer views when serialized',
    () {
      final program = Compiler().compile({
        'example': {
          'main.dart': '''
          import 'dart:typed_data';

          int main() {
            final bytes = Uint8List(8);
            final int8 = bytes.buffer.asInt8List(0, 1);
            final int16 = bytes.buffer.asInt16List(2, 1);
            final clamped = bytes.buffer.asUint8ClampedList(4, 3);

            int8[0] = -128;
            int16[0] = -32768;
            clamped[0] = -1;
            clamped[1] = 256;
            clamped[2] = 42;

            final int8View = Int8List.view(bytes.buffer, 0, 1);
            final int16View = Int16List.view(bytes.buffer, 2, 1);
            final clampedView = Uint8ClampedList.view(bytes.buffer, 4, 3);
            if (int8View[0] != -128 || int16View[0] != -32768) return 1;
            if (clampedView[0] != 0 ||
                clampedView[1] != 255 ||
                clampedView[2] != 42) {
              return 2;
            }
            if (int8.lengthInBytes != 1 || int8.offsetInBytes != 0) return 3;
            if (int16.lengthInBytes != 2 || int16.offsetInBytes != 2) return 4;
            if (clamped.lengthInBytes != 3 || clamped.offsetInBytes != 4) {
              return 5;
            }
            return 0;
          }
        ''',
        },
      });

      for (final (kind, candidate) in [
        ('fresh', program),
        ('serialized', Program.read(program.write().buffer)),
      ]) {
        final runtime = Runtime.ofProgram(candidate);
        expect(
          runtime.executeLib('package:example/main.dart', 'main'),
          0,
          reason: kind,
        );
      }
    },
  );

  test('Endian constants bind to the SDK values when serialized', () {
    final program = Compiler().compile({
      'example': {
        'main.dart': '''
          import 'dart:typed_data';

          int main() {
            final data = ByteData(2);
            data.setInt16(0, 258, Endian.little);
            if (data.getUint8(0) != 2 || data.getUint8(1) != 1) return 1;
            data.setInt16(0, 258, Endian.big);
            if (data.getUint8(0) != 1 || data.getUint8(1) != 2) return 2;
            return Endian.host == Endian.little || Endian.host == Endian.big
                ? 0
                : 3;
          }
        ''',
      },
    });

    for (final (kind, candidate) in [
      ('fresh', program),
      ('serialized', Program.read(program.write().buffer)),
    ]) {
      final runtime = Runtime.ofProgram(candidate);
      expect(
        runtime.executeLib('package:example/main.dart', 'main'),
        0,
        reason: kind,
      );
    }
  });
}
