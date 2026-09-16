import 'dart:typed_data';

import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/src/eval/runtime/class.dart';
import 'typed_function.dart';

/// Register initialization happens once at the public host boundary. Internal
/// calls already have their arguments in the compiler-assigned registers.
class TypedEntry {
  TypedEntry._(List<Object?> registers, {this.environment = const []})
    : a = registers[0] as int,
      b = registers[1] as int,
      f = registers[2] as double,
      g = registers[3] as double,
      e = registers[4] as bool,
      x = registers[5] as bool,
      r = registers[6],
      s = registers[7],
      c = registers[8];

  static TypedEntry prepare(
    TypedFunction function,
    List<int> integers,
    List<double> doubles,
    List<bool> booleans,
    List<Object?> objects,
    Runtime? runtime,
  ) {
    final layout = function.callLayout;
    final registers = <Object?>[0, 0, 0.0, 0.0, false, false, null, null, null];
    final overflow = layout.overflowCount == 0
        ? null
        : List<Object?>.filled(layout.overflowCount, null);
    var integer = 0, floating = 0, boolean = 0, object = 0;
    for (var i = 0; i < function.argumentKinds.length; i++) {
      final Object? value;
      switch (function.argumentKinds[i]) {
        case TypedArgumentKind.integer:
          if (integer == integers.length) {
            throw ArgumentError('Missing int argument');
          }
          value = integers[integer++];
        case TypedArgumentKind.doublePrecision:
          if (floating == doubles.length) {
            throw ArgumentError('Missing double argument');
          }
          value = doubles[floating++];
        case TypedArgumentKind.boolean:
          if (boolean == booleans.length) {
            throw ArgumentError('Missing bool argument');
          }
          value = booleans[boolean++];
        case TypedArgumentKind.string:
          if (object == objects.length) {
            throw ArgumentError('Missing String argument');
          }
          value = objects[object++] as String;
        case TypedArgumentKind.object:
          if (object == objects.length) {
            throw ArgumentError('Missing object argument');
          }
          value = TypedInterop.boxExternal(objects[object++], runtime: runtime);
      }
      final location = layout.arguments[i];
      if (location.overflowIndex case final index?) {
        overflow![index] = value;
      } else {
        registers[location.bank.index * 2 + location.index] = value;
      }
    }
    if (integer != integers.length ||
        floating != doubles.length ||
        boolean != booleans.length ||
        object != objects.length) {
      throw ArgumentError('Too many typed entry arguments');
    }
    if (overflow != null) registers[8] = overflow;
    return TypedEntry._(registers);
  }

  /// Values already have the physical representations in the signature.
  /// No boxing, argument rebinding, or host conversion occurs here.
  factory TypedEntry.fromValues(
    TypedFunction function,
    List<Object?> values, {
    List<Object?> environment = const [],
  }) {
    if (values.length != function.argumentKinds.length) {
      throw ArgumentError(
        'Expected ${function.argumentKinds.length} arguments, got ${values.length}',
      );
    }
    final layout = function.callLayout;
    final registers = <Object?>[0, 0, 0.0, 0.0, false, false, null, null, null];
    final overflow = layout.overflowCount == 0
        ? null
        : List<Object?>.filled(layout.overflowCount, null);
    for (var i = 0; i < values.length; i++) {
      final location = layout.arguments[i];
      if (location.overflowIndex case final index?) {
        overflow![index] = values[i];
      } else {
        registers[location.bank.index * 2 + location.index] = values[i];
      }
    }
    if (overflow != null) registers[8] = overflow;
    return TypedEntry._(registers, environment: environment);
  }

  final int a, b;
  final double f, g;
  final bool e, x;
  final Object? r, s, c;
  final List<Object?> environment;
}

/// Each active invocation owns spills and one optional outgoing list. A callee
/// receives the caller's list in C and borrows it until returning. It uses its
/// own outgoing list for nested calls, so argument lists need no copy.
class TypedFrame {
  TypedFrame(this.function, [this.parent])
    : intSpills = Int64List(function.intSpillCount),
      doubleSpills = Float64List(function.doubleSpillCount),
      boolSpills = Uint8List(function.boolSpillCount),
      objectSpills = List<Object?>.filled(function.objectSpillCount, null),
      objectOutgoing = function.objectOutgoingCount == 0
          ? const []
          : List<Object?>.filled(function.objectOutgoingCount, null);

  /// Reuse a frame for repeated calls at the same depth. Recursive invocations
  /// still have distinct storage, and every run owns its entire frame chain.
  @pragma('vm:never-inline')
  TypedFrame enter(TypedFunction callee, int pc) {
    var child = _child;
    if (child == null || !identical(child.function, callee)) {
      child = _child = TypedFrame(callee, this);
    }
    child.returnPc = pc;
    child.environment = const [];
    return child;
  }

  @pragma('vm:never-inline')
  TypedFrame enterClosure(
    TypedFunction callee,
    int pc,
    List<Object?> captures,
  ) {
    // Keep the cached-frame path in one Dart call, just like ordinary calls.
    var child = _child;
    if (child == null || !identical(child.function, callee)) {
      child = _child = TypedFrame(callee, this);
    }
    child.returnPc = pc;
    child.environment = captures;
    return child;
  }

  @pragma('vm:never-inline')
  Object? captureAt(int index) => environment[index];

  @pragma('vm:never-inline')
  TypedFrame leave() {
    environment = const [];
    // Cached inactive frames must not retain arbitrary application objects.
    if (objectSpills.isNotEmpty) {
      objectSpills.fillRange(0, objectSpills.length, null);
    }
    if (objectOutgoing.isNotEmpty) {
      objectOutgoing.fillRange(0, objectOutgoing.length, null);
    }
    final caller = parent!;
    if (caller.objectOutgoing.isNotEmpty) {
      caller.objectOutgoing.fillRange(0, caller.objectOutgoing.length, null);
    }
    return caller;
  }

  /// Host callbacks may retain their argument list or reenter the interpreter.
  /// Give them a snapshot, never the VM's mutable outgoing storage.
  @pragma('vm:never-inline')
  List<$Value?> takeObjectArguments(int count) {
    final arguments = List<$Value?>.generate(
      count,
      (i) => objectOutgoing[i] as $Value?,
      growable: false,
    );
    if (objectOutgoing.isNotEmpty) {
      objectOutgoing.fillRange(0, objectOutgoing.length, null);
    }
    return arguments;
  }

  final TypedFunction function;
  final TypedFrame? parent;
  TypedFrame? _child;
  int returnPc = 0;
  List<Object?> environment = const [];
  final Int64List intSpills;
  final Float64List doubleSpills;
  final Uint8List boolSpills;
  final List<Object?> objectSpills, objectOutgoing;
}
