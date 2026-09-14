import 'dart:typed_data';

import 'typed_ops.g.dart';

/// Validated immutable bytecode for the scalar-bank execution loop.
class TypedProgram {
  TypedProgram(
    Uint8List code, {
    List<int> integers = const [],
    List<double> doubles = const [],
    this.intSpillCount = 0,
    this.doubleSpillCount = 0,
    this.boolSpillCount = 0,
  }) : code = Uint8List.fromList(code).asUnmodifiableView(),
       integers = Int64List.fromList(integers).asUnmodifiableView(),
       doubles = Float64List.fromList(doubles).asUnmodifiableView() {
    _validate();
  }

  final Uint8List code;
  final Int64List integers;
  final Float64List doubles;
  final int intSpillCount;
  final int doubleSpillCount;
  final int boolSpillCount;

  void _validate() {
    for (final count in [intSpillCount, doubleSpillCount, boolSpillCount]) {
      if (count < 0 || count > 65536) {
        throw ArgumentError.value(count, 'spillCount', 'Must fit a u16 index');
      }
    }
    if (code.isEmpty) throw const FormatException('Empty typed program');
    final boundaries = <int>{};
    final branches = <int>[];
    var pc = 0;
    late TypedInstruction last;
    while (pc < code.length) {
      boundaries.add(pc);
      final opcode = code[pc];
      if (opcode >= TypedOp.instructions.length) {
        throw FormatException('Unknown typed opcode $opcode', code, pc);
      }
      last = TypedOp.instructions[opcode];
      final end = pc + last.length;
      if (end > code.length) {
        throw FormatException('Truncated ${last.name}', code, pc);
      }
      if (last.immediate == TypedImmediate.branch) {
        branches.add(
          code[pc + 1] |
              (code[pc + 2] << 8) |
              (code[pc + 3] << 16) |
              (code[pc + 4] << 24),
        );
      } else if (last.immediate != TypedImmediate.none) {
        final index = code[pc + 1] | (code[pc + 2] << 8);
        final limit = switch (last.immediate) {
          TypedImmediate.intConstant => integers.length,
          TypedImmediate.doubleConstant => doubles.length,
          TypedImmediate.intSpill => intSpillCount,
          TypedImmediate.doubleSpill => doubleSpillCount,
          TypedImmediate.boolSpill => boolSpillCount,
          _ => null,
        };
        if (limit != null && index >= limit) {
          throw FormatException(
            '${last.name} index $index exceeds $limit',
            code,
            pc,
          );
        }
      }
      pc = end;
    }
    if (!last.terminates) {
      throw const FormatException('Typed program can fall off the end');
    }
    for (final address in branches) {
      if (!boundaries.contains(address)) {
        throw FormatException('Branch target $address is not an instruction');
      }
    }
  }
}
