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
  const names = ['a', 'b', 'f', 'g', 'e', 'x'];
  for (var register = 0; register < names.length; register++) {
    final name = names[register];
    final bank = register < 2
        ? 'int'
        : register < 4
        ? 'double'
        : 'bool';
    final pool = bank == 'int' ? 'integers' : 'doubles';
    if (bank != 'bool') {
      add(
        '${name}Constant',
        '$name = $pool[index];',
        output: register,
        immediate: '${bank}Constant',
      );
    } else {
      add('${name}True', '$name = true;', output: register);
      add('${name}False', '$name = false;', output: register);
    }
    add(
      '${name}Argument',
      '$name = frame.${bank}Arguments[index]${bank == 'bool' ? ' != 0' : ''};',
      output: register,
      immediate: '${bank}Argument',
      mayThrow: true,
    );
    add(
      '${name}Spill',
      '${bank}Spills[index] = ${bank == 'bool' ? '$name ? 1 : 0' : name};',
      inputs: [register],
      immediate: '${bank}Spill',
    );
    add(
      '${name}Reload',
      '$name = ${bank}Spills[index]${bank == 'bool' ? ' != 0' : ''};',
      output: register,
      immediate: '${bank}Spill',
    );
    final resultName = bank == 'int'
        ? 'a'
        : bank == 'double'
        ? 'f'
        : 'e';
    final resultBank = register ~/ 2;
    add(
      '${name}Return',
      '''if (frame.parent == null) return $name;
          if (frame.returnBank != $resultBank) throw StateError('Typed return bank mismatch');
          final returned = $name;
          pc = frame.returnPc;
          frame = frame.parent!;
          intSpills = frame.intSpills; doubleSpills = frame.doubleSpills; boolSpills = frame.boolSpills;
          a = 0; b = 0; f = 0.0; g = 0.0; e = false; x = false;
          $resultName = returned;''',
      inputs: [register],
      terminates: true,
    );
  }
  for (final (first, second) in [(0, 1), (2, 3), (4, 5)]) {
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
      for (final (left, right) in [(0, 1), (1, 0), (2, 3), (3, 2)]) {
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
  for (var register = 0; register < names.length; register++) {
    final name = names[register];
    final bank = register < 2
        ? 'int'
        : register < 4
        ? 'double'
        : 'bool';
    add(
      '${name}Outgoing',
      'frame.${bank}Outgoing[index] = ${bank == 'bool' ? '$name ? 1 : 0' : name};',
      inputs: [register],
      immediate: '${bank}Outgoing',
    );
  }
  for (final (bank, name) in [(0, 'Int'), (1, 'Double'), (2, 'Bool')]) {
    add(
      'call$name',
      '''final function = program.functions[index];
          frame = TypedFrame(function,
            frame.intOutgoing.sublist(0, function.intArgumentCount),
            frame.doubleOutgoing.sublist(0, function.doubleArgumentCount),
            frame.boolOutgoing.sublist(0, function.boolArgumentCount),
            parent: frame, returnPc: pc, returnBank: $bank);
          intSpills = frame.intSpills; doubleSpills = frame.doubleSpills; boolSpills = frame.boolSpills;
          a = 0; b = 0; f = 0.0; g = 0.0; e = false; x = false;
          pc = function.entry;''',
      immediate: 'function',
      mayThrow: true,
      output: bank * 2,
    );
  }
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
  static const a = 0, b = 1, f = 2, g = 3, e = 4, x = 5;
}

enum TypedImmediate { none, intConstant, doubleConstant, intArgument,
  doubleArgument, boolArgument, intSpill, doubleSpill, boolSpill, branch,
  intOutgoing, doubleOutgoing, boolOutgoing, function }

class TypedInstruction {
  const TypedInstruction(this.name, this.inputs, this.outputs, this.immediate,
      this.mayThrow, this.terminates);
  final String name;
  final List<int> inputs;
  final List<int> outputs;
  final TypedImmediate immediate;
  final bool mayThrow;
  final bool terminates;
  List<int> get clobberedRegisters => immediate == TypedImmediate.function
      ? const [0, 1, 2, 3, 4, 5] : const [];
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

abstract final class TypedMachine {
  /// Fixed scalar banks stay in typed locals across the dispatch loop.
  @pragma('vm:never-inline')
  static Object run(TypedProgram program, {
      List<int> intArguments = const [], List<double> doubleArguments = const [],
      List<bool> boolArguments = const []}) {
    final code = program.code;
    final integers = program.integers;
    final doubles = program.doubles;
    final entry = program.functions[program.entryFunction];
    if (intArguments.length < entry.intArgumentCount || doubleArguments.length < entry.doubleArgumentCount || boolArguments.length < entry.boolArgumentCount) {
      throw ArgumentError('Insufficient typed entry arguments');
    }
    var frame = TypedFrame(entry, intArguments, doubleArguments,
      [for (final value in boolArguments) value ? 1 : 0]);
    var intSpills = frame.intSpills;
    var doubleSpills = frame.doubleSpills;
    var boolSpills = frame.boolSpills;
    var a = 0, b = 0;
    var f = 0.0, g = 0.0;
    var e = false, x = false;
    var pc = entry.entry;
    while (true) {
      switch (code[pc++]) {
''',
  );
  for (final op in ops) {
    machine.writeln('        case TypedOp.${op.name}:');
    if (op.immediate == 'branch') {
      machine.writeln(
        '          final address = code[pc] | (code[pc + 1] << 8) | (code[pc + 2] << 16) | (code[pc + 3] << 24); pc += 4;',
      );
    } else if (op.immediate != 'none') {
      machine.writeln(
        '          final index = code[pc] | (code[pc + 1] << 8); pc += 2;',
      );
    }
    machine.writeln('          ${op.body}');
    if (!op.body.startsWith('return ')) machine.writeln('          break;');
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
