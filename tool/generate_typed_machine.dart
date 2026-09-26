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

/// Register-agnostic operation kind for [TypedInstruction.family]: drop the
/// leading output-register letter (a lowercase register name followed by an
/// uppercase base) and the trailing uppercase parameter-encoding letters.
/// `aListLengthR` → `ListLength`, `mapSetCSR` → `mapSet`.
String familyOf(String name) {
  var end = name.length;
  while (end > 0 &&
      name.codeUnitAt(end - 1) >= 0x41 &&
      name.codeUnitAt(end - 1) <= 0x5A) {
    end--;
  }
  var start = 0;
  if (name.length > 1 &&
      'abfgersc'.contains(name[0]) &&
      name.codeUnitAt(1) >= 0x41 &&
      name.codeUnitAt(1) <= 0x5A) {
    start = 1;
  }
  if (start >= end) return name;
  final family = name.substring(start, end);
  // xFromY between registers of one bank is a plain copy, not a conversion.
  if (family == 'From' && start == 1 && end == name.length - 1) {
    const domains = ['ab', 'fg', 'e', 'rsc'];
    final source = name.substring(name.length - 1).toLowerCase();
    for (final domain in domains) {
      if (domain.contains(name[0]) && domain.contains(source)) return 'Move';
    }
  }
  return family;
}

({List<Instruction> ops, List<Instruction> extended}) specification() {
  final ops = <Instruction>[];
  final extendedOps = <Instruction>[];
  void add(
    String name,
    String body, {
    List<int> inputs = const [],
    int? output,
    String immediate = 'none',
    bool mayThrow = false,
    bool terminates = false,
    bool commutative = false,
    bool extended = false,
  }) => (extended ? extendedOps : ops).add(
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
  const names = ['a', 'b', 'f', 'g', 'e', '', 'r', 's', 'c'];
  for (var register = 0; register < names.length; register++) {
    final name = names[register];
    if (name.isEmpty) continue;
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
  for (final (first, second) in [(0, 1), (2, 3), (6, 7), (6, 8), (7, 8)]) {
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
  }
  for (final target in [2, 3]) {
    final name = names[target];
    add('${name}Negate', '$name = -$name;', inputs: [target], output: target);
  }
  for (final output in [4]) {
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
    '''final typeEnvironmentReceiver = frame.pendingTypeEnvironmentReceiver;
          final typeArguments = frame.pendingTypeArguments;
          frame.pendingTypeEnvironmentReceiver = null;
          frame.pendingTypeArguments = const [];
          frame = frame.enterStatic(
            program,
            index,
            pc,
            typeEnvironmentReceiver: typeEnvironmentReceiver,
            typeArguments: typeArguments,
          );
          pc = frame.function.entry;''',
    immediate: 'function',
    mayThrow: true,
  );
  add(
    'rSetCallTypeReceiver',
    'frame.pendingTypeEnvironmentReceiver = r;',
    inputs: [6],
  );
  add(
    'setCallTypeArguments',
    '''final constant = (runtime!.typedConstant(index) as List).cast<int>();
          frame.pendingTypeArguments = runtime.resolveTypedCallTypeArguments(
            constant,
            actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
            callableTypeArguments: frame.effectiveTypeArguments,
          );''',
    immediate: 'runtimeConstant',
    mayThrow: true,
  );
  for (final register in [6, 7, 8]) {
    final name = names[register];
    add('${name}Null', '$name = null;', output: register);
    for (final flag in [4]) {
      add(
        '${names[flag]}IsNull${name.toUpperCase()}',
        '${names[flag]} = TypedInterop.isNull($name);',
        inputs: [register],
        output: flag,
      );
    }
  }
  for (final flag in [4]) {
    add(
      '${names[flag]}EqRS',
      '${names[flag]} = TypedInterop.equals(runtime, r, s);',
      inputs: [6, 7],
      output: flag,
      mayThrow: true,
    );
  }
  for (final register in [0, 1, 2, 3, 4]) {
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
    extended: true,
  );
  add(
    'rNewBridgeSuperShim',
    'r = TypedInterop.newBridgeSuperShim();',
    output: 6,
    mayThrow: true,
    extended: true,
  );
  add(
    'parentBridgeSuperShim',
    'TypedInterop.parentBridgeSuperShim(r, s);',
    inputs: [6, 7],
    mayThrow: true,
    extended: true,
  );
  add(
    'rAttachBridge',
    'r = TypedInterop.attachBridge(runtime, r, s, index);',
    inputs: [6, 7],
    output: 6,
    immediate: 'typeId',
    mayThrow: true,
    extended: true,
  );
  add(
    'rRuntimeType',
    'r = TypedInterop.runtimeTypeOf(runtime, r);',
    inputs: [6],
    output: 6,
    mayThrow: true,
    extended: true,
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
    '''r = TypedClosure.create(
          program,
          index,
          frame.objectOutgoing,
          runtime,
          frame.effectiveTypeEnvironmentReceiver,
          frame.effectiveTypeArguments,
        );''',
    output: 6,
    immediate: 'closureIndex',
    mayThrow: true,
    extended: true,
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
    '''final site = program.closureCalls[index];
          final callTypeArguments = runtime == null
              ? site.typeArguments
              : runtime.resolveTypedCallTypeArguments(
                  site.typeArguments,
                  actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
                  callableTypeArguments: frame.effectiveTypeArguments,
                );
          final closure = TypedClosure.resolve(
            program, r, index, runtime, s, c, callTypeArguments,
          );
          if (closure != null) {
            final function = closure.function;
            if (!closure.descriptor.hasEnvironment) r = closure.captures.single;
            frame = frame.enterClosure(
              function,
              pc,
              closure.captures,
              typeEnvironmentReceiver: closure.descriptor.boundReceiver
                  ? closure.captures.single
                  : null,
              typeArguments: callTypeArguments,
              lexicalTypeEnvironmentReceiver:
                  closure.definingTypeEnvironmentReceiver,
              lexicalTypeArguments: closure.definingTypeArguments,
            );
            pc = function.entry;
          } else {
            r = TypedClosure.invokeAt(
              program, runtime, r, s, c, index, callTypeArguments,
            );
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
  add(
    'rBeginAsync',
    '''final runtimeTypeId = runtime == null
              ? index
              : runtime.resolveTypedEnvironmentType(
                  index,
                  actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
                  callableTypeArguments: frame.effectiveTypeArguments,
                );
          r = TypedAsync.begin(frame, runtimeTypeId, runtime);''',
    output: 6,
    immediate: 'typeId',
    extended: true,
  );
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
    extended: true,
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
      extended: true,
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
    extended: true,
  );
  add(
    'rCaughtException',
    'r = TypedExceptions.caught(frame);',
    output: 6,
    extended: true,
  );
  add(
    'rCaughtStackTrace',
    'r = TypedExceptions.trace(frame);',
    output: 6,
    extended: true,
  );
  add(
    'rThrow',
    'throw WrappedException(r!);',
    inputs: [6],
    mayThrow: true,
    terminates: true,
    extended: true,
  );
  add(
    'rethrowCaught',
    'TypedExceptions.rethrowCaught(program, frame, index);',
    immediate: 'exceptionRegion',
    mayThrow: true,
    terminates: true,
    extended: true,
  );
  add(
    'eIsTypeR',
    '''e = runtime!.isTypedValueTypeInCallableEnvironment(
            r,
            index,
            frame.effectiveTypeArguments,
            actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
          );''',
    inputs: [6],
    output: 4,
    immediate: 'typeId',
    mayThrow: true,
  );
  add(
    'eIsGroundTypeR',
    'e = runtime!.isTypedValueType(r, index);',
    inputs: [6],
    output: 4,
    immediate: 'typeId',
    mayThrow: true,
    extended: true,
  );
  add(
    'rCreateRecord',
    '''r = TypedRecords.create(
            runtime!,
            r,
            index,
            actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
            callableTypeArguments: frame.effectiveTypeArguments,
          );''',
    inputs: [6],
    output: 6,
    immediate: 'runtimeConstant',
    mayThrow: true,
    extended: true,
  );
  add(
    'rLoadType',
    r'r = $TypeImpl(index, runtime);',
    output: 6,
    immediate: 'typeId',
  );
  add(
    'aSetTypeEnvironment',
    'frame.typeEnvironmentReceiver = a;',
    inputs: [0],
    extended: true,
  );
  add(
    'aResolveType',
    '''a = runtime == null
            ? index
            : runtime.resolveTypedEnvironmentType(
                index,
                actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
                callableTypeArguments: frame.effectiveTypeArguments,
              );''',
    output: 0,
    immediate: 'typeId',
    extended: true,
  );
  add(
    'rLoadTypeParameter',
    '''r = \$TypeImpl(
            runtime!.resolveTypeParameterInEnvironment(
              index,
              frame.typeEnvironmentOwnerType(runtime),
              frame.effectiveTypeArguments,
            ),
            runtime,
          );''',
    output: 6,
    immediate: 'typeId',
    mayThrow: true,
    extended: true,
  );
  add(
    'rAssertType',
    '''if (runtime != null) {
          if (!runtime.isTypedValueTypeInCallableEnvironment(
            r,
            index,
            frame.effectiveTypeArguments,
            actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
          )) {
            throw TypeError();
          }
        }''',
    inputs: [6],
    immediate: 'typeId',
    mayThrow: true,
    extended: true,
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
    '''final args = frame.takeObjectArguments(index);
          final (hfirst, hrest) = TypedInterop.splitVector(args);
          final result = TypedInterop.call(runtime, r, args.length, hfirst, hrest); r = result; s = null; c = null; ''',
    inputs: [6],
    output: 6,
    immediate: 'hostCall',
    mayThrow: true,
    extended: true,
  );
  add(
    'callMethod',
    '''final args = frame.takeObjectArguments(index);
          final (hfirst, hrest) = TypedInterop.splitVector(args);
          final result = TypedInterop.invoke(runtime, r, s as String, args.length, hfirst, hrest); r = result; s = null; c = null; ''',
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
  add(
    'rStringSubRAB',
    'r = (r as String).substring(a, b);',
    inputs: [6, 0, 1],
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
    'cNewConstMap',
    'c = TypedCollections.newConstMap(runtime);',
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
    'cNewConstSet',
    'c = TypedCollections.newConstSet(runtime);',
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
    'eSetAddCR',
    'e = (c as Set<Object?>).add(r);',
    inputs: [8, 6],
    output: 4,
    mayThrow: true,
  );
  add(
    'cNativeElementsC',
    'c = index == 0 ? (c as Set<Object?>).toList() : (c as Map<Object?, Object?>).keys.toList();',
    inputs: [8],
    output: 8,
    immediate: 'integer',
    mayThrow: true,
  );
  add(
    'eIsNativeR',
    'e = index == 0 ? r is List : index == 1 ? r is Set : r is Map;',
    inputs: [6],
    output: 4,
    immediate: 'integer',
  );
  add(
    'rBoxMap',
    r'''final runtimeTypeId = runtime == null
              ? index
              : runtime.resolveTypedEnvironmentType(
                  index,
                  actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
                  callableTypeArguments: frame.effectiveTypeArguments,
                );
          r = $Map.wrap(
            r as Map<Object?, Object?>,
            runtimeTypeId: runtimeTypeId,
            runtime: runtime,
          );''',
    inputs: [6],
    output: 6,
    immediate: 'typeId',
    mayThrow: true,
  );
  add(
    'rBoxSet',
    r'''final runtimeTypeId = runtime == null
              ? index
              : runtime.resolveTypedEnvironmentType(
                  index,
                  actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
                  callableTypeArguments: frame.effectiveTypeArguments,
                );
          r = $Set.wrap(
            r as Set<Object?>,
            runtimeTypeId: runtimeTypeId,
            runtime: runtime,
          );''',
    inputs: [6],
    output: 6,
    immediate: 'typeId',
    mayThrow: true,
  );
  for (final register in [6, 7, 8]) {
    final name = names[register];
    add(
      'eInternConst${name.toUpperCase()}',
      '''r = runtime == null
              ? $name
              : runtime.internConst(
                  $name,
                  runtime.resolveTypedEnvironmentType(
                    index,
                    actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
                    callableTypeArguments: frame.effectiveTypeArguments,
                  ),
                );''',
      inputs: [register],
      output: 6,
      immediate: 'typeId',
      mayThrow: true,
    );
  }
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
    'rBoxListTyped',
    r'''final runtimeTypeId = runtime == null
              ? index
              : runtime.resolveTypedEnvironmentType(
                  index,
                  actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
                  callableTypeArguments: frame.effectiveTypeArguments,
                );
          r = $List.wrap(
            r as List,
            runtimeTypeId: runtimeTypeId,
            runtime: runtime,
          );''',
    inputs: [6],
    output: 6,
    immediate: 'typeId',
    mayThrow: true,
  );
  add(
    'rCreateClassRA',
    '''final runtimeTypeId = runtime == null
              ? a
              : runtime.resolveTypedEnvironmentType(
                  a,
                  actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
                  callableTypeArguments: frame.effectiveTypeArguments,
                );
          r = TypedInstance(
            program,
            index,
            r as \$Instance?,
            runtime,
            runtimeTypeId,
          );''',
    inputs: [6, 0],
    output: 6,
    immediate: 'classIndex',
    mayThrow: true,
  );
  add(
    'rLoadPropertyR',
    'r = TypedInstance.boxField((r as TypedInstance).values[index]);',
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
    'aLoadPropertyR',
    'a = TypedInstance.intField((r as TypedInstance).values[index]);',
    inputs: [6],
    output: 0,
    immediate: 'field',
    mayThrow: true,
  );
  add(
    'fLoadPropertyR',
    'f = TypedInstance.doubleField((r as TypedInstance).values[index]);',
    inputs: [6],
    output: 2,
    immediate: 'field',
    mayThrow: true,
  );
  add(
    'eLoadPropertyR',
    'e = TypedInterop.toBool((r as TypedInstance).values[index]);',
    inputs: [6],
    output: 4,
    immediate: 'field',
    mayThrow: true,
  );
  add(
    'rLoadPropertyStringR',
    'r = TypedInterop.toStringValue((r as TypedInstance).values[index]);',
    inputs: [6],
    output: 6,
    immediate: 'field',
    mayThrow: true,
  );
  add(
    'aFieldIncrementRA',
    'final instance = r as TypedInstance; instance.values[index] = TypedInstance.intField(instance.values[index]) + 1;',
    inputs: [6],
    immediate: 'field',
    mayThrow: true,
  );
  add(
    'aStringCodeUnitFieldsRR',
    'final instance = r as TypedInstance; a = TypedInterop.toStringValue(instance.values[index & 255]).codeUnitAt(TypedInstance.intField(instance.values[index >> 8]));',
    inputs: [6],
    output: 0,
    immediate: 'integer',
    mayThrow: true,
  );
  add(
    'eFieldLessStrLenRR',
    'final instance = r as TypedInstance; e = TypedInstance.intField(instance.values[index & 255]) < TypedInterop.toStringValue(instance.values[index >> 8]).length;',
    inputs: [6],
    output: 4,
    immediate: 'integer',
    mayThrow: true,
  );
  add(
    'setPropertyRA',
    '(r as TypedInstance).values[index] = a;',
    inputs: [6, 0],
    immediate: 'field',
    mayThrow: true,
  );
  add(
    'setPropertyRF',
    '(r as TypedInstance).values[index] = f;',
    inputs: [6, 2],
    immediate: 'field',
    mayThrow: true,
  );
  add(
    'setPropertyRE',
    '(r as TypedInstance).values[index] = \$bool(e);',
    inputs: [6, 4],
    immediate: 'field',
    mayThrow: true,
  );
  add(
    'bufWriteRS',
    '(r as \$StringBuffer).\$value.write(TypedInterop.reify(s));',
    inputs: [6, 7],
    mayThrow: true,
  );
  add(
    'rLoadSuperR',
    'r = (r as TypedInstance).superclass;',
    inputs: [6],
    output: 6,
    mayThrow: true,
    extended: true,
  );
  add(
    'rUninitializedField',
    'r = TypedLateField.uninitialized;',
    output: 6,
    extended: true,
  );
  add(
    'rLoadLatePropertyR',
    'r = TypedLateField.read(r, index);',
    inputs: [6],
    output: 6,
    immediate: 'field',
    mayThrow: true,
    extended: true,
  );
  add(
    'setLateFinalPropertyRS',
    'TypedLateField.writeFinal(r, index, s);',
    inputs: [6, 7],
    immediate: 'field',
    mayThrow: true,
    extended: true,
  );
  add(
    'rLoadThisR',
    'r = (r as TypedInstance).dispatchRoot;',
    inputs: [6],
    output: 6,
    mayThrow: true,
    extended: true,
  );
  add('returnNull', '''if (frame.parent == null) return null;
          pc = frame.returnPc;
          frame = frame.leave();
          r = null; s = null; c = null;''', terminates: true);
  add(
    'callVirtual',
    '''final member = TypedDispatch.resolve(program, r, index, runtime, s, c);
          if (member != null) {
            final function = member.function;
            r = member.receiver;
            frame = frame.enter(
              function,
              pc,
              typeEnvironmentReceiver: member.receiver,
            );
            pc = function.entry;
          } else {
            final site = program.callSites[index];
            final callTypeArguments = runtime == null
                ? site.typeArguments
                : runtime.resolveTypedCallTypeArguments(
                    site.typeArguments,
                    actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
                    callableTypeArguments: frame.effectiveTypeArguments,
                  );
            r = TypedDispatch.invoke(
              program, runtime, r, s, c, index, callTypeArguments,
            );
            s = null; c = null;
          }''',
    immediate: 'callSite',
    mayThrow: true,
  );
  for (final (name, operator) in [('Eq', '=='), ('Ne', '!=')]) {
    add(
      'eString${name}RS',
      'e = (r as String) $operator (s as String);',
      inputs: [6, 7],
      output: 4,
      extended: true,
    );
  }
  for (final (name, member) in [
    ('IsEmpty', 'isEmpty'),
    ('IsNotEmpty', 'isNotEmpty'),
  ]) {
    add(
      'eString${name}R',
      'e = (r as String).$member;',
      inputs: [6],
      output: 4,
      extended: true,
    );
  }
  add(
    'eStringStartsWithRS',
    'e = (r as String).startsWith(s as String);',
    inputs: [6, 7],
    output: 4,
    extended: true,
  );
  // Branch on the negated comparison, preserving unordered NaN semantics.
  for (final comparison in {
    'Eq': '==',
    'Ne': '!=',
    'Lt': '<',
    'Lte': '<=',
    'Gt': '>',
    'Gte': '>=',
  }.entries) {
    for (final (left, right) in [(0, 1), (2, 3)]) {
      add(
        'jumpNot${comparison.key}${names[left].toUpperCase()}${names[right].toUpperCase()}',
        'if (!(${names[left]} ${comparison.value} ${names[right]})) pc = address;',
        inputs: [left, right],
        immediate: 'branch',
        extended: true,
      );
    }
  }
  for (final op in [...ops, ...extendedOps]) {
    if (op.immediate != 'branch') continue;
    add(
      '${op.name}Short',
      op.body,
      inputs: op.inputs,
      immediate: 'shortBranch',
      terminates: op.terminates,
    );
  }

  // Register variants of hot object-register ops, dispatched through `ext`:
  // the canonical op uses `r`; variants let the allocator keep values in
  // s/c/d (and ints in w) without shuffling through r.
  for (final (recv, rn) in [(7, 's'), (8, 'c')]) {
    final R = rn.toUpperCase();
    add(
      'aLoadProperty$R',
      'a = TypedInstance.intField(($rn as TypedInstance).values[index]);',
      inputs: [recv],
      output: 0,
      immediate: 'field',
      mayThrow: true,
      extended: true,
    );
    add(
      'fLoadProperty$R',
      'f = TypedInstance.doubleField(($rn as TypedInstance).values[index]);',
      inputs: [recv],
      output: 2,
      immediate: 'field',
      mayThrow: true,
      extended: true,
    );
    add(
      'eLoadProperty$R',
      'e = TypedInterop.toBool(($rn as TypedInstance).values[index]);',
      inputs: [recv],
      output: 4,
      immediate: 'field',
      mayThrow: true,
      extended: true,
    );
    add(
      '${rn}LoadProperty$R',
      '$rn = TypedInstance.boxField(($rn as TypedInstance).values[index]);',
      inputs: [recv],
      output: recv,
      immediate: 'field',
      mayThrow: true,
      extended: true,
    );
    add(
      '${rn}LoadPropertyString$R',
      '$rn = TypedInterop.toStringValue(($rn as TypedInstance).values[index]);',
      inputs: [recv],
      output: recv,
      immediate: 'field',
      mayThrow: true,
      extended: true,
    );
    // A field of `this` (r) loaded straight into another object register.
    add(
      '${rn}LoadPropertyR',
      '$rn = TypedInstance.boxField((r as TypedInstance).values[index]);',
      inputs: [6],
      output: recv,
      immediate: 'field',
      mayThrow: true,
      extended: true,
    );
    add(
      '${rn}LoadPropertyStringR',
      '$rn = TypedInterop.toStringValue((r as TypedInstance).values[index]);',
      inputs: [6],
      output: recv,
      immediate: 'field',
      mayThrow: true,
      extended: true,
    );
    for (final (vreg, vn, boxed) in [
      (0, 'a', 'a'),
      (1, 'b', 'b'),
      (7, 's', 's'),
      (8, 'c', 'c'),
      (2, 'f', 'f'),
      (4, 'e', r'$bool(e)'),
    ]) {
      add(
        'setProperty$R${vn.toUpperCase()}',
        '($rn as TypedInstance).values[index] = $boxed;',
        inputs: [recv, vreg],
        immediate: 'field',
        mayThrow: true,
        extended: true,
      );
    }
    add(
      'aFieldIncrement${R}A',
      'final instance = $rn as TypedInstance; instance.values[index] = TypedInstance.intField(instance.values[index]) + 1;',
      inputs: [recv],
      immediate: 'field',
      mayThrow: true,
      extended: true,
    );
    add(
      'aStringCodeUnitFields${R}R',
      'final instance = $rn as TypedInstance; a = TypedInterop.toStringValue(instance.values[index & 255]).codeUnitAt(TypedInstance.intField(instance.values[index >> 8]));',
      inputs: [recv],
      output: 0,
      immediate: 'integer',
      mayThrow: true,
      extended: true,
    );
    add(
      'eFieldLessStrLen${R}R',
      'final instance = $rn as TypedInstance; e = TypedInstance.intField(instance.values[index & 255]) < TypedInterop.toStringValue(instance.values[index >> 8]).length;',
      inputs: [recv],
      output: 4,
      immediate: 'integer',
      mayThrow: true,
      extended: true,
    );
    add(
      'aStringLength$R',
      'a = ($rn as String).length;',
      inputs: [recv],
      output: 0,
      mayThrow: true,
      extended: true,
    );
    add(
      'aStringCodeUnit$R',
      'a = ($rn as String).codeUnitAt(a);',
      inputs: [recv, 0],
      output: 0,
      mayThrow: true,
      extended: true,
    );
    add(
      '${rn}StringIndex${R}A',
      '$rn = ($rn as String)[a];',
      inputs: [recv, 0],
      output: recv,
      mayThrow: true,
      extended: true,
    );
    add(
      '${rn}StringSub${R}AB',
      '$rn = ($rn as String).substring(a, b);',
      inputs: [recv, 0, 1],
      output: recv,
      mayThrow: true,
      extended: true,
    );
    add(
      '${rn}BoxString',
      '$rn = \$String($rn as String);',
      inputs: [recv],
      output: recv,
      mayThrow: true,
      extended: true,
    );
    add(
      '${rn}UnboxString',
      '$rn = TypedInterop.toStringValue($rn);',
      inputs: [recv],
      output: recv,
      mayThrow: true,
      extended: true,
    );
    add(
      'aListLength$R',
      'a = ($rn as List).length;',
      inputs: [recv],
      output: 0,
      mayThrow: true,
      extended: true,
    );
    add(
      'aNativeFrom$R',
      'a = $rn as int;',
      inputs: [recv],
      output: 0,
      mayThrow: true,
      extended: true,
    );
    add(
      'fNativeFrom$R',
      'f = $rn as double;',
      inputs: [recv],
      output: 2,
      mayThrow: true,
      extended: true,
    );
    add(
      'eNativeFrom$R',
      'e = $rn as bool;',
      inputs: [recv],
      output: 4,
      mayThrow: true,
      extended: true,
    );
    add(
      'aFrom$R',
      'a = TypedInterop.toInt($rn);',
      inputs: [recv],
      output: 0,
      mayThrow: true,
      extended: true,
    );
    add(
      'fFrom$R',
      'f = TypedInterop.toDouble($rn);',
      inputs: [recv],
      output: 2,
      mayThrow: true,
      extended: true,
    );
    add(
      'eFrom$R',
      'e = TypedInterop.toBool($rn);',
      inputs: [recv],
      output: 4,
      mayThrow: true,
      extended: true,
    );
    add(
      '${rn}BoxList',
      '$rn = \$List.wrap($rn as List);',
      inputs: [recv],
      output: recv,
      mayThrow: true,
      extended: true,
    );
    add(
      '${rn}BoxMap',
      '''final runtimeTypeId = runtime == null
              ? index
              : runtime.resolveTypedEnvironmentType(
                  index,
                  actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
                  callableTypeArguments: frame.effectiveTypeArguments,
                );
          $rn = \$Map.wrap(
            $rn as Map<Object?, Object?>,
            runtimeTypeId: runtimeTypeId,
            runtime: runtime,
          );''',
      inputs: [recv],
      output: recv,
      immediate: 'typeId',
      mayThrow: true,
      extended: true,
    );
    add(
      '${rn}BoxSet',
      '''final runtimeTypeId = runtime == null
              ? index
              : runtime.resolveTypedEnvironmentType(
                  index,
                  actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
                  callableTypeArguments: frame.effectiveTypeArguments,
                );
          $rn = \$Set.wrap(
            $rn as Set<Object?>,
            runtimeTypeId: runtimeTypeId,
            runtime: runtime,
          );''',
      inputs: [recv],
      output: recv,
      immediate: 'typeId',
      mayThrow: true,
      extended: true,
    );
    add(
      '${rn}LoadThis$R',
      '$rn = ($rn as TypedInstance).dispatchRoot;',
      inputs: [recv],
      output: recv,
      mayThrow: true,
      extended: true,
    );
    add(
      'eIsNative$R',
      'e = index == 0 ? $rn is List : index == 1 ? $rn is Set : $rn is Map;',
      inputs: [recv],
      output: 4,
      immediate: 'integer',
      extended: true,
    );
    add(
      '${rn}Throw',
      'throw WrappedException($rn!);',
      inputs: [recv],
      mayThrow: true,
      terminates: true,
      extended: true,
    );
    add(
      '${rn}LoadGlobal',
      '$rn = TypedGlobalState.loadObject(runtime, index);',
      output: recv,
      immediate: 'globalIndex',
      mayThrow: true,
      extended: true,
    );
    add(
      '${rn}SetGlobal',
      'TypedGlobalState.storeObject(runtime, index, $rn);',
      inputs: [recv],
      immediate: 'globalIndex',
      mayThrow: true,
      extended: true,
    );

    add(
      'eAssert$R',
      'if (!e) throw WrappedException($rn!);',
      inputs: [4, recv],
      mayThrow: true,
      extended: true,
    );
    add(
      'eIsType$R',
      '''e = runtime!.isTypedValueTypeInCallableEnvironment(
            $rn,
            index,
            frame.effectiveTypeArguments,
            actualOwnerType: frame.typeEnvironmentOwnerType(runtime),
          );''',
      inputs: [recv],
      output: 4,
      immediate: 'typeId',
      mayThrow: true,
      extended: true,
    );
    if (recv != 7) {
      add(
        'bufWriteR$R',
        '(r as \$StringBuffer).\$value.write(TypedInterop.reify($rn));',
        inputs: [6, recv],
        mayThrow: true,
        extended: true,
      );
    }
    for (final src in [0, 1, 2, 3, 4]) {
      final sn = names[src];
      add(
        '${rn}From${sn.toUpperCase()}',
        '$rn = $sn;',
        inputs: [src],
        output: recv,
        mayThrow: true,
        extended: true,
      );
      if (src < 2 || false) {
        add(
          '${rn}Box${sn.toUpperCase()}',
          '$rn = \$int($sn);',
          inputs: [src],
          output: recv,
          extended: true,
        );
      }
    }
  }

  // Ops whose canonical receiver is `c` get r/s/d variants.
  for (final (recv, rn) in [(6, 'r'), (7, 's')]) {
    final R = rn.toUpperCase();
    add(
      'rListIndex${R}A',
      'r = ($rn as List<Object?>)[a];',
      inputs: [recv, 0],
      output: 6,
      mayThrow: true,
      extended: true,
    );
    add(
      'listSet${R}AR',
      '($rn as List<Object?>)[a] = r;',
      inputs: [recv, 0, 6],
      mayThrow: true,
      extended: true,
    );
    add(
      'listAppend${R}R',
      '($rn as List<Object?>).add(r);',
      inputs: [recv, 6],
      mayThrow: true,
      extended: true,
    );
    add(
      'rMapIndex${R}S',
      'r = ($rn as Map<Object?, Object?>)[s];',
      inputs: [recv, 7],
      output: 6,
      mayThrow: true,
      extended: true,
    );
    add(
      'mapSet${R}SR',
      '($rn as Map<Object?, Object?>)[s] = r;',
      inputs: [recv, 7, 6],
      mayThrow: true,
      extended: true,
    );
    add(
      'setAdd${R}R',
      '($rn as Set<Object?>).add(r);',
      inputs: [recv, 6],
      mayThrow: true,
      extended: true,
    );
    add(
      'eSetAdd${R}R',
      'e = ($rn as Set<Object?>).add(r);',
      inputs: [recv, 6],
      output: 4,
      mayThrow: true,
      extended: true,
    );
    add(
      '${rn}NewList',
      '$rn = <Object?>[];',
      output: recv,
      mayThrow: true,
      extended: true,
    );
    add(
      '${rn}LoadOutgoing',
      '$rn = frame.objectOutgoing;',
      output: recv,
      mayThrow: true,
      extended: true,
    );
  }
  for (final (x, y) in [(6, 8), (7, 8)]) {
    final xn = names[x], yn = names[y];
    add(
      'eEq${xn.toUpperCase()}${yn.toUpperCase()}',
      'e = TypedInterop.equals(runtime, $xn, $yn);',
      inputs: [x, y],
      output: 4,
      mayThrow: true,
      extended: true,
    );
  }
  ops.add(Instruction('ext', '', inputs: const [], immediate: 'none'));
  // AOT allocation follows the numeric case order. Keep simple register-only
  // operations ahead of handlers with decoding, calls and exceptional edges.
  final originalOrder = {for (var i = 0; i < ops.length; i++) ops[i]: i};
  int rank(Instruction op) =>
      op.name != 'ext' &&
          op.immediate == 'none' &&
          !op.terminates &&
          !op.mayThrow
      ? 0
      : 1;
  ops.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : originalOrder[a]!.compareTo(originalOrder[b]!);
  });
  return (ops: ops, extended: extendedOps);
}

void main(List<String> arguments) {
  final (:ops, :extended) = specification();
  if (ops.length > 256 ||
      extended.length > 256 ||
      ops.map((op) => op.name).toSet().length != ops.length) {
    throw StateError('Opcode names must be unique and fit in one byte');
  }

  final constants = StringBuffer(
    '''// GENERATED by tool/generate_typed_machine.dart. Do not edit.

/// Physical scalar banks; these IDs are allocator-visible, never value storage.
abstract final class TypedRegister {
  static const a = 0, b = 1, f = 2, g = 3, e = 4, r = 6, s = 7, c = 8;
}

enum TypedImmediate { none, intConstant, doubleConstant,
  intSpill, doubleSpill, boolSpill, branch,
  function, objectConstant, objectSpill, objectOutgoing, hostCall, shortBranch, integer, overflow,
  classIndex, field, callSite, externalCall, closureIndex, captureIndex, closureCall, globalIndex,
  exceptionRegion, completionJump, typeId, runtimeConstant }

class TypedInstruction {
  const TypedInstruction(this.name, this.inputs, this.outputs, this.immediate,
      this.mayThrow, this.terminates, this.commutative, this.family);
  final String name;
  final List<int> inputs;
  final List<int> outputs;
  final TypedImmediate immediate;
  final bool mayThrow;
  final bool terminates;
  /// Operand order may change during allocation without changing the result.
  /// Floating operations retain order, including NaN payload propagation.
  final bool commutative;
  /// Register-agnostic operation kind: the name with the output-register
  /// prefix and parameter-encoding suffix removed. Register variants of one
  /// operation (rBoxMap, cBoxMap) share a family (BoxMap).
  final String family;
  List<int> get clobberedRegisters => (immediate == TypedImmediate.function || immediate == TypedImmediate.hostCall || immediate == TypedImmediate.callSite || immediate == TypedImmediate.externalCall || immediate == TypedImmediate.closureCall)
      ? const [0, 1, 2, 3, 4, 6, 7, 8] : const [];
  int get length => immediate == TypedImmediate.none ? 1
      : immediate == TypedImmediate.branch ? 5 : 3;
}

abstract final class TypedOp {
''',
  );
  for (var i = 0; i < ops.length; i++) {
    constants.writeln('  static const ${ops[i].name} = $i;');
  }
  // Extended opcodes dispatch behind [ext]: their logical code is
  // `extendedBase + index` — an escape byte followed by the sub-index.
  constants.writeln('  static const extendedBase = 256;');
  for (var i = 0; i < extended.length; i++) {
    constants.writeln('  static const ${extended[i].name} = ${256 + i};');
  }
  constants.writeln('  static const instructions = <TypedInstruction>[');
  void writeSpec(Instruction op) {
    final outputs = op.name.endsWith('Swap')
        ? op.inputs
        : [if (op.output != null) op.output!];
    constants.writeln(
      "    TypedInstruction('${op.name}', ${op.inputs}, $outputs, TypedImmediate.${op.immediate}, ${op.mayThrow}, ${op.terminates}, ${op.commutative}, '${familyOf(op.name)}'),",
    );
  }

  for (final op in ops) {
    writeSpec(op);
  }
  // Pad to the extended base so `instructions[code]` indexes both spaces.
  for (var i = ops.length; i < 256; i++) {
    constants.writeln(
      "    TypedInstruction('reserved$i', [], [], TypedImmediate.none, false, false, false, 'reserved$i'),",
    );
  }
  for (final op in extended) {
    writeSpec(op);
  }
  constants.writeln('  ];\n}');
  final machine = StringBuffer(
    '''// GENERATED by tool/generate_typed_machine.dart. Do not edit.
import 'typed_ops.g.dart';
import 'typed_program.dart';
import 'typed_frame.dart';
import 'typed_interop.dart';
import 'typed_instance.dart';
import 'typed_late_field.dart';
import 'typed_dispatch.dart';
import 'typed_closure.dart';
import 'typed_global_state.dart';
import 'typed_exception_state.dart';
import 'typed_collections.dart';
import 'typed_records.dart';
import 'typed_async.dart';
import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/stdlib/core.dart';

/// Exchange object for the secondary dispatch in [_dispatchCold].
final class _ColdCall {
  int op = 0;
  int pc = 0;
  int a = 0, b = 0;
  double f = 0.0, g = 0.0;
  bool e = false;
  Object? r, s, c;
  TypedFrame? frame;
}

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
    final root = TypedFrame(entry)
      ..environment = arguments.environment
      ..typeEnvironmentReceiver = arguments.typeEnvironmentReceiver
      ..typeArguments = arguments.typeArguments
      ..lexicalTypeEnvironmentReceiver = arguments.lexicalTypeEnvironmentReceiver
      ..lexicalTypeArguments = arguments.lexicalTypeArguments;
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
    var e = arguments.e;
    final cold = _ColdCall();
      dispatch: while (true) {
      switch (code[pc++]) {
''',
  );
  // Extended ops that must stay in `_dispatch`: they reassign `frame`
  // (stack discipline) or return a result out of the interpreter.
  bool inlineCold(Instruction op) =>
      op.body.contains('frame =') || op.body.contains('return ');

  void emitCaseBody(
    Instruction op,
    String pad, {
    StringBuffer? sink,
    bool cold = false,
  }) {
    final out = sink ?? machine;
    final next = cold ? 'break;' : 'continue dispatch;';
    if (op.immediate == 'branch' || op.immediate == 'shortBranch') {
      final short = op.immediate == 'shortBranch';
      final width = short ? 2 : 4;
      final expression = short
          ? 'pc + 2 + (code[pc] | (code[pc + 1] << 8)).toSigned(16)'
          : 'code[pc] | (code[pc + 1] << 8) | (code[pc + 2] << 16) | (code[pc + 3] << 24)';
      final condition = RegExp(
        r'^if \((.+)\) pc = address;$',
      ).firstMatch(op.body)?.group(1);
      out.writeln(
        condition == null
            ? '$pad pc = $expression;'
            : '$pad if ($condition) { pc = $expression; } else { pc += $width; }',
      );
      out.writeln('$pad $next');
      return;
    } else if (op.immediate != 'none') {
      out.writeln(
        '$pad final index = code[pc] | (code[pc + 1] << 8); pc += 2;',
      );
    }
    out.writeln('$pad ${op.body.trimRight()}');
    final last = op.body.trimRight().split('\n').last.trimLeft();
    if (!last.startsWith('return ') &&
        !last.startsWith('return;') &&
        !last.startsWith('throw') &&
        op.name != 'rethrowCaught') {
      out.writeln('$pad $next');
    }
  }

  for (final op in ops) {
    machine.writeln('        case TypedOp.${op.name}:');
    if (op.name == 'ext') {
      // Secondary dispatch: the next byte selects an extended opcode. Ops that
      // mutate `frame` or leave the interpreter stay inline; the rest run in
      // [_dispatchCold] so the hot switch stays small enough to optimize.
      machine.writeln('          switch (256 + code[pc++]) {');
      for (var i = 0; i < extended.length; i++) {
        if (!inlineCold(extended[i])) continue;
        machine.writeln('            case ${256 + i}:');
        emitCaseBody(extended[i], '            ');
      }
      machine.writeln('''            default:
              cold.op = code[pc - 1];
              cold.pc = pc;
              cold.a = a;
              cold.b = b;
              cold.f = f;
              cold.g = g;
              cold.e = e;
              cold.r = r;
              cold.s = s;
              cold.c = c;
              cold.frame = frame;
              _dispatchCold(program, cold, runtime);
              pc = cold.pc;
              a = cold.a;
              b = cold.b;
              f = cold.f;
              g = cold.g;
              e = cold.e;
              r = cold.r;
              s = cold.s;
              c = cold.c;
              continue dispatch;
          }''');
      continue;
    }
    emitCaseBody(op, '          ');
  }
  machine.writeln(
    """        default: throw StateError('Invalid typed opcode at byte \${pc - 1}');
      }
    }
  }

  // Cold half of the extended dispatch. Ops that do not need to mutate
  // `frame` or leave the interpreter delegate here so `_dispatch` stays
  // small; registers travel in and out through [st].
  @pragma('vm:never-inline')
  static void _dispatchCold(
      TypedProgram program, _ColdCall st, Runtime? runtime) {
    final code = program.code;
    var pc = st.pc;
    var a = st.a, b = st.b;
    var f = st.f, g = st.g;
    var e = st.e;
    Object? r = st.r, s = st.s, c = st.c;
    final frame = st.frame!;
    switch (256 + st.op) {
""",
  );
  for (var i = 0; i < extended.length; i++) {
    if (inlineCold(extended[i])) continue;
    machine.writeln('    case ${256 + i}:');
    emitCaseBody(extended[i], '      ', sink: machine, cold: true);
  }
  machine.writeln(
    '''    default: throw StateError('Invalid extended typed opcode');
    }
    st.pc = pc;
    st.a = a;
    st.b = b;
    st.f = f;
    st.g = g;
    st.e = e;
    st.r = r;
    st.s = s;
    st.c = c;
  }
}
''',
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
  stdout.writeln(
    '${ops.length} typed instructions (${extended.length} extended)',
  );
}
