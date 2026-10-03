import 'package:dart_eval/dart_eval_bridge.dart';

final class TypedLateInitializationError extends Error {
  TypedLateInitializationError(this.message);
  final String message;
  @override
  String toString() => 'LateInitializationError: $message';
}

/// Shared by a late local and all closures that reference it.
final class TypedLateLocal {
  TypedLateLocal(this.name, this.isFinal);
  final String name;
  final bool isFinal;
  static const _uninitialized = Object();
  Object? _value = _uninitialized;
  EvalCallable? initializer;

  @pragma('vm:never-inline')
  void setInitializer(Object? value) => initializer = value as EvalCallable;

  @pragma('vm:never-inline')
  Object? read(Runtime runtime) {
    if (!identical(_value, _uninitialized)) return _value;
    final initialize = initializer;
    if (initialize == null) {
      throw TypedLateInitializationError(
        "Local '$name' has not been initialized.",
      );
    }
    // Recursive reads may finish an inner initialization. Do not mark the
    // slot initialized until a value is available, so failed reads retry.
    final value = initialize.call(runtime, null, null, null, 0);
    if (isFinal && !identical(_value, _uninitialized)) {
      throw TypedLateInitializationError(
        "Local '$name' has been assigned during initialization.",
      );
    }
    return _value = value;
  }

  @pragma('vm:never-inline')
  void write(Object? value) {
    if (isFinal && !identical(_value, _uninitialized)) {
      throw TypedLateInitializationError(
        "Local '$name' has already been initialized.",
      );
    }
    _value = value;
  }
}
