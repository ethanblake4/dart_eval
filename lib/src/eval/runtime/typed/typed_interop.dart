import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/stdlib/core.dart';

/// Boundaries between typed registers and dart_eval's existing object model.
abstract final class TypedInterop {
  @pragma('vm:never-inline')
  static Object? call(
    Runtime? runtime,
    Object? receiver,
    List<Object?> arguments,
  ) {
    if (receiver is Function) return Function.apply(receiver, arguments);
    return _runtime(runtime).invokeTypedObject(receiver, 'call', arguments);
  }

  @pragma('vm:never-inline')
  static Object? invoke(
    Runtime? runtime,
    Object? receiver,
    String name,
    List<Object?> arguments,
  ) => _runtime(runtime).invokeTypedObject(receiver, name, arguments);

  @pragma('vm:never-inline')
  static bool equals(Runtime? runtime, Object? left, Object? right) {
    final a = _primitive(left), b = _primitive(right);
    if (a == null || b == null) return a == null && b == null;
    if (a is $Instance) {
      return toBool(_runtime(runtime).invokeTypedObject(a, '==', [b]));
    }
    return a == b;
  }

  static bool isNull(Object? value) => value == null || value is $null;

  @pragma('vm:never-inline')
  static int toInt(Object? value) => _primitive(value) as int;
  @pragma('vm:never-inline')
  static double toDouble(Object? value) => _primitive(value) as double;
  @pragma('vm:never-inline')
  static bool toBool(Object? value) => _primitive(value) as bool;

  // Only known scalar wrappers can be unboxed without changing object identity
  // or invoking unsupported $InstanceImpl.$value/$reified getters.
  static Object? _primitive(Object? value) => switch (value) {
    $null() => null,
    $num() => value.$value,
    $bool() => value.$value,
    $String() => value.$value,
    _ => value,
  };

  static Runtime _runtime(Runtime? runtime) =>
      runtime ??
      (throw StateError('A Runtime is required to invoke dart_eval objects'));
}
