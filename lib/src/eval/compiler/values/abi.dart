import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/values/value_rep.dart';

export 'package:dart_eval/src/eval/compiler/values/value_rep.dart';

/// What kind of callable an ABI belongs to. Drives the boxing convention
/// for its parameters and result.
enum CallableKind {
  /// Top-level/static functions: scalars cross the boundary unboxed.
  function,

  /// Instance members (methods, getters, setters): the dynamic-dispatch
  /// ABI is always boxed so bridge interop sees a consistent interface.
  method,

  /// Constructors: scalars cross the boundary unboxed.
  constructor,

  /// Closures: always boxed (closure values are `$Instance`s).
  closure,

  /// Constructor initializer conventions (`this.x` / `super.y` formals):
  /// same as the constructor boundary.
  initializer,
}

/// Boxing conventions for values that cross a boundary — call arguments,
/// results, field storage, collection elements. The convention is a
/// property of the boundary, not of the type.
abstract final class Abi {
  /// The rep a value of [type] has when it crosses a function boundary
  /// unboxed-eligible: int/double/bool in their own banks when non-nullable
  /// and not a type parameter, `boxed` otherwise. (String deliberately
  /// stays boxed at call boundaries.)
  static ValueRep unboxedAcrossCalls(TypeRef type) {
    if (type.nullable || type.isTypeParameter) return ValueRep.boxed;
    if (type.file != dartCoreFile) return ValueRep.boxed;
    return switch (type.name) {
      'int' => ValueRep.int,
      'double' => ValueRep.double,
      'bool' => ValueRep.bool,
      _ => ValueRep.boxed,
    };
  }

  /// The rep an argument must have when passed for a parameter of [type]
  /// declared on a [kind] callable. [erased] marks parameters whose
  /// annotation names a type parameter of the enclosing declaration —
  /// those take the erased-object (boxed) ABI even on scalars.
  static ValueRep parameter(TypeRef type, CallableKind kind, {bool erased = false}) {
    if (erased) return ValueRep.boxed;
    switch (kind) {
      case CallableKind.function:
      case CallableKind.constructor:
      case CallableKind.initializer:
        return unboxedAcrossCalls(type);
      case CallableKind.method:
      case CallableKind.closure:
        return ValueRep.boxed;
    }
  }

  /// The rep a callable of [kind] returns a value of [type] in.
  /// [isAsync] forces boxed (async results travel as `Future` objects).
  /// `==`/`!=` methods on evaluated classes return their bool unboxed;
  /// pass [unboxedBoolResult] to model that.
  static ValueRep result(
    TypeRef type,
    CallableKind kind, {
    bool isAsync = false,
    bool unboxedBoolResult = false,
  }) {
    if (isAsync) return ValueRep.boxed;
    switch (kind) {
      case CallableKind.function:
      case CallableKind.constructor:
      case CallableKind.initializer:
        return unboxedAcrossCalls(type);
      case CallableKind.method:
        if (unboxedBoolResult) return unboxedAcrossCalls(type);
        return ValueRep.boxed;
      case CallableKind.closure:
        return ValueRep.boxed;
    }
  }

  /// Field storage is always boxed.
  static const fieldStorage = ValueRep.boxed;

  /// Collection elements are always boxed.
  static const collectionElement = ValueRep.boxed;
}

/// The full ABI of one callable: the rep of each parameter slot and of the
/// result. `null` result means the callable returns no value (`void`).
class CallableAbi {
  const CallableAbi(this.parameters, this.result);

  final List<ValueRep> parameters;
  final ValueRep? result;
}
