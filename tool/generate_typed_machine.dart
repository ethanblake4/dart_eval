import 'dart:io';

/// The sole instruction specification. Operand order, byte widths, register
/// dependencies and handler bodies are generated together from these entries.
class Instruction {
  const Instruction(
    this.name,
    this.body, {
    this.inputs = const [],
    this.output,
    this.immediate = 'none',
    this.mayThrow = false,
    this.terminates = false,
  });
  final String name;
  final String body;
  final List<int> inputs;
  final int? output;
  final String immediate;
  final bool mayThrow;
  final bool terminates;
}

List<Instruction> specification() {
  final ops = <Instruction>[];
  void add(
    String name,
    String body, {
    List<int> inputs = const [],
    int? output,
    String immediate = 'none',
    bool mayThrow = false,
    bool terminates = false,
  }) => ops.add(
    Instruction(
      name,
      body,
      inputs: inputs,
      output: output,
      immediate: immediate,
      mayThrow: mayThrow,
      terminates: terminates,
    ),
  );
  const names = ['a', 'b', 'f', 'g', 'e', 'x', 'r', 's', 'c'];
  for (var register = 0; register < names.length; register++) {
    final name = names[register];
    final bank = register < 2
        ? 'int'
        : register < 4
        ? 'double'
        : register < 6
        ? 'bool'
        : 'object';
    final pool = bank == 'int'
        ? 'program.integerAt'
        : bank == 'double'
        ? 'program.doubleAt'
        : 'program.objectAt';
    if (bank != 'bool') {
      add(
        '${name}Constant',
        '$name = $pool(index);',
        output: register,
        immediate: '${bank}Constant',
      );
    } else {
      add('${name}True', '$name = true;', output: register);
      add('${name}False', '$name = false;', output: register);
    }
    add(
      '${name}Spill',
      'frame.${bank}Spills[index] = ${bank == 'bool' ? '$name ? 1 : 0' : name};',
      inputs: [register],
      immediate: '${bank}Spill',
    );
    add(
      '${name}Reload',
      '$name = frame.${bank}Spills[index]${bank == 'bool' ? ' != 0' : ''};',
      output: register,
      immediate: '${bank}Spill',
    );
    final resultName = bank == 'int'
        ? 'a'
        : bank == 'double'
        ? 'f'
        : bank == 'bool'
        ? 'e'
        : 'r';
    add(
      '${name}Return',
      '''if (frame.parent == null) return ${bank == 'object' ? 'TypedInterop.exportExternal($name)' : name};
          final returned = $name;
          pc = frame.returnPc;
          frame = frame.leave();
          r = null; s = null; c = null;
          $resultName = returned;''',
      inputs: [register],
      terminates: true,
    );
  }
  for (final (first, second) in [
    (0, 1),
    (2, 3),
    (4, 5),
    (6, 7),
    (6, 8),
    (7, 8),
  ]) {
    final left = names[first], right = names[second];
    add(
      '${left}From${right.toUpperCase()}',
      '$left = $right;',
      inputs: [second],
      output: first,
    );
    add(
      '${right}From${left.toUpperCase()}',
      '$right = $left;',
      inputs: [first],
      output: second,
    );
    // Both writes are declared by a separate metadata field for exchange ops.
    add(
      '$left${right.toUpperCase()}Swap',
      'final temporary = $left; $left = $right; $right = temporary;',
      inputs: [first, second],
    );
  }
  const integerOperators = {
    'Add': '+',
    'Sub': '-',
    'Mul': '*',
    'Div': '~/',
    'Mod': '%',
    'And': '&',
    'Or': '|',
    'Xor': '^',
    'ShiftLeft': '<<',
    'ShiftRight': '>>',
    'UnsignedShiftRight': '>>>',
  };
  for (final entry in integerOperators.entries) {
    for (final (target, other) in [(0, 1), (1, 0)]) {
      final left = names[target], right = names[other];
      add(
        '$left${entry.key}${right.toUpperCase()}',
        '$left = $left ${entry.value} $right;',
        inputs: [target, other],
        output: target,
        mayThrow: {
          'Div',
          'Mod',
          'ShiftLeft',
          'ShiftRight',
          'UnsignedShiftRight',
        }.contains(entry.key),
      );
    }
  }
  for (final entry in {
    'Add': '+',
    'Sub': '-',
    'Mul': '*',
    'Div': '/',
  }.entries) {
    for (final (target, other) in [(2, 3), (3, 2)]) {
      final left = names[target], right = names[other];
      add(
        '$left${entry.key}${right.toUpperCase()}',
        '$left = $left ${entry.value} $right;',
        inputs: [target, other],
        output: target,
      );
    }
  }
  for (final target in [0, 1]) {
    final name = names[target];
    add(
      '${name}Immediate',
      '$name = index.toSigned(16);',
      output: target,
      immediate: 'integer',
    );
    add('${name}Increment', '$name++;', inputs: [target], output: target);
    add('${name}Decrement', '$name--;', inputs: [target], output: target);
    add('${name}Negate', '$name = -$name;', inputs: [target], output: target);
    add('${name}BitNot', '$name = ~$name;', inputs: [target], output: target);
  }
  for (final output in [4, 5]) {
    final result = names[output];
    for (final entry in {
      'Eq': '==',
      'Ne': '!=',
      'Lt': '<',
      'Lte': '<=',
      'Gt': '>',
      'Gte': '>=',
    }.entries) {
      for (final (left, right) in [(0, 1), (2, 3)]) {
        add(
          '$result${entry.key}${names[left].toUpperCase()}${names[right].toUpperCase()}',
          '$result = ${names[left]} ${entry.value} ${names[right]};',
          inputs: [left, right],
          output: output,
        );
      }
    }
    for (final input in [0, 1]) {
      add(
        '$result${names[input].toUpperCase()}Positive',
        '$result = ${names[input]} > 0;',
        inputs: [input],
        output: output,
      );
    }
    add(
      '${result}Not',
      '$result = !$result;',
      inputs: [output],
      output: output,
    );
    for (final entry in {'And': '&&', 'Or': '||', 'Xor': '!='}.entries) {
      final other = output == 4 ? 5 : 4;
      add(
        '$result${entry.key}${names[other].toUpperCase()}',
        '$result = $result ${entry.value} ${names[other]};',
        inputs: [output, other],
        output: output,
      );
    }
    add(
      'jump${result.toUpperCase()}True',
      'if ($result) pc = address;',
      inputs: [output],
      immediate: 'branch',
    );
    add(
      'jump${result.toUpperCase()}False',
      'if (!$result) pc = address;',
      inputs: [output],
      immediate: 'branch',
    );
  }
  for (final integer in [0, 1]) {
    for (final floating in [2, 3]) {
      add(
        '${names[floating]}From${names[integer].toUpperCase()}',
        '${names[floating]} = ${names[integer]}.toDouble();',
        inputs: [integer],
        output: floating,
      );
      add(
        '${names[integer]}From${names[floating].toUpperCase()}',
        '${names[integer]} = ${names[floating]}.toInt();',
        inputs: [floating],
        output: integer,
        mayThrow: true,
      );
    }
  }
  add('jump', 'pc = address;', immediate: 'branch', terminates: true);
  for (var register = 6; register < names.length; register++) {
    final name = names[register];
    add(
      '${name}Outgoing',
      'frame.objectOutgoing[index] = $name;',
      inputs: [register],
      immediate: 'objectOutgoing',
    );
  }
  add('cLoadOutgoing', 'c = frame.objectOutgoing;', output: 8);
  add(
    'rOverflow',
    'r = (c as List<Object?>)[index];',
    inputs: [8],
    output: 6,
    immediate: 'overflow',
    mayThrow: true,
  );
  add(
    'call',
    '''final function = program.functions[index];
          frame = frame.enter(function, pc);
          pc = function.entry;''',
    immediate: 'function',
    mayThrow: true,
  );
  for (final register in [6, 7, 8]) {
    final name = names[register];
    add('${name}Null', '$name = null;', output: register);
    for (final flag in [4, 5]) {
      add(
        '${names[flag]}IsNull${name.toUpperCase()}',
        '${names[flag]} = TypedInterop.isNull($name);',
        inputs: [register],
        output: flag,
      );
    }
  }
  for (final flag in [4, 5]) {
    add(
      '${names[flag]}EqRS',
      '${names[flag]} = TypedInterop.equals(runtime, r, s);',
      inputs: [6, 7],
      output: flag,
      mayThrow: true,
    );
  }
  for (var register = 0; register < 6; register++) {
    add(
      'rFrom${names[register].toUpperCase()}',
      'r = ${names[register]};',
      inputs: [register],
      output: 6,
    );
    final wrapper = register < 2
        ? r'$int'
        : register < 4
        ? r'$double'
        : r'$bool';
    add(
      'rBox${names[register].toUpperCase()}',
      'r = $wrapper(${names[register]});',
      inputs: [register],
      output: 6,
    );
  }
  for (final (register, type) in [(0, 'Int'), (2, 'Double'), (4, 'Bool')]) {
    add(
      '${names[register]}FromR',
      '${names[register]} = TypedInterop.to$type(r);',
      inputs: [6],
      output: register,
      mayThrow: true,
    );
    add(
      '${names[register]}NativeFromR',
      '${names[register]} = r as ${type.toLowerCase()};',
      inputs: [6],
      output: register,
      mayThrow: true,
    );
  }
  add(
    'rBoxString',
    r'r = $String(r as String);',
    inputs: [6],
    output: 6,
    mayThrow: true,
  );
  add(
    'rUnboxString',
    'r = TypedInterop.toStringValue(r);',
    inputs: [6],
    output: 6,
    mayThrow: true,
  );
  add(
    'callHost',
    'final result = TypedInterop.call(runtime, r, frame.takeObjectArguments(index)); r = result; s = null; c = null; ',
    inputs: [6],
    output: 6,
    immediate: 'hostCall',
    mayThrow: true,
  );
  add(
    'callMethod',
    'final result = TypedInterop.invoke(runtime, r, s as String, frame.takeObjectArguments(index)); r = result; s = null; c = null; ',
    inputs: [6, 7],
    output: 6,
    immediate: 'hostCall',
    mayThrow: true,
  );
  for (final op in [...ops]) {
    if (op.immediate != 'branch') continue;
    add(
      '${op.name}Short',
      op.body,
      inputs: op.inputs,
      immediate: 'shortBranch',
      terminates: op.terminates,
    );
  }
  // AOT allocation follows the numeric case order. Keep simple register-only
  // operations ahead of handlers with decoding, calls and exceptional edges.
  final originalOrder = {for (var i = 0; i < ops.length; i++) ops[i]: i};
  int rank(Instruction op) =>
      op.immediate == 'none' && !op.terminates && !op.mayThrow ? 0 : 1;
  ops.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : originalOrder[a]!.compareTo(originalOrder[b]!);
  });
  return ops;
}

void main(List<String> arguments) {
  final ops = specification();
  if (ops.length > 256 ||
      ops.map((op) => op.name).toSet().length != ops.length) {
    throw StateError('Opcode names must be unique and fit in one byte');
  }
  final constants = StringBuffer(
    '''// GENERATED by tool/generate_typed_machine.dart. Do not edit.

/// Physical scalar banks; these IDs are allocator-visible, never value storage.
abstract final class TypedRegister {
  static const a = 0, b = 1, f = 2, g = 3, e = 4, x = 5, r = 6, s = 7, c = 8;
}

enum TypedImmediate { none, intConstant, doubleConstant,
  intSpill, doubleSpill, boolSpill, branch,
  function, objectConstant, objectSpill, objectOutgoing, hostCall, shortBranch, integer, overflow }

class TypedInstruction {
  const TypedInstruction(this.name, this.inputs, this.outputs, this.immediate,
      this.mayThrow, this.terminates);
  final String name;
  final List<int> inputs;
  final List<int> outputs;
  final TypedImmediate immediate;
  final bool mayThrow;
  final bool terminates;
  List<int> get clobberedRegisters => (immediate == TypedImmediate.function || immediate == TypedImmediate.hostCall)
      ? const [0, 1, 2, 3, 4, 5, 6, 7, 8] : const [];
  int get length => immediate == TypedImmediate.none ? 1
      : immediate == TypedImmediate.branch ? 5 : 3;
}

abstract final class TypedOp {
''',
  );
  for (var i = 0; i < ops.length; i++) {
    constants.writeln('  static const ${ops[i].name} = $i;');
  }
  constants.writeln('  static const instructions = <TypedInstruction>[');
  for (final op in ops) {
    final outputs = op.name.endsWith('Swap')
        ? op.inputs
        : [if (op.output != null) op.output!];
    constants.writeln(
      "    TypedInstruction('${op.name}', ${op.inputs}, $outputs, TypedImmediate.${op.immediate}, ${op.mayThrow}, ${op.terminates}),",
    );
  }
  constants.writeln('  ];\n}');
  final machine = StringBuffer(
    '''// GENERATED by tool/generate_typed_machine.dart. Do not edit.
import 'typed_ops.g.dart';
import 'typed_program.dart';
import 'typed_frame.dart';
import 'typed_interop.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/stdlib/core.dart';

abstract final class TypedMachine {
  /// Fixed scalar banks stay in typed locals across the dispatch loop.
  @pragma('vm:never-inline')
  static Object? run(TypedProgram program, {
      List<int> intArguments = const [], List<double> doubleArguments = const [],
      List<bool> boolArguments = const [], List<Object?> objectArguments = const [], Runtime? runtime}) {
    final code = program.code;
    final entry = program.functions[program.entryFunction];
    final arguments = TypedEntry.prepare(entry, intArguments, doubleArguments, boolArguments, objectArguments, runtime);
    var frame = TypedFrame(entry);
    Object? r = arguments.r, s = arguments.s, c = arguments.c;
    var a = arguments.a, b = arguments.b;
    var f = arguments.f, g = arguments.g;
    var e = arguments.e, x = arguments.x;
    var pc = entry.entry;
    dispatch: while (true) {
      switch (code[pc++]) {
''',
  );
  for (final op in ops) {
    machine.writeln('        case TypedOp.${op.name}:');
    if (op.immediate == 'branch' || op.immediate == 'shortBranch') {
      final short = op.immediate == 'shortBranch';
      final width = short ? 2 : 4;
      final expression = short
          ? 'pc + 2 + (code[pc] | (code[pc + 1] << 8)).toSigned(16)'
          : 'code[pc] | (code[pc + 1] << 8) | (code[pc + 2] << 16) | (code[pc + 3] << 24)';
      final condition = RegExp(
        r'^if \((.+)\) pc = address;$',
      ).firstMatch(op.body)?.group(1);
      machine.writeln(
        condition == null
            ? '          pc = $expression;'
            : '          if ($condition) { pc = $expression; } else { pc += $width; }',
      );
      machine.writeln('          continue dispatch;');
      continue;
    } else if (op.immediate != 'none') {
      machine.writeln(
        '          final index = code[pc] | (code[pc + 1] << 8); pc += 2;',
      );
    }
    machine.writeln('          ${op.body.trimRight()}');
    if (!op.body.startsWith('return '))
      machine.writeln('          continue dispatch;');
  }
  machine.writeln(
    "        default: throw StateError('Invalid typed opcode at byte \${pc - 1}');\n      }\n    }\n  }\n}",
  );
  final outputs = {
    'lib/src/eval/runtime/typed/typed_ops.g.dart': constants.toString(),
    'lib/src/eval/runtime/typed/typed_machine.g.dart': machine.toString(),
  };
  for (final output in outputs.entries) {
    final file = File(output.key);
    if (arguments.contains('--check')) {
      if (!file.existsSync() || file.readAsStringSync() != output.value) {
        stderr.writeln('Generated file is stale: ${output.key}');
        exitCode = 1;
      }
    } else {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(output.value);
    }
  }
  stdout.writeln('${ops.length} typed instructions');
}
