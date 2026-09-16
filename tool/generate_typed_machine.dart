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
    this.commutative = false,
  });
  final String name;
  final String body;
  final List<int> inputs;
  final int? output;
  final String immediate;
  final bool mayThrow;
  final bool terminates;
  final bool commutative;
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
    bool commutative = false,
  }) => ops.add(
    Instruction(
      name,
      body,
      inputs: inputs,
      output: output,
      immediate: immediate,
      mayThrow: mayThrow,
      terminates: terminates,
      commutative: commutative,
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
      '''if (frame.parent == null) return $name;
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
    final commutative = {'Add', 'Mul', 'And', 'Or', 'Xor'}.contains(entry.key);
    for (final (target, other) in [(0, 1), if (!commutative) (1, 0)]) {
      final left = names[target], right = names[other];
      add(
        '$left${entry.key}${right.toUpperCase()}',
        '$left = $left ${entry.value} $right;',
        inputs: [target, other],
        output: target,
        commutative: commutative,
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
    for (final (target, other) in [
      (2, 3),
      if (entry.key != 'Add' && entry.key != 'Mul') (3, 2),
    ]) {
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
      if (output != 4) continue;
      final other = output == 4 ? 5 : 4;
      add(
        '$result${entry.key}${names[other].toUpperCase()}',
        '$result = $result ${entry.value} ${names[other]};',
        inputs: [output, other],
        output: output,
        commutative: true,
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
    '''frame = frame.enterStatic(program, index, pc);
          pc = frame.function.entry;''',
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
    'callExternal',
    'r = TypedInterop.invokeExternal(program, runtime, r, s, c, index); s = null; c = null;',
    output: 6,
    immediate: 'externalCall',
    mayThrow: true,
  );
  add(
    'rNewCaptureCell',
    'r = TypedCaptureCell(r);',
    inputs: [6],
    output: 6,
    mayThrow: true,
  );
  add(
    'rReadCaptureCell',
    'r = (r as TypedCaptureCell).value;',
    inputs: [6],
    output: 6,
    mayThrow: true,
  );
  add(
    'writeCaptureCellRS',
    '(r as TypedCaptureCell).value = s;',
    inputs: [6, 7],
    mayThrow: true,
  );
  add(
    'rCreateClosure',
    'r = TypedClosure.create(program, index, frame.objectOutgoing, runtime);',
    output: 6,
    immediate: 'closureIndex',
    mayThrow: true,
  );
  add(
    'rLoadCapture',
    'r = frame.captureAt(index);',
    output: 6,
    immediate: 'captureIndex',
    mayThrow: true,
  );
  add(
    'callClosure',
    '''final closure = TypedClosure.resolve(program, r, index, runtime);
          if (closure != null) {
            final function = closure.function;
            frame = frame.enterClosure(function, pc, closure.captures);
            pc = function.entry;
          } else {
            r = TypedClosure.invokeAt(program, runtime, r, s, c, index);
            s = null; c = null;
          }''',
    immediate: 'closureCall',
    mayThrow: true,
  );
  add('rBridgeArgument', r'r ??= const $null();', inputs: [6], output: 6);
  add(
    'enterTry',
    'TypedExceptions.enter(program, frame, index);',
    immediate: 'exceptionRegion',
    mayThrow: true,
  );
  add('leaveTry', 'TypedExceptions.leave(frame);');
  add('rBeginAsync', 'r = TypedAsync.begin(frame);', output: 6);
  add(
    'rAwait',
    '''final caller = frame.parent;
          final returnPc = frame.returnPc;
          final future = TypedAsync.suspend(program, frame, pc, r, runtime, _resumeAsync);
          if (caller == null) return future;
          frame = caller; pc = returnPc;
          r = future; s = null; c = null;''',
    inputs: [6],
    output: 6,
    mayThrow: true,
  );
  for (final withValue in [true, false]) {
    add(
      withValue ? 'rReturnAsync' : 'returnAsyncNull',
      '''final returned = TypedAsync.complete(frame, ${withValue ? 'r' : 'null'});
          if (frame.parent == null) return returned;
          pc = frame.returnPc;
          frame = frame.leave();
          r = returned; s = null; c = null;''',
      inputs: withValue ? [6] : [],
      terminates: true,
    );
  }
  add(
    'completeJump',
    'pc = TypedExceptions.jump(program, frame, index);',
    immediate: 'completionJump',
    terminates: true,
  );
  add(
    'resumeCompletion',
    'pc = TypedExceptions.resume(frame, pc);',
    mayThrow: true,
    terminates: true,
  );
  add(
    'eAssertR',
    'if (!e) throw WrappedException(r!);',
    inputs: [4, 6],
    mayThrow: true,
  );
  add('rCaughtException', 'r = TypedExceptions.caught(frame);', output: 6);
  add('rCaughtStackTrace', 'r = TypedExceptions.trace(frame);', output: 6);
  add(
    'rThrow',
    'throw WrappedException(r!);',
    inputs: [6],
    mayThrow: true,
    terminates: true,
  );
  add(
    'rethrowCaught',
    'TypedExceptions.rethrowCaught(program, frame, index);',
    immediate: 'exceptionRegion',
    mayThrow: true,
    terminates: true,
  );
  add(
    'eIsTypeR',
    'e = runtime!.isTypedValueType(r, index);',
    inputs: [6],
    output: 4,
    immediate: 'typeId',
    mayThrow: true,
  );
  add(
    'rCreateRecord',
    'r = TypedRecords.create(runtime!, r, index);',
    inputs: [6],
    output: 6,
    immediate: 'runtimeConstant',
    mayThrow: true,
  );
  add('rLoadType', r'r = $TypeImpl(index);', output: 6, immediate: 'typeId');
  add(
    'rAssertType',
    'TypedRecords.assertType(runtime!, r, index);',
    inputs: [6],
    immediate: 'typeId',
    mayThrow: true,
  );
  for (final (register, index, type) in [
    ('a', 0, 'Integer'),
    ('f', 2, 'Double'),
    ('e', 4, 'Boolean'),
    ('r', 6, 'Object'),
  ]) {
    add(
      '${register}LoadGlobal',
      '$register = TypedGlobalState.load$type(runtime, index);',
      output: index,
      immediate: 'globalIndex',
      mayThrow: true,
    );
    add(
      '${register}SetGlobal',
      'TypedGlobalState.store$type(runtime, index, $register);',
      inputs: [index],
      immediate: 'globalIndex',
      mayThrow: true,
    );
  }
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
  add(
    'aStringLengthR',
    'a = (r as String).length;',
    inputs: [6],
    output: 0,
    mayThrow: true,
  );
  add(
    'rStringConcatS',
    'r = (r as String) + (s as String);',
    inputs: [6, 7],
    output: 6,
    mayThrow: true,
  );
  add(
    'aStringCodeUnitR',
    'a = (r as String).codeUnitAt(a);',
    inputs: [6, 0],
    output: 0,
    mayThrow: true,
  );
  add(
    'rStringIndexA',
    'r = (r as String)[a];',
    inputs: [6, 0],
    output: 6,
    mayThrow: true,
  );
  add('cNewList', 'c = <Object?>[];', output: 8, mayThrow: true);
  add(
    'cNewMap',
    'c = TypedCollections.newMap(runtime);',
    output: 8,
    mayThrow: true,
  );
  add(
    'cNewSet',
    'c = TypedCollections.newSet(runtime);',
    output: 8,
    mayThrow: true,
  );
  add(
    'rMapIndexCS',
    'r = (c as Map<Object?, Object?>)[s];',
    inputs: [8, 7],
    output: 6,
    mayThrow: true,
  );
  add(
    'mapSetCSR',
    '(c as Map<Object?, Object?>)[s] = r;',
    inputs: [8, 7, 6],
    mayThrow: true,
  );
  add(
    'setAddCR',
    '(c as Set<Object?>).add(r);',
    inputs: [8, 6],
    mayThrow: true,
  );
  add(
    'rBoxMap',
    r'r = $Map.wrap(r as Map<Object?, Object?>);',
    inputs: [6],
    output: 6,
    mayThrow: true,
  );
  add(
    'rBoxSet',
    r'r = $Set.wrap(r as Set<Object?>);',
    inputs: [6],
    output: 6,
    mayThrow: true,
  );
  add(
    'aListLengthR',
    'a = (r as List).length;',
    inputs: [6],
    output: 0,
    mayThrow: true,
  );
  add(
    'rListIndexCA',
    'r = (c as List<Object?>)[a];',
    inputs: [8, 0],
    output: 6,
    mayThrow: true,
  );
  add(
    'listSetCAR',
    '(c as List<Object?>)[a] = r;',
    inputs: [8, 0, 6],
    mayThrow: true,
  );
  add(
    'listAppendCR',
    '(c as List<Object?>).add(r);',
    inputs: [8, 6],
    mayThrow: true,
  );
  add(
    'rBoxList',
    r'r = $List.wrap(r as List);',
    inputs: [6],
    output: 6,
    mayThrow: true,
  );
  add(
    'rCreateClassR',
    'r = TypedInstance(program, index, r as \$Instance?, runtime);',
    inputs: [6],
    output: 6,
    immediate: 'classIndex',
    mayThrow: true,
  );
  add(
    'rLoadPropertyR',
    'r = (r as TypedInstance).values[index];',
    inputs: [6],
    output: 6,
    immediate: 'field',
    mayThrow: true,
  );
  add(
    'setPropertyRS',
    '(r as TypedInstance).values[index] = s;',
    inputs: [6, 7],
    immediate: 'field',
    mayThrow: true,
  );
  add(
    'rLoadSuperR',
    'r = (r as TypedInstance).superclass;',
    inputs: [6],
    output: 6,
    mayThrow: true,
  );
  add(
    'rLoadThisR',
    'r = (r as TypedInstance).dispatchRoot;',
    inputs: [6],
    output: 6,
    mayThrow: true,
  );
  add('returnNull', '''if (frame.parent == null) return null;
          pc = frame.returnPc;
          frame = frame.leave();
          r = null; s = null; c = null;''', terminates: true);
  add(
    'callVirtual',
    '''final member = TypedDispatch.resolve(program, r, index, runtime);
          if (member != null) {
            final function = member.function;
            r = member.receiver;
            frame = frame.enter(function, pc);
            pc = function.entry;
          } else {
            r = TypedDispatch.invoke(program, runtime, r, s, c, index);
            s = null; c = null;
          }''',
    immediate: 'callSite',
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
  function, objectConstant, objectSpill, objectOutgoing, hostCall, shortBranch, integer, overflow,
  classIndex, field, callSite, externalCall, closureIndex, captureIndex, closureCall, globalIndex,
  exceptionRegion, completionJump, typeId, runtimeConstant }

class TypedInstruction {
  const TypedInstruction(this.name, this.inputs, this.outputs, this.immediate,
      this.mayThrow, this.terminates, this.commutative);
  final String name;
  final List<int> inputs;
  final List<int> outputs;
  final TypedImmediate immediate;
  final bool mayThrow;
  final bool terminates;
  /// Operand order may change during allocation without changing the result.
  /// Floating operations retain order, including NaN payload propagation.
  final bool commutative;
  List<int> get clobberedRegisters => (immediate == TypedImmediate.function || immediate == TypedImmediate.hostCall || immediate == TypedImmediate.callSite || immediate == TypedImmediate.externalCall || immediate == TypedImmediate.closureCall)
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
      "    TypedInstruction('${op.name}', ${op.inputs}, $outputs, TypedImmediate.${op.immediate}, ${op.mayThrow}, ${op.terminates}, ${op.commutative}),",
    );
  }
  constants.writeln('  ];\n}');
  final machine = StringBuffer(
    '''// GENERATED by tool/generate_typed_machine.dart. Do not edit.
import 'typed_ops.g.dart';
import 'typed_program.dart';
import 'typed_frame.dart';
import 'typed_interop.dart';
import 'typed_instance.dart';
import 'typed_dispatch.dart';
import 'typed_closure.dart';
import 'typed_global_state.dart';
import 'typed_exception_state.dart';
import 'typed_collections.dart';
import 'typed_records.dart';
import 'typed_async.dart';
import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/type.dart';
import 'package:dart_eval/stdlib/core.dart';

abstract final class TypedMachine {
  /// Public host boundary. Internal calls keep their machine representation.
  static Object? run(TypedProgram program, {
      List<int> intArguments = const [], List<double> doubleArguments = const [],
      List<bool> boolArguments = const [], List<Object?> objectArguments = const [], Runtime? runtime}) =>
    TypedInterop.exportExternal(runRaw(program, intArguments: intArguments,
      doubleArguments: doubleArguments, boolArguments: boolArguments,
      objectArguments: objectArguments, runtime: runtime), runtime: runtime);

  /// Convenience entry for callers that already group arguments by bank.
  static Object? runRaw(TypedProgram program, {
      int? entryFunction,
      List<int> intArguments = const [], List<double> doubleArguments = const [],
      List<bool> boolArguments = const [], List<Object?> objectArguments = const [], Runtime? runtime}) {
    final functionId = entryFunction ?? program.entryFunction;
    final entry = program.functions[functionId];
    final arguments = TypedEntry.prepare(entry, intArguments, doubleArguments, boolArguments, objectArguments, runtime);
    return runEntry(program, arguments, functionId, runtime: runtime);
  }

  /// Prepared host entry. Internal calls remain in this typed dispatch loop.
  @pragma('vm:never-inline')
  static Object? runEntry(TypedProgram program, TypedEntry arguments, int functionId, {Runtime? runtime}) {
    runtime?.prepareTypedRuntime();
    final entry = program.functions[functionId];
    final root = TypedFrame(entry)..environment = arguments.environment;
    return _drive(program, arguments, root, entry.entry, runtime);
  }

  static void _resumeAsync(TypedProgram program, TypedFrame root, int pc,
      Object? value, Object? error, StackTrace? trace, Runtime? runtime) {
    if (error != null) {
      final transfer = TypedExceptions.handle(root.activeFrame, error, trace!, runtime);
      if (transfer == null) Error.throwWithStackTrace(error, trace);
      if (transfer.frame == null) return;
      _drive(program, TypedEntry.result(transfer.result), transfer.frame!, transfer.pc, runtime);
      return;
    }
    _drive(program, TypedEntry.result(value), root, pc, runtime);
  }

  @pragma('vm:never-inline')
  static Object? _drive(TypedProgram program, TypedEntry arguments,
      TypedFrame root, int pc, Runtime? runtime) {
    var frame = root;
    while (true) {
      try {
        return _dispatch(program, arguments, frame, pc, runtime: runtime);
      } catch (error, trace) {
        final transfer = TypedExceptions.handle(root.activeFrame, error, trace, runtime);
        if (transfer == null) rethrow;
        if (transfer.frame == null) return transfer.result;
        frame = transfer.frame!; pc = transfer.pc;
        arguments = TypedEntry.result(transfer.result);
      }
    }
  }

  // A catch region around this switch makes the AOT compiler reserve large
  // catch spill areas. Recover in runEntry and reenter only after a throw.
  @pragma('vm:never-inline')
  static Object? _dispatch(TypedProgram program, TypedEntry arguments,
      TypedFrame frame, int pc, {Runtime? runtime}) {
    final code = program.code;
    Object? r = arguments.r, s = arguments.s, c = arguments.c;
    var a = arguments.a, b = arguments.b;
    var f = arguments.f, g = arguments.g;
    var e = arguments.e, x = arguments.x;
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
    if (!op.body.startsWith('return ') &&
        op.name != 'rThrow' &&
        op.name != 'rethrowCaught') {
      machine.writeln('          continue dispatch;');
    }
  }
  machine.writeln(
    """        default: throw StateError('Invalid typed opcode at byte \${pc - 1}');
      }
    }
  }
}
""",
  );
  final outputs = {
    'lib/src/eval/runtime/typed/typed_ops.g.dart': constants.toString(),
    'lib/src/eval/runtime/typed/typed_machine.g.dart':
        '${machine.toString().trimRight()}\n',
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
