import 'dart:typed_data';
import 'typed_function.dart';

/// A suspended caller owns its outgoing buffers. Its callee borrows them as
/// read-only arguments, and has separate outgoing buffers for recursive calls.
class TypedFrame {
  TypedFrame._(
    this.function,
    this.parent,
    this.intArguments,
    this.doubleArguments,
    this.boolArguments,
    this.objectArguments,
  ) : intSpills = Int64List(function.intSpillCount),
      doubleSpills = Float64List(function.doubleSpillCount),
      boolSpills = Uint8List(function.boolSpillCount),
      objectSpills = List<Object?>.filled(function.objectSpillCount, null),
      intOutgoing = Int64List(function.intOutgoingCount),
      doubleOutgoing = Float64List(function.doubleOutgoingCount),
      boolOutgoing = Uint8List(function.boolOutgoingCount),
      objectOutgoing = List<Object?>.filled(function.objectOutgoingCount, null);

  @pragma('vm:never-inline')
  static TypedFrame entry(
    TypedFunction function,
    List<int> integers,
    List<double> doubles,
    List<bool> booleans,
    List<Object?> objects,
  ) {
    if (integers.length < function.intArgumentCount ||
        doubles.length < function.doubleArgumentCount ||
        booleans.length < function.boolArgumentCount ||
        objects.length < function.objectArgumentCount) {
      throw ArgumentError('Insufficient typed entry arguments');
    }
    return TypedFrame._(
      function,
      null,
      Int64List.fromList(integers),
      Float64List.fromList(doubles),
      Uint8List.fromList([for (final b in booleans) b ? 1 : 0]),
      List<Object?>.of(objects),
    );
  }

  /// Reuse a frame for repeated calls at the same depth. Recursive invocations
  /// still have distinct storage, and every run owns its entire frame chain.
  @pragma('vm:never-inline')
  TypedFrame enter(TypedFunction callee, int pc, int bank) {
    var child = _child;
    if (child == null || !identical(child.function, callee)) {
      child = _child = TypedFrame._(
        callee,
        this,
        intOutgoing,
        doubleOutgoing,
        boolOutgoing,
        objectOutgoing,
      );
    } else {
      if (child.intSpills.isNotEmpty)
        child.intSpills.fillRange(0, child.intSpills.length, 0);
      if (child.doubleSpills.isNotEmpty)
        child.doubleSpills.fillRange(0, child.doubleSpills.length, 0);
      if (child.boolSpills.isNotEmpty)
        child.boolSpills.fillRange(0, child.boolSpills.length, 0);
      if (child.intOutgoing.isNotEmpty)
        child.intOutgoing.fillRange(0, child.intOutgoing.length, 0);
      if (child.doubleOutgoing.isNotEmpty)
        child.doubleOutgoing.fillRange(0, child.doubleOutgoing.length, 0);
      if (child.boolOutgoing.isNotEmpty)
        child.boolOutgoing.fillRange(0, child.boolOutgoing.length, 0);
    }
    child.returnPc = pc;
    child.returnBank = bank;
    return child;
  }

  @pragma('vm:never-inline')
  TypedFrame leave() {
    // Cached inactive frames must not retain arbitrary application objects.
    if (objectSpills.isNotEmpty)
      objectSpills.fillRange(0, objectSpills.length, null);
    if (objectOutgoing.isNotEmpty)
      objectOutgoing.fillRange(0, objectOutgoing.length, null);
    final caller = parent!;
    // The callee borrows these arguments only while active. Callers stage
    // fresh arguments for their next call.
    if (caller.objectOutgoing.isNotEmpty)
      caller.objectOutgoing.fillRange(0, caller.objectOutgoing.length, null);
    return caller;
  }

  /// Host callbacks may retain their argument list or reenter the interpreter.
  /// Give them a snapshot, never the VM's mutable outgoing storage.
  @pragma('vm:never-inline')
  List<Object?> takeObjectArguments(int count) {
    final arguments = objectOutgoing.sublist(0, count);
    if (objectOutgoing.isNotEmpty)
      objectOutgoing.fillRange(0, objectOutgoing.length, null);
    return arguments;
  }

  final TypedFunction function;
  final TypedFrame? parent;
  TypedFrame? _child;
  int returnPc = 0;
  int returnBank = -1;
  final Int64List intArguments, intSpills, intOutgoing;
  final Float64List doubleArguments, doubleSpills, doubleOutgoing;
  final Uint8List boolArguments, boolSpills, boolOutgoing;
  final List<Object?> objectArguments, objectSpills, objectOutgoing;
}
