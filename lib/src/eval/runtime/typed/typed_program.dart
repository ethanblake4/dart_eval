import 'dart:typed_data';

import 'typed_ops.g.dart';
import 'typed_class.dart';
import 'typed_call_site.dart';
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
    List<TypedClass> classes = const [],
    List<TypedCallSite> callSites = const [],
    this.entryFunction = 0,
  }) : code = Uint8List.fromList(code).asUnmodifiableView(),
       classes = List.unmodifiable(
         classes.map(
           (type) => TypedClass(
             type.name,
             library: type.library,
             valueCount: type.valueCount,
             methods: type.methods,
             getters: type.getters,
             setters: type.setters,
           ),
         ),
       ),
       callSites = List.unmodifiable(
         callSites.map(
           (site) => TypedCallSite(
             site.name,
             argumentCount: site.argumentCount,
             kind: site.kind,
           ),
         ),
       ),
       functions = List.unmodifiable(
         (functions ??
                 [
                   TypedFunction(
                     0,
                     intSpillCount: intSpillCount,
                     doubleSpillCount: doubleSpillCount,
                     boolSpillCount: boolSpillCount,
                     objectSpillCount: objectSpillCount,
                   ),
                 ])
             .map(
               (function) => TypedFunction(
                 function.entry,
                 intSpillCount: function.intSpillCount,
                 doubleSpillCount: function.doubleSpillCount,
                 boolSpillCount: function.boolSpillCount,
                 objectSpillCount: function.objectSpillCount,
                 argumentKinds: List.unmodifiable(function.argumentKinds),
                 resultKind: function.resultKind,
                 objectOutgoingCount: function.objectOutgoingCount,
               ),
             ),
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
  final List<TypedClass> classes;
  final List<TypedCallSite> callSites;
  final int entryFunction;

  ByteData write() => TypedCodec.write(this);
  factory TypedProgram.read(ByteBuffer buffer) => TypedCodec.read(buffer);

  void _validateClasses() {
    if (classes.length > 65536 || callSites.length > 65536) {
      throw const FormatException('Too many typed classes or call sites');
    }
    for (final type in classes) {
      if (type.valueCount < 0 || type.valueCount > 65536) {
        throw const FormatException('Invalid typed class field count');
      }
      for (final (kind, members) in [
        (TypedMemberKind.method, type.methods),
        (TypedMemberKind.getter, type.getters),
        (TypedMemberKind.setter, type.setters),
      ]) {
        for (final entry in members.entries) {
          if (entry.value < 0 || entry.value >= functions.length) {
            throw const FormatException('Invalid typed member function');
          }
          final function = functions[entry.value];
          if (function.argumentKinds.isEmpty ||
              function.argumentKinds.any(
                (kind) => kind != TypedArgumentKind.object,
              ) ||
              (kind == TypedMemberKind.getter &&
                  function.argumentKinds.length != 1) ||
              (kind == TypedMemberKind.setter &&
                  function.argumentKinds.length != 2)) {
            throw const FormatException('Invalid typed member signature');
          }
        }
      }
    }
    for (final site in callSites) {
      if (site.argumentCount < 0 ||
          site.argumentCount > 65537 ||
          (site.kind == TypedMemberKind.getter && site.argumentCount != 0) ||
          (site.kind == TypedMemberKind.setter && site.argumentCount != 1)) {
        throw const FormatException('Invalid typed call site signature');
      }
    }
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
    for (final function in functions) {
      if (function.argumentKinds.length > 65544 ||
          function.callLayout.overflowCount > 65536) {
        throw const FormatException('Too many typed function arguments');
      }
    }
    _validateClasses();
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
          TypedImmediate.objectOutgoing => function.objectOutgoingCount,
          TypedImmediate.overflow => function.callLayout.overflowCount,
          TypedImmediate.function => functions.length,
          TypedImmediate.classIndex => classes.length,
          TypedImmediate.callSite => callSites.length,
          TypedImmediate.field => classes.fold<int>(
            0,
            (n, type) => type.valueCount > n ? type.valueCount : n,
          ),
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
        if (last.immediate == TypedImmediate.callSite) {
          final site = callSites[index];
          final overflow = site.argumentCount > 2 ? site.argumentCount - 1 : 0;
          if (overflow > function.objectOutgoingCount) {
            throw const FormatException(
              'Insufficient outgoing storage for member call',
            );
          }
        }
        if (last.immediate == TypedImmediate.function) {
          final callee = functions[index];
          if (callee.callLayout.overflowCount > function.objectOutgoingCount) {
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
