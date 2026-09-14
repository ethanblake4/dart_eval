part of 'runtime.dart';

/// Physical machine state owned by one invocation. Values never address SSA IDs.
final class _RegisterFrame {
  _RegisterFrame(
    this.pc,
    int registerCount,
    int spillCount,
    this.arguments,
    this.captures,
  ) : registers = List<Object?>.filled(registerCount, null),
      spills = List<Object?>.filled(spillCount, null);

  int pc;
  final List<Object?> registers;
  final List<Object?> spills;
  final List<Object?> arguments;
  final List<Object?> captures;
  final List<Object?> outgoing = [];
  final List<_RegisterTrap> traps = [];
  Object? caught;
  StackTrace? caughtStack;
  _RegisterCompletion? pending;
}

final class _RegisterTrap {
  const _RegisterTrap(this.catchOffset, this.finallyOffset);
  final int catchOffset;
  final int finallyOffset;
}

final class _RegisterCompletion {
  const _RegisterCompletion(this.value, {this.error = false, this.stack});
  final Object? value;
  final bool error;
  final StackTrace? stack;
}

/// Callable closure object used by both register calls and host bridge callbacks.
final class _RegisterClosure extends EvalFunction {
  _RegisterClosure(
    this.offset,
    this.captures,
    this.requiredPositional,
    this.positionalCount,
    this.namedNames, {
    this.boundReceiver = false,
    this.positionalUnboxed = const [],
    this.namedUnboxed = const [],
  });
  final int offset;
  final List<Object?> captures;
  final int requiredPositional;
  final int positionalCount;
  final List<String> namedNames;
  final bool boundReceiver;
  final List<bool> positionalUnboxed;
  final List<bool> namedUnboxed;

  List<Object?> prepare(List<Object?> positional, Map<String, Object?> named) {
    if (positional.length < requiredPositional ||
        positional.length > positionalCount) {
      throw ArgumentError('Invalid positional argument count for closure');
    }
    if (named.keys.any((name) => !namedNames.contains(name))) {
      throw ArgumentError('Unknown named argument for closure');
    }
    Object? adapt(Object? value, bool unboxed) =>
        unboxed && value is $Value ? value.$value : value;
    return [
      if (boundReceiver) captures.first,
      for (var i = 0; i < positionalCount; i++)
        adapt(
          i < positional.length ? positional[i] : null,
          i < positionalUnboxed.length && positionalUnboxed[i],
        ),
      for (var i = 0; i < namedNames.length; i++)
        adapt(named[namedNames[i]], i < namedUnboxed.length && namedUnboxed[i]),
    ];
  }

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    final result = runtime._executeRegisters(
      offset,
      prepare(args, {}),
      captures,
    );
    return result == null ? null : runtime.wrapAlways(result);
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.function);
  @override
  Object get $value => this;
  @override
  Object get $reified => this;
}

extension _RegisterRuntime on Runtime {
  $Value? _registerArgument(Object? value) =>
      value == null || value is $null ? null : wrapAlways(value);

  Object? _registerUnbox(Object? value) =>
      value is $Value ? value.$value : value;

  $Value? _registerBox(Object? value) =>
      value == null ? const $null() : wrapAlways(value);

  Object? _registerInvoke(
    Object? receiver,
    String name,
    List<Object?> arguments,
  ) {
    if (name == 'call') {
      if (receiver is _RegisterClosure) {
        return _executeRegisters(
          receiver.offset,
          receiver.prepare(arguments, {}),
          receiver.captures,
        );
      }
      if (receiver is EvalStaticFunctionPtr) {
        return _executeRegisters(receiver.offset, [
          if (receiver.$this != null) receiver.$this,
          ...arguments,
        ]);
      }
      if (receiver is EvalCallable) {
        return receiver.call(
          this,
          receiver is $Value ? receiver as $Value : null,
          arguments.map(_registerArgument).toList(),
        );
      }
    }
    var object = receiver;
    while (object is $InstanceImpl) {
      final offset = object.evalClass.methods[name];
      if (offset != null)
        return _executeRegisters(offset, [object, ...arguments]);
      if (object.evalSuperclass == null) break;
      object = object.evalSuperclass;
    }
    final boxed = _registerBox(object);
    if (boxed is! $Instance) throw StateError('Cannot invoke $name on $object');
    final callable = boxed.$getProperty(this, name);
    if (callable is! EvalCallable) throw StateError('$name is not callable');
    return (callable as EvalCallable).call(
      this,
      boxed,
      arguments.map(_registerArgument).toList(),
    );
  }

  Object? _registerGetProperty(Object? receiver, String name) {
    var object = receiver;
    while (object is $InstanceImpl) {
      final getter = object.evalClass.getters[name];
      if (getter != null) return _executeRegisters(getter, [object]);
      final method = object.evalClass.methods[name];
      if (method != null) return EvalStaticFunctionPtr(object, method);
      if (object.evalSuperclass == null) break;
      object = object.evalSuperclass;
    }
    final boxed = _registerBox(object);
    if (boxed is! $Instance) throw StateError('Cannot read $name on $object');
    return boxed.$getProperty(this, name);
  }

  void _registerSetProperty(Object? receiver, String name, Object? value) {
    var object = receiver;
    while (object is $InstanceImpl) {
      final setter = object.evalClass.setters[name];
      if (setter != null) {
        _executeRegisters(setter, [object, value]);
        return;
      }
      if (object.evalSuperclass == null) break;
      object = object.evalSuperclass;
    }
    final boxed = _registerBox(object);
    if (boxed is! $Instance) throw StateError('Cannot write $name on $object');
    boxed.$setProperty(this, name, _registerBox(value)!);
  }

  bool _registerIsType(Object? value, int type) {
    final boxed = _registerBox(value)!;
    final actual = boxed.$getRuntimeType(this);
    return actual == type ||
        (actual < _typeTypes.length && _typeTypes[actual].contains(type));
  }
}

extension _RegisterExecution on Runtime {
  Object? _executeRegisters(
    int offset,
    List<Object?> arguments, [
    List<Object?> captures = const [],
  ]) {
    if (offset < 0 ||
        offset >= pr.length ||
        pr[offset] != RegisterOp.entry.index) {
      throw StateError('Invalid register function entry $offset');
    }
    final dataStart = offset + 4 + (pr[offset + 2] as int);
    final registers = pr[dataStart] as int;
    final spills = pr[dataStart + 1] as int;
    if (registers < 0 || registers > 32 || spills < 0) {
      throw StateError('Invalid register frame dimensions');
    }
    final machine = _RegisterFrame(
      offset,
      registers,
      spills,
      List<Object?>.of(arguments),
      List<Object?>.of(captures),
    );
    return _resumeRegisters(machine);
  }

  bool _registerUnwind(_RegisterFrame machine, Object error, StackTrace trace) {
    machine.caught = error is WrappedException ? error.exception : error;
    machine.caughtStack = trace;
    machine.pending = null;
    while (machine.traps.isNotEmpty) {
      final trap = machine.traps.removeLast();
      if (trap.catchOffset >= 0) {
        // Keep the region's finally handler active while executing its catch.
        machine.traps.add(_RegisterTrap(-1, trap.finallyOffset));
        machine.pc = trap.catchOffset;
        return true;
      }
      if (trap.finallyOffset >= 0) {
        machine.pending = _RegisterCompletion(
          machine.caught,
          error: true,
          stack: trace,
        );
        machine.pc = trap.finallyOffset;
        return true;
      }
    }
    return false;
  }

  bool _registerReturnThroughFinally(_RegisterFrame machine, Object? value) {
    while (machine.traps.isNotEmpty) {
      final trap = machine.traps.removeLast();
      if (trap.finallyOffset >= 0) {
        machine.pending = _RegisterCompletion(value);
        machine.pc = trap.finallyOffset;
        return true;
      }
    }
    return false;
  }

  Object? _resumeRegisters(_RegisterFrame machine) {
    final savedFrame = frame;
    final savedArgs = args;
    final savedPc = _prOffset;
    frame = machine.registers;
    args = [];
    try {
      while (true) {
        try {
          _prOffset = machine.pc;
          final opcode = RegisterOp.values[pr[machine.pc++] as int];
          final output = pr[machine.pc++] as int;
          final inputCount = pr[machine.pc++] as int;
          final inputRegisters = <int>[
            for (var i = 0; i < inputCount; i++) pr[machine.pc++] as int,
          ];
          final inputs = [
            for (final register in inputRegisters) machine.registers[register],
          ];
          final dataCount = pr[machine.pc++] as int;
          final data = <int>[
            for (var i = 0; i < dataCount; i++) pr[machine.pc++] as int,
          ];
          Object? result;
          List<Object?> consumeArguments() {
            final outgoing = List<Object?>.of(machine.outgoing);
            machine.outgoing.clear();
            return outgoing;
          }

          switch (opcode) {
            case RegisterOp.entry:
              break;
            case RegisterOp.constant:
              result = data[0] < 0 ? null : _constantPool[data[0]];
              break;
            case RegisterOp.move:
              result = inputs.single;
              break;
            case RegisterOp.swap:
              machine.registers[inputRegisters[0]] = inputs[1];
              machine.registers[inputRegisters[1]] = inputs[0];
              continue;
            case RegisterOp.spill:
              machine.spills[data.single] = inputs.single;
              break;
            case RegisterOp.reload:
              result = machine.spills[data.single];
              break;
            case RegisterOp.parameter:
              result = data.single < machine.arguments.length
                  ? machine.arguments[data.single]
                  : null;
              break;
            case RegisterOp.intAdd:
              result = (inputs[0] as int) + (inputs[1] as int);
              break;
            case RegisterOp.intSub:
              result = (inputs[0] as int) - (inputs[1] as int);
              break;
            case RegisterOp.intMul:
              result = (inputs[0] as int) * (inputs[1] as int);
              break;
            case RegisterOp.intDiv:
              result = (inputs[0] as int) ~/ (inputs[1] as int);
              break;
            case RegisterOp.doubleAdd:
              result = (inputs[0] as num).toDouble() + (inputs[1] as num);
              break;
            case RegisterOp.doubleSub:
              result = (inputs[0] as num).toDouble() - (inputs[1] as num);
              break;
            case RegisterOp.doubleMul:
              result = (inputs[0] as num).toDouble() * (inputs[1] as num);
              break;
            case RegisterOp.doubleDiv:
              result = (inputs[0] as num) / (inputs[1] as num);
              break;
            case RegisterOp.numericMod:
              result = (inputs[0] as num) % (inputs[1] as num);
              break;
            case RegisterOp.numericLt:
              result = (inputs[0] as num) < (inputs[1] as num);
              break;
            case RegisterOp.numericLte:
              result = (inputs[0] as num) <= (inputs[1] as num);
              break;
            case RegisterOp.numericGt:
              result = (inputs[0] as num) > (inputs[1] as num);
              break;
            case RegisterOp.numericGte:
              result = (inputs[0] as num) >= (inputs[1] as num);
              break;
            case RegisterOp.numericEq:
              result = (inputs[0] as num) == (inputs[1] as num);
              break;
            case RegisterOp.numericNe:
              result = (inputs[0] as num) != (inputs[1] as num);
              break;
            case RegisterOp.intLt:
              result = (inputs[0] as int) < (inputs[1] as int);
              break;
            case RegisterOp.intLte:
              result = (inputs[0] as int) <= (inputs[1] as int);
              break;
            case RegisterOp.intGt:
              result = (inputs[0] as int) > (inputs[1] as int);
              break;
            case RegisterOp.intGte:
              result = (inputs[0] as int) >= (inputs[1] as int);
              break;
            case RegisterOp.intEq:
              result = (inputs[0] as int) == (inputs[1] as int);
              break;
            case RegisterOp.intNe:
              result = (inputs[0] as int) != (inputs[1] as int);
              break;
            case RegisterOp.lessThan:
              result = (inputs[0] as num) < (inputs[1] as num);
              break;
            case RegisterOp.increment:
              result = (inputs.single as int) + 1;
              break;
            case RegisterOp.logicalNot:
              result = !(inputs.single as bool);
              break;
            case RegisterOp.logicalAnd:
              result = (inputs[0] as bool) && (inputs[1] as bool);
              break;
            case RegisterOp.logicalOr:
              result = (inputs[0] as bool) || (inputs[1] as bool);
              break;
            case RegisterOp.dynamicEquals:
              result = inputs[0] == null || inputs[0] is $null
                  ? inputs[1] == null || inputs[1] is $null
                  : _registerUnbox(
                      _registerInvoke(inputs[0], '==', [inputs[1]]),
                    );
              break;
            case RegisterOp.isNull:
              result = inputs.single == null || inputs.single is $null;
              break;
            case RegisterOp.boxInt:
              result = inputs.single is $int
                  ? inputs.single
                  : $int(inputs.single as int);
              break;
            case RegisterOp.boxDouble:
              result = inputs.single is $double
                  ? inputs.single
                  : $double(inputs.single as double);
              break;
            case RegisterOp.boxNum:
              result = inputs.single is $num
                  ? inputs.single
                  : $num(inputs.single as num);
              break;
            case RegisterOp.boxBool:
              result = inputs.single is $bool
                  ? inputs.single
                  : $bool(inputs.single as bool);
              break;
            case RegisterOp.boxString:
              result = inputs.single is $String
                  ? inputs.single
                  : $String(inputs.single as String);
              break;
            case RegisterOp.boxList:
              result = inputs.single is $List
                  ? inputs.single
                  : $List.wrap(inputs.single as List);
              break;
            case RegisterOp.boxMap:
              result = inputs.single is $Map
                  ? inputs.single
                  : $Map.wrap(inputs.single as Map);
              break;
            case RegisterOp.boxSet:
              result = inputs.single is $Set
                  ? inputs.single
                  : $Set.wrap(inputs.single as Set);
              break;
            case RegisterOp.boxNull:
              result = const $null();
              break;
            case RegisterOp.maybeBoxNull:
              result = inputs.single ?? const $null();
              break;
            case RegisterOp.unbox:
              result = _registerUnbox(inputs.single);
              break;
            case RegisterOp.jump:
              machine.pc = data.single;
              break;
            case RegisterOp.jumpIfFalse:
              machine.pc = (inputs.single as bool) ? data[1] : data[0];
              break;
            case RegisterOp.jumpIfNull:
              machine.pc = (inputs.single == null || inputs.single is $null)
                  ? data[0]
                  : data[1];
              break;
            case RegisterOp.jumpIfNonNull:
              machine.pc = (inputs.single != null && inputs.single is! $null)
                  ? data[0]
                  : data[1];
              break;
            case RegisterOp.stageArgument:
              machine.outgoing.add(inputs.single);
              break;
            case RegisterOp.call:
              result = _executeRegisters(data.single, consumeArguments());
              break;
            case RegisterOp.invokeExternal:
              result = _bridgeFunctions[data.single](
                this,
                null,
                consumeArguments().map(_registerArgument).toList(),
              );
              break;
            case RegisterOp.invokeDynamic:
              final outgoing = consumeArguments();
              result = _registerInvoke(
                outgoing.first,
                _constantPool[data.single] as String,
                outgoing.sublist(1),
              );
              break;
            case RegisterOp.invokeClosure:
              final outgoing = consumeArguments();
              final closure = outgoing.first;
              final positional = outgoing.sublist(1, 1 + data[0]);
              final names = (_constantPool[data[1]] as List).cast<String>();
              final named = {
                for (var i = 0; i < names.length; i++)
                  names[i]: outgoing[1 + data[0] + i],
              };
              if (closure is _RegisterClosure) {
                result = _executeRegisters(
                  closure.offset,
                  closure.prepare(positional, named),
                  closure.captures,
                );
              } else {
                result = _registerInvoke(closure, 'call', [
                  ...positional,
                  ...named.values,
                ]);
              }
              break;
            case RegisterOp.returnValue:
              final value = inputs.isEmpty ? null : inputs.single;
              if (_registerReturnThroughFinally(machine, value)) continue;
              return value;
            case RegisterOp.returnAsync:
              final value = inputs.length > 1 ? inputs.first : null;
              final completer = _registerUnbox(inputs.last) as Completer;
              if (!completer.isCompleted) completer.complete(value);
              return $Future.wrap(completer.future);
            case RegisterOp.createClosure:
              final signature = _constantPool[data[1]] as Map;
              result = _RegisterClosure(
                data[0],
                consumeArguments(),
                signature['requiredPositional'] as int,
                (signature['positionalTypes'] as List).length,
                (signature['namedNames'] as List).cast<String>(),
                boundReceiver: signature['boundReceiver'] as bool? ?? false,
                positionalUnboxed:
                    (signature['positionalUnboxed'] as List?)?.cast<bool>() ??
                    const [],
                namedUnboxed:
                    (signature['namedUnboxed'] as List?)?.cast<bool>() ??
                    const [],
              );
              break;
            case RegisterOp.loadCapture:
              result = machine.captures[data.single];
              break;
            case RegisterOp.loadFunctionPointer:
              result = EvalStaticFunctionPtr(null, data.single);
              break;
            case RegisterOp.createClass:
              result = $InstanceImpl(
                declaredClasses[data[0]]![_constantPool[data[1]]]!,
                inputs.single as $Instance?,
                List<Object?>.filled(data[2], null),
              );
              break;
            case RegisterOp.loadPropertyStatic:
              result = (inputs.single as $InstanceImpl).values[data.single];
              break;
            case RegisterOp.setPropertyStatic:
              (inputs[0] as $InstanceImpl).values[data.single] = inputs[1];
              break;
            case RegisterOp.loadPropertyDynamic:
              result = _registerGetProperty(
                inputs.single,
                _constantPool[data.single] as String,
              );
              break;
            case RegisterOp.setPropertyDynamic:
              _registerSetProperty(
                inputs[0],
                _constantPool[data.single] as String,
                inputs[1],
              );
              break;
            case RegisterOp.loadSuper:
              result = (inputs.single as $InstanceImpl).evalSuperclass;
              break;
            case RegisterOp.newBridgeSuperShim:
              result = BridgeSuperShim();
              break;
            case RegisterOp.parentBridgeSuperShim:
              (inputs[0] as BridgeSuperShim).bridge = inputs[1] as $Bridge;
              break;
            case RegisterOp.bridgeInstantiate:
              final outgoing = consumeArguments();
              final instance =
                  _bridgeFunctions[data.single](
                        this,
                        null,
                        outgoing.sublist(1).map(_registerArgument).toList(),
                      )
                      as $Instance;
              Runtime.bridgeData[instance] = BridgeData(
                this,
                (outgoing.first as $Instance?)?.$getRuntimeType(this) ?? 1,
                outgoing.first as $Instance? ?? const BridgeDelegatingShim(),
              );
              result = instance;
              break;
            case RegisterOp.loadGlobal:
              final index = data.single;
              if (!_initializedRegisterGlobals.contains(index) &&
                  globals[index] == null &&
                  index < _globalInitializers.length &&
                  _globalInitializers[index] >= 0) {
                _initializedRegisterGlobals.add(index);
                globals[index] = _executeRegisters(
                  _globalInitializers[index],
                  [],
                );
              }
              result = globals[index];
              break;
            case RegisterOp.setGlobal:
              globals[data.single] = inputs.single;
              _initializedRegisterGlobals.add(data.single);
              break;
            case RegisterOp.newList:
              result = <Object?>[];
              break;
            case RegisterOp.indexList:
              result = (inputs[0] as List)[inputs[1] as int];
              break;
            case RegisterOp.listSet:
              (inputs[0] as List)[inputs[1] as int] = inputs[2];
              break;
            case RegisterOp.listAppend:
              (inputs[0] as List).add(inputs[1]);
              break;
            case RegisterOp.newMap:
              result = <Object?, Object?>{};
              break;
            case RegisterOp.mapIndex:
              result = (inputs[0] as Map)[inputs[1]];
              break;
            case RegisterOp.mapSet:
              (inputs[0] as Map)[inputs[1]] = inputs[2];
              break;
            case RegisterOp.newSet:
              result = <Object?>{};
              break;
            case RegisterOp.setAdd:
              (inputs[0] as Set).add(inputs[1]);
              break;
            case RegisterOp.iterableLength:
              result = (inputs.single as Iterable).length;
              break;
            case RegisterOp.newRecord:
              result = $Record(
                (inputs.single as List).cast<Object?>(),
                (_constantPool[data[0]] as Map).cast<String, int>(),
                data[1],
              );
              break;
            case RegisterOp.assertType:
              if (!_registerIsType(inputs.single, data.single))
                throw StateError('Runtime type assertion failed');
              break;
            case RegisterOp.isType:
              result =
                  _registerIsType(inputs.single, data[0]) != (data[1] != 0);
              break;
            case RegisterOp.loadConstantType:
              result = $TypeImpl(data.single);
              break;
            case RegisterOp.loadRuntimeType:
              result = $TypeImpl(
                _registerBox(inputs.single)!.$getRuntimeType(this),
              );
              break;
            case RegisterOp.assertValue:
              if (!(inputs[0] as bool))
                throw WrappedException(
                  AssertionError(_registerUnbox(inputs[1])),
                );
              break;
            case RegisterOp.throwValue:
              throw WrappedException(
                inputs.single ?? StateError('Thrown null'),
              );
            case RegisterOp.rethrowValue:
              Error.throwWithStackTrace(
                WrappedException(
                  inputs.isEmpty ? machine.caught! : inputs.single!,
                ),
                machine.caughtStack ?? StackTrace.current,
              );
            case RegisterOp.enterTry:
              machine.traps.add(_RegisterTrap(data[0], data[1]));
              break;
            case RegisterOp.leaveTry:
              if (machine.traps.isNotEmpty) machine.traps.removeLast();
              break;
            case RegisterOp.caughtException:
              result = _registerBox(machine.caught);
              break;
            case RegisterOp.caughtStackTrace:
              result = wrapAlways(machine.caughtStack);
              break;
            case RegisterOp.resumeCompletion:
              final pending = machine.pending;
              machine.pending = null;
              if (pending != null) {
                if (pending.error)
                  Error.throwWithStackTrace(
                    WrappedException(pending.value!),
                    pending.stack ?? StackTrace.current,
                  );
                if (_registerReturnThroughFinally(machine, pending.value))
                  continue;
                return pending.value;
              }
              break;
            case RegisterOp.awaitValue:
              final subject = _registerUnbox(inputs[1]);
              final completer = _registerUnbox(inputs[0]) as Completer;
              Future<Object?>.value(subject)
                  .then<void>(
                    (value) {
                      machine.registers[output] = value;
                      _resumeRegisters(machine);
                    },
                    onError: (Object error, StackTrace trace) {
                      if (_registerUnwind(machine, error, trace)) {
                        _resumeRegisters(machine);
                      } else {
                        Error.throwWithStackTrace(error, trace);
                      }
                    },
                  )
                  .catchError((Object error, StackTrace trace) {
                    if (!completer.isCompleted) {
                      completer.completeError(
                        error is WrappedException ? error.exception : error,
                        trace,
                      );
                    }
                  });
              return $Future.wrap(completer.future);
          }
          if (output >= 0) machine.registers[output] = result;
        } catch (error, trace) {
          if (!_registerUnwind(machine, error, trace)) {
            if (_registerFailureOffset < 0) {
              _registerFailureOffset = _prOffset;
              _registerFailureFrame = List<Object?>.of(machine.registers);
              _registerFailureArguments = List<Object?>.of(machine.arguments);
            }
            rethrow;
          }
        }
      }
    } finally {
      frame = savedFrame;
      args = savedArgs;
      _prOffset = savedPc;
    }
  }
}
