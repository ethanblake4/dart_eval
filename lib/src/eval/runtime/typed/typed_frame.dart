import 'dart:typed_data';

import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/src/eval/runtime/class.dart';
import 'typed_function.dart';
import 'typed_exception_state.dart';
import 'typed_async.dart';
import 'typed_instance.dart';
import 'typed_program.dart';

/// Register initialization happens once at the public host boundary. Internal
/// calls already have their arguments in the compiler-assigned registers.
class TypedEntry {
  /// Recovery and await continuations have a single boxed result in R.
  const TypedEntry.result(this.r)
    : a = 0,
      b = 0,
      f = 0.0,
      g = 0.0,
      e = false,
      s = null,
      c = null,
      environment = const [],
      typeEnvironmentReceiver = null,
      typeArguments = const [],
      lexicalTypeEnvironmentReceiver = null,
      lexicalTypeArguments = const [];

  const TypedEntry.empty()
    : a = 0,
      b = 0,
      f = 0.0,
      g = 0.0,
      e = false,
      r = null,
      s = null,
      c = null,
      environment = const [],
      typeEnvironmentReceiver = null,
      typeArguments = const [],
      lexicalTypeEnvironmentReceiver = null,
      lexicalTypeArguments = const [];

  const TypedEntry.direct({
    this.a = 0,
    this.b = 0,
    this.f = 0.0,
    this.g = 0.0,
    this.e = false,
    this.r,
    this.s,
    this.c,
    this.environment = const [],
    this.typeEnvironmentReceiver,
    this.typeArguments = const [],
    this.lexicalTypeEnvironmentReceiver,
    this.lexicalTypeArguments = const [],
  });

  static TypedEntry prepare(
    TypedFunction function,
    List<int> integers,
    List<double> doubles,
    List<bool> booleans,
    List<Object?> objects,
    Runtime? runtime,
  ) {
    final layout = function.callLayout;
    var a = 0, b = 0;
    var f = 0.0, g = 0.0;
    var e = false;
    Object? r, s, c;
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
        switch (location.bank) {
          case TypedRegisterBank.integer:
            if (location.index == 0) {
              a = value as int;
            } else {
              b = value as int;
            }
          case TypedRegisterBank.doublePrecision:
            if (location.index == 0) {
              f = value as double;
            } else {
              g = value as double;
            }
          case TypedRegisterBank.boolean:
            e = value as bool;
          case TypedRegisterBank.object:
            if (location.index == 0) {
              r = value;
            } else if (location.index == 1) {
              s = value;
            } else {
              c = value;
            }
        }
      }
    }
    if (integer != integers.length ||
        floating != doubles.length ||
        boolean != booleans.length ||
        object != objects.length) {
      throw ArgumentError('Too many typed entry arguments');
    }
    if (overflow != null) c = overflow;
    return TypedEntry.direct(a: a, b: b, f: f, g: g, e: e, r: r, s: s, c: c);
  }

  /// Values already have the physical representations in the signature.
  /// No boxing, argument rebinding, or host conversion occurs here.
  factory TypedEntry.fromValues(
    TypedFunction function,
    List<Object?> values, {
    List<Object?> environment = const [],
    Object? typeEnvironmentReceiver,
    List<int> typeArguments = const [],
    Object? lexicalTypeEnvironmentReceiver,
    List<int> lexicalTypeArguments = const [],
  }) {
    if (values.length != function.argumentKinds.length) {
      throw ArgumentError(
        'Expected ${function.argumentKinds.length} arguments, got ${values.length}',
      );
    }
    final layout = function.callLayout;
    var a = 0, b = 0;
    var f = 0.0, g = 0.0;
    var e = false;
    Object? r, s, c;
    final overflow = layout.overflowCount == 0
        ? null
        : List<Object?>.filled(layout.overflowCount, null);
    for (var i = 0; i < values.length; i++) {
      final location = layout.arguments[i];
      if (location.overflowIndex case final index?) {
        overflow![index] = values[i];
      } else {
        final value = values[i];
        switch (location.bank) {
          case TypedRegisterBank.integer:
            if (location.index == 0) {
              a = value as int;
            } else {
              b = value as int;
            }
          case TypedRegisterBank.doublePrecision:
            if (location.index == 0) {
              f = value as double;
            } else {
              g = value as double;
            }
          case TypedRegisterBank.boolean:
            e = value as bool;
          case TypedRegisterBank.object:
            if (location.index == 0) {
              r = value;
            } else if (location.index == 1) {
              s = value;
            } else {
              c = value;
            }
        }
      }
    }
    if (overflow != null) c = overflow;
    return TypedEntry.direct(
      a: a,
      b: b,
      f: f,
      g: g,
      e: e,
      r: r,
      s: s,
      c: c,
      environment: environment,
      typeEnvironmentReceiver: typeEnvironmentReceiver,
      typeArguments: typeArguments,
      lexicalTypeEnvironmentReceiver: lexicalTypeEnvironmentReceiver,
      lexicalTypeArguments: lexicalTypeArguments,
    );
  }

  final int a, b;
  final double f, g;
  final bool e;
  final Object? r, s, c;
  final List<Object?> environment;
  final Object? typeEnvironmentReceiver;
  final List<int> typeArguments;
  final Object? lexicalTypeEnvironmentReceiver;
  final List<int> lexicalTypeArguments;
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
  TypedFrame _childFor(TypedFunction callee) {
    var child = _child;
    if (child == null) {
      child = _child = TypedFrame(callee, this);
    } else if (!identical(child.function, callee)) {
      if (child._child == null) {
        child._retarget(callee);
      } else {
        child = _child = TypedFrame(callee, this);
      }
    }
    return child;
  }

  @pragma('vm:never-inline')
  TypedFrame enterStatic(
    TypedProgram program,
    int index,
    int pc, {
    Object? typeEnvironmentReceiver,
    List<int> typeArguments = const [],
  }) {
    final child = _childFor(program.functions[index]);
    child.returnPc = pc;
    child.environment = const [];
    child.typeEnvironmentReceiver = typeEnvironmentReceiver;
    child.typeArguments = typeArguments;
    child.lexicalTypeEnvironmentReceiver = null;
    child.lexicalTypeArguments = const [];
    child.pendingTypeEnvironmentReceiver = null;
    child.pendingTypeArguments = const [];
    return child;
  }

  @pragma('vm:never-inline')
  TypedFrame enter(
    TypedFunction callee,
    int pc, {
    Object? typeEnvironmentReceiver,
    List<int> typeArguments = const [],
  }) {
    final child = _childFor(callee);
    child.returnPc = pc;
    child.environment = const [];
    child.typeEnvironmentReceiver = typeEnvironmentReceiver;
    child.typeArguments = typeArguments;
    child.lexicalTypeEnvironmentReceiver = null;
    child.lexicalTypeArguments = const [];
    child.pendingTypeEnvironmentReceiver = null;
    child.pendingTypeArguments = const [];
    return child;
  }

  @pragma('vm:never-inline')
  TypedFrame enterClosure(
    TypedFunction callee,
    int pc,
    List<Object?> captures, {
    Object? typeEnvironmentReceiver,
    List<int> typeArguments = const [],
    Object? lexicalTypeEnvironmentReceiver,
    List<int> lexicalTypeArguments = const [],
  }) {
    // Keep the cached-frame path in one Dart call, just like ordinary calls.
    final child = _childFor(callee);
    child.returnPc = pc;
    child.environment = captures;
    child.typeEnvironmentReceiver = typeEnvironmentReceiver;
    child.typeArguments = typeArguments;
    child.lexicalTypeEnvironmentReceiver = lexicalTypeEnvironmentReceiver;
    child.lexicalTypeArguments = lexicalTypeArguments;
    child.pendingTypeEnvironmentReceiver = null;
    child.pendingTypeArguments = const [];
    return child;
  }

  @pragma('vm:never-inline')
  Object? captureAt(int index) => environment[index];

  @pragma('vm:never-inline')
  TypedFrame leave() {
    returnPc = -1;
    // Compiler continuations and exception unwinding have already popped this
    // frame's handlers. Ordinary returns need no handler-state check.
    environment = const [];
    typeEnvironmentReceiver = null;
    typeArguments = const [];
    _ownerTypeReceiver = null;
    _ownerTypeId = null;
    lexicalTypeEnvironmentReceiver = null;
    lexicalTypeArguments = const [];
    pendingTypeEnvironmentReceiver = null;
    pendingTypeArguments = const [];
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

  /// Reuse inactive leaf storage across differing callees. Frames with cached
  /// children retain function-specific call trees: retargeting those regresses
  /// recursive workloads even when it reduces allocations.
  @pragma('vm:never-inline')
  void _retarget(TypedFunction callee) {
    assert(returnPc < 0 && asyncState == null);
    assert(exceptions == null || exceptions!.depth == 0);
    if (intSpills.length < callee.intSpillCount) {
      intSpills = Int64List(callee.intSpillCount);
    }
    if (doubleSpills.length < callee.doubleSpillCount) {
      doubleSpills = Float64List(callee.doubleSpillCount);
    }
    if (boolSpills.length < callee.boolSpillCount) {
      boolSpills = Uint8List(callee.boolSpillCount);
    }
    if (objectSpills.length < callee.objectSpillCount) {
      objectSpills = List<Object?>.filled(callee.objectSpillCount, null);
    }
    if (objectOutgoing.length < callee.objectOutgoingCount) {
      objectOutgoing = List<Object?>.filled(callee.objectOutgoingCount, null);
    }
    function = callee;
  }

  TypedFunction function;
  TypedExceptionState? exceptions;
  TypedAsyncState? asyncState;
  TypedFrame? parent;
  TypedFrame? _child;
  int returnPc = -1;

  /// A suspended invocation must never be reused by its former caller.
  /// Ordinary calls and returns do not inspect async state.
  @pragma('vm:never-inline')
  void detachAsync() {
    final caller = parent;
    if (caller != null) {
      if (identical(caller._child, this)) caller._child = null;
      if (caller.objectOutgoing.isNotEmpty) {
        caller.objectOutgoing.fillRange(0, caller.objectOutgoing.length, null);
      }
    }
    parent = null;
    returnPc = -1;
  }

  /// Only consulted after a native unwind. An inactive cached child has no
  /// return address; calls already set that address as part of their ABI.
  TypedFrame get activeFrame {
    var frame = this;
    while (true) {
      final child = frame._child;
      if (child == null || child.returnPc < 0) return frame;
      frame = child;
    }
  }

  List<Object?> environment = const [];
  Object? typeEnvironmentReceiver;
  List<int> typeArguments = const [];
  Object? lexicalTypeEnvironmentReceiver;
  List<int> lexicalTypeArguments = const [];

  Object? get effectiveTypeEnvironmentReceiver =>
      typeEnvironmentReceiver ?? lexicalTypeEnvironmentReceiver;

  List<int> get effectiveTypeArguments =>
      typeArguments.isEmpty ? lexicalTypeArguments : typeArguments;

  Object? _ownerTypeReceiver;
  int? _ownerTypeId;

  /// Resolved `dispatchRoot` runtime type of [effectiveTypeEnvironmentReceiver],
  /// or null when the receiver is not a TypedInstance. Cached per receiver —
  /// an instance's runtime type is stable for the frame's lifetime.
  int? typeEnvironmentOwnerType(Runtime runtime) {
    final receiver = effectiveTypeEnvironmentReceiver;
    if (!identical(_ownerTypeReceiver, receiver)) {
      _ownerTypeReceiver = receiver;
      _ownerTypeId = switch (receiver) {
        TypedInstance() => receiver.dispatchRoot.$getRuntimeType(runtime),
        // Constructors adopt their trailing runtime-type-id argument.
        int() => receiver,
        _ => null,
      };
    }
    return _ownerTypeId;
  }

  Object? pendingTypeEnvironmentReceiver;
  List<int> pendingTypeArguments = const [];
  Int64List intSpills;
  Float64List doubleSpills;
  Uint8List boolSpills;
  List<Object?> objectSpills, objectOutgoing;
}
