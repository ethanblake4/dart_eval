import 'dart:typed_data';

import 'typed_ops.g.dart';
import 'typed_function.dart';
import 'typed_codec.dart';

/// Validated immutable bytecode for the typed-bank execution loop.
class TypedProgram {
  TypedProgram(
    Uint8List code, {
    List<int> integers = const [],
    List<double> doubles = const [],
    List<Object?> objects = const [],
    int intSpillCount = 0,
    int doubleSpillCount = 0,
    int boolSpillCount = 0,
    int objectSpillCount = 0,
    List<TypedFunction>? functions,
    this.entryFunction = 0,
  }) : code = Uint8List.fromList(code).asUnmodifiableView(),
       functions = List.unmodifiable(
         functions ??
             [
               TypedFunction(
                 0,
                 intSpillCount: intSpillCount,
                 doubleSpillCount: doubleSpillCount,
                 boolSpillCount: boolSpillCount,
                 objectSpillCount: objectSpillCount,
                 intArgumentCount: _argumentCount(
                   code,
                   TypedImmediate.intArgument,
                 ),
                 doubleArgumentCount: _argumentCount(
                   code,
                   TypedImmediate.doubleArgument,
                 ),
                 objectArgumentCount: _argumentCount(
                   code,
                   TypedImmediate.objectArgument,
                 ),
                 boolArgumentCount: _argumentCount(
                   code,
                   TypedImmediate.boolArgument,
                 ),
               ),
             ],
       ),
       integers = Int64List.fromList(integers).asUnmodifiableView(),
       doubles = Float64List.fromList(doubles).asUnmodifiableView(),
       objects = List<Object?>.unmodifiable(objects) {
    _validate();
  }

  final Uint8List code;
  final Int64List integers;
  final Float64List doubles;
  // Keep pool bases and per-access bounds metadata out of the dispatch loop's
  // live register set. Numeric returns retain their declared representation.
  @pragma('vm:never-inline')
  int integerAt(int index) => integers[index];
  @pragma('vm:never-inline')
  double doubleAt(int index) => doubles[index];
  @pragma('vm:never-inline')
  Object? objectAt(int index) => objects[index];

  /// The pool is immutable; referenced objects retain their identity and state.
  final List<Object?> objects;
  int get intSpillCount => functions[entryFunction].intSpillCount;
  int get doubleSpillCount => functions[entryFunction].doubleSpillCount;
  int get boolSpillCount => functions[entryFunction].boolSpillCount;
  int get objectSpillCount => functions[entryFunction].objectSpillCount;
  final List<TypedFunction> functions;
  final int entryFunction;

  ByteData write() => TypedCodec.write(this);
  factory TypedProgram.read(ByteBuffer buffer) => TypedCodec.read(buffer);

  static int _argumentCount(Uint8List code, TypedImmediate kind) {
    var count = 0;
    for (var pc = 0; pc < code.length;) {
      if (code[pc] >= TypedOp.instructions.length) break;
      final instruction = TypedOp.instructions[code[pc]];
      if (pc + instruction.length > code.length) break;
      if (instruction.immediate == kind) {
        final needed = (code[pc + 1] | (code[pc + 2] << 8)) + 1;
        if (needed > count) count = needed;
      }
      pc += instruction.length;
    }
    return count;
  }

  void _validate() {
    if (functions.isEmpty ||
        functions.length > 65536 ||
        entryFunction < 0 ||
        entryFunction >= functions.length) {
      throw const FormatException('Invalid typed function table');
    }
    for (final count in functions.expand(
      (function) => function.layout.skip(1),
    )) {
      if (count < 0 || count > 65536) {
        throw ArgumentError.value(count, 'spillCount', 'Must fit a u16 index');
      }
    }
    if (code.isEmpty) throw const FormatException('Empty typed program');
    final boundaries = <int>{};
    final branches = <(int, int)>[];
    final ordered = functions.toList()
      ..sort((a, b) => a.entry.compareTo(b.entry));
    if (ordered.first.entry != 0 ||
        ordered.map((f) => f.entry).toSet().length != ordered.length) {
      throw const FormatException(
        'Function entries must be unique and begin at zero',
      );
    }
    var pc = 0;
    var functionIndex = 0;
    late TypedInstruction last;
    while (pc < code.length) {
      boundaries.add(pc);
      while (functionIndex + 1 < ordered.length &&
          pc >= ordered[functionIndex + 1].entry) {
        if (!last.terminates) {
          throw const FormatException(
            'Typed function can fall into next function',
          );
        }
        functionIndex++;
      }
      final function = ordered[functionIndex];
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
        branches.add((
          function.entry,
          code[pc + 1] |
              (code[pc + 2] << 8) |
              (code[pc + 3] << 16) |
              (code[pc + 4] << 24),
        ));
      } else if (last.immediate == TypedImmediate.shortBranch) {
        final encoded = code[pc + 1] | (code[pc + 2] << 8);
        final displacement = encoded >= 0x8000 ? encoded - 0x10000 : encoded;
        branches.add((function.entry, end + displacement));
      } else if (last.immediate != TypedImmediate.none) {
        final index = code[pc + 1] | (code[pc + 2] << 8);
        final limit = switch (last.immediate) {
          TypedImmediate.intConstant => integers.length,
          TypedImmediate.doubleConstant => doubles.length,
          TypedImmediate.objectConstant => objects.length,
          TypedImmediate.intSpill => function.intSpillCount,
          TypedImmediate.doubleSpill => function.doubleSpillCount,
          TypedImmediate.boolSpill => function.boolSpillCount,
          TypedImmediate.objectSpill => function.objectSpillCount,
          TypedImmediate.intOutgoing => function.intOutgoingCount,
          TypedImmediate.doubleOutgoing => function.doubleOutgoingCount,
          TypedImmediate.boolOutgoing => function.boolOutgoingCount,
          TypedImmediate.objectOutgoing => function.objectOutgoingCount,
          TypedImmediate.intArgument => function.intArgumentCount,
          TypedImmediate.doubleArgument => function.doubleArgumentCount,
          TypedImmediate.boolArgument => function.boolArgumentCount,
          TypedImmediate.objectArgument => function.objectArgumentCount,
          TypedImmediate.function => functions.length,
          _ => null,
        };
        if (limit != null && index >= limit) {
          throw FormatException(
            '${last.name} index $index exceeds $limit',
            code,
            pc,
          );
        }
        if (last.immediate == TypedImmediate.hostCall &&
            index > function.objectOutgoingCount) {
          throw const FormatException(
            'Insufficient outgoing object storage for host call',
          );
        }
        if (last.immediate == TypedImmediate.function) {
          final callee = functions[index];
          if (callee.intArgumentCount > function.intOutgoingCount ||
              callee.doubleArgumentCount > function.doubleOutgoingCount ||
              callee.boolArgumentCount > function.boolOutgoingCount ||
              callee.objectArgumentCount > function.objectOutgoingCount) {
            throw FormatException(
              'Insufficient outgoing argument storage for function $index',
            );
          }
        }
      }
      pc = end;
    }
    if (!last.terminates) {
      throw const FormatException('Typed program can fall off the end');
    }
    for (final function in functions) {
      if (!boundaries.contains(function.entry)) {
        throw FormatException(
          'Function entry ${function.entry} is not an instruction',
        );
      }
    }
    for (final (entry, address) in branches) {
      final owner = ordered.lastWhere(
        (f) => f.entry <= address,
        orElse: () => ordered.first,
      );
      if (!boundaries.contains(address) || owner.entry != entry) {
        throw FormatException('Branch target $address is not an instruction');
      }
    }
  }
}
