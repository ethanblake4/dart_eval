import 'dart:typed_data';

import '../runtime.dart';
import 'typed_machine.g.dart';
import 'typed_program.dart';

/// Mutable storage belongs to a runtime, never to its shareable program.
final class TypedGlobalState {
  TypedGlobalState(this.program, this.runtime)
    : values = List<Object?>.filled(program.globals.length, null),
      _states = Uint8List(program.globals.length);

  final TypedProgram program;
  final Runtime runtime;
  final List<Object?> values;
  final Uint8List _states;

  static TypedGlobalState _state(Runtime? runtime) =>
      runtime?.typedGlobals ??
      (throw StateError('A Runtime is required to access globals'));

  Object? _read(int index) =>
      _states[index] == 2 ? values[index] : _initialize(index);

  @pragma('vm:never-inline')
  Object? _initialize(int index) {
    final descriptor = program.globals[index];
    if (_states[index] == 1) {
      throw StateError('Cyclic initialization of global ${descriptor.name}');
    }
    if (descriptor.initializerFunction < 0) {
      if (descriptor.isLate) {
        throw StateError('Global ${descriptor.name} has not been initialized');
      }
      _states[index] = 2;
      return null;
    }
    _states[index] = 1;
    try {
      final value = TypedMachine.runRaw(
        program,
        entryFunction: descriptor.initializerFunction,
        runtime: runtime,
      );
      values[index] = value;
      _states[index] = 2;
      return value;
    } catch (_) {
      // An explicit assignment made by the initializer survives an exception.
      if (_states[index] == 1) _states[index] = 0;
      rethrow;
    }
  }

  void write(int index, Object? value) {
    final descriptor = program.globals[index];
    if (descriptor.isFinal && _states[index] == 2) {
      throw StateError(
        'Global ${descriptor.name} has already been initialized',
      );
    }
    values[index] = value;
    _states[index] = 2;
  }

  // These typed helper boundaries prevent a global table or generic value
  // conversion from becoming live across every iteration of the switch loop.
  @pragma('vm:never-inline')
  static int loadInteger(Runtime? runtime, int index) =>
      _state(runtime)._read(index) as int;
  @pragma('vm:never-inline')
  static double loadDouble(Runtime? runtime, int index) =>
      _state(runtime)._read(index) as double;
  @pragma('vm:never-inline')
  static bool loadBoolean(Runtime? runtime, int index) =>
      _state(runtime)._read(index) as bool;
  @pragma('vm:never-inline')
  static Object? loadObject(Runtime? runtime, int index) =>
      _state(runtime)._read(index);

  @pragma('vm:never-inline')
  static void storeInteger(Runtime? runtime, int index, int value) =>
      _state(runtime).write(index, value);
  @pragma('vm:never-inline')
  static void storeDouble(Runtime? runtime, int index, double value) =>
      _state(runtime).write(index, value);
  @pragma('vm:never-inline')
  static void storeBoolean(Runtime? runtime, int index, bool value) =>
      _state(runtime).write(index, value);
  @pragma('vm:never-inline')
  static void storeObject(Runtime? runtime, int index, Object? value) =>
      _state(runtime).write(index, value);
}
