import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'nullable dead field accesses retain capacity without allocating classes',
    () {
      final compiler = Compiler()..entrypointFunctions['/main.dart'] = {'main'};
      final program = compiler.compile({
        'slot_capacity': {
          'main.dart': '''
class Ledger { late int id; late int value; }
bool main() {
  Ledger? entry;
  entry?..id = 1 ..value = entry.id + 4;
  return entry == null;
}
''',
        },
      });
      expect(program.typedProgram.classes, isEmpty);
      expect(program.typedProgram.fieldSlotCount, 2);
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:slot_capacity/main.dart', 'main'),
          true,
        );
      }
    },
  );

  test('codec preserves slot capacity and rejects invalid bounds', () {
    final code = Uint8List.fromList([
      TypedOp.rLoadPropertyR,
      1,
      0,
      TypedOp.rReturn,
    ]);
    final program = TypedProgram(code, fieldSlotCount: 2);
    final decoded = TypedProgram.read(program.write().buffer);
    expect(decoded.classes, isEmpty);
    expect(decoded.fieldSlotCount, 2);
    expect(() => TypedProgram(code, fieldSlotCount: 1), throwsFormatException);
    final bytes = program.write().buffer.asUint8List();
    final bad = Uint8List.fromList(bytes);
    // One empty function layout follows the fixed header before capacity.
    ByteData.sublistView(bad).setUint32(76 + 37, 65537, Endian.little);
    expect(() => TypedProgram.read(bad.buffer), throwsFormatException);
  });

  test(
    'version 140 uses allocated class layouts without slot capacity metadata',
    () {
      final program = TypedProgram(
        Uint8List.fromList([TypedOp.rLoadPropertyR, 1, 0, TypedOp.rReturn]),
        classes: [TypedClass('Ledger', library: 'test', valueCount: 2)],
      );
      final bytes = program.write().buffer.asUint8List();
      final data = ByteData.sublistView(bytes);
      final metadataLength = data.getUint32(44, Endian.little);
      final capacityOffset = 76 + 37 + metadataLength - 4;
      final legacy = Uint8List.fromList([
        ...bytes.take(capacityOffset),
        ...bytes.skip(capacityOffset + 4),
      ]);
      ByteData.sublistView(legacy)
        ..setUint32(4, 140, Endian.little)
        ..setUint32(44, metadataLength - 4, Endian.little);
      final decoded = TypedProgram.read(legacy.buffer);
      expect(decoded.fieldSlotCount, 0);
      expect(decoded.classes.single.valueCount, 2);
      expect(decoded.code, program.code);
    },
  );
}
