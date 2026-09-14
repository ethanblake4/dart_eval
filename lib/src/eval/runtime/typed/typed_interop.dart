import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

/// The dynamic-call boundary uses boxed language values exclusively.
///
/// The compiler emits every scalar box and unbox operation. Host functions must
/// use an explicit bridge wrapper, such as $Function or $Closure.
abstract final class TypedInterop {
  @pragma('vm:never-inline')
  static $Value? call(
    Runtime? runtime,
    Object? receiver,
    List<$Value?> arguments,
  ) => receiver is TypedHostFunction
      ? receiver.invokeHost(runtime, arguments)
      : _runtime(runtime).invokeTypedObject(receiver, 'call', arguments);

  @pragma('vm:never-inline')
  static $Value? invoke(
    Runtime? runtime,
    Object? receiver,
    String name,
    List<$Value?> arguments,
  ) => _runtime(runtime).invokeTypedObject(receiver, name, arguments);

  @pragma('vm:never-inline')
  static bool equals(Runtime? runtime, Object? left, Object? right) {
    final a = left as $Value?, b = right as $Value?;
    if (isNull(a) || isNull(b)) return isNull(a) && isNull(b);
    // $Object is the explicit adapter for a native host object's operators.
    // Subclasses may override bridge dispatch and must use their own methods.
    if (a.runtimeType == $Object) {
      return (a as $Object).$value == exportExternal(b);
    }
    return toBool(_runtime(runtime).invokeTypedObject(a, '==', [b]));
  }

  static bool isNull(Object? value) => value == null;

  @pragma('vm:never-inline')
  static int toInt(Object? value) => (value as $int).$value;
  @pragma('vm:never-inline')
  static double toDouble(Object? value) => (value as $double).$value;
  @pragma('vm:never-inline')
  static bool toBool(Object? value) => (value as $bool).$value;
  @pragma('vm:never-inline')
  static String toStringValue(Object? value) => (value as $String).$value;

  /// Normalize once when a host enters the typed machine.
  static $Value? boxExternal(Object? value, {Runtime? runtime}) =>
      switch (value) {
        null || $null() => null,
        $Value() => value,
        int() => $int(value),
        double() => $double(value),
        bool() => $bool(value),
        String() => $String(value),
        Function() => TypedHostFunction(value),
        _ => runtime == null ? $Object(value) : runtime.wrap(value),
      };

  /// Export scalar wrappers once when control returns to host Dart.
  /// Evaluated instances retain their identity and never read $value.
  static Object? exportExternal(Object? value) => switch (value) {
    $null() => null,
    $num() => value.$value,
    $bool() => value.$value,
    $String() => value.$value,
    $Object() => value.$value,
    _ => value,
  };

  static Runtime _runtime(Runtime? runtime) =>
      runtime ??
      (throw StateError('A Runtime is required to invoke dart_eval objects'));
}

/// Explicit adapter for a native Dart function at the public host boundary.
final class TypedHostFunction extends EvalFunction {
  TypedHostFunction(this.function);
  final Function function;

  $Value? invokeHost(Runtime? runtime, List<$Value?> arguments) =>
      TypedInterop.boxExternal(
        Function.apply(
          function,
          arguments.map(TypedInterop.exportExternal).toList(),
        ),
        runtime: runtime,
      );

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) =>
      invokeHost(runtime, args);

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.function);
}
