import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/bridge/runtime_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/type.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import 'typed_instance.dart';
import 'typed_host_collections.dart';
import 'typed_program.dart';
import 'typed_closure.dart';

/// The dynamic-call boundary uses boxed language values exclusively.
///
/// The compiler emits every scalar box and unbox operation. Host functions must
/// use an explicit bridge wrapper, such as $Function or $Closure.
abstract final class TypedInterop {
  static $Value runtimeTypeOf(Runtime? runtime, Object? value) {
    final target = _runtime(runtime);
    return $TypeImpl(
      value == null
          ? target.lookupType(CoreTypes.nullType)
          : (value as $Value).$getRuntimeType(target),
    );
  }

  static BridgeSuperShim newBridgeSuperShim() => BridgeSuperShim();

  static void parentBridgeSuperShim(Object? shim, Object? parent) {
    (shim as BridgeSuperShim).bridge = parent as $Bridge;
  }

  static $Instance attachBridge(
    Runtime? runtime,
    Object? host,
    Object? subclass,
    int typeId,
  ) {
    final target = _runtime(runtime);
    final instance = host as $Instance;
    Runtime.bridgeData[instance] = BridgeData(
      target,
      typeId,
      subclass as $Instance?,
    );
    return instance;
  }

  /// Resolve metadata outside the switch so its table does not stay live in
  /// the arithmetic loop. Generated bridges consume canonical R/S/C directly.
  @pragma('vm:never-inline')
  static $Value? invokeExternal(
    TypedProgram program,
    Runtime? runtime,
    Object? first,
    Object? second,
    Object? rest,
    int siteIndex,
  ) {
    final target = _runtime(runtime);
    final site = program.externalCalls[siteIndex];
    return target.invokeTypedExternal(
      site.externalFunctionId,
      site.argumentCount,
      first,
      second,
      rest,
    );
  }

  @pragma('vm:never-inline')
  static $Value? call(
    Runtime? runtime,
    Object? receiver,
    List<$Value?> arguments,
  ) => switch (receiver) {
    TypedClosure() => receiver.invoke(arguments, runtime: runtime),
    TypedHostFunction() => receiver.invokeHost(runtime, arguments),
    TypedMember() => receiver.invokeClosure(arguments, runtime: runtime),
    TypedInstance() => receiver.invoke('call', arguments, runtime: runtime),
    _ => _runtime(runtime).invokeTypedObject(receiver, 'call', arguments),
  };

  @pragma('vm:never-inline')
  static $Value? invoke(
    Runtime? runtime,
    Object? receiver,
    String name,
    List<$Value?> arguments,
  ) => receiver is TypedInstance
      ? receiver.invoke(name, arguments, runtime: runtime)
      : _runtime(runtime).invokeTypedObject(receiver, name, arguments);

  static $Value? getProperty(Runtime? runtime, Object? receiver, String name) {
    final value = receiver is TypedInstance
        ? receiver.getProperty(name, runtime: runtime)
        : (receiver as $Instance).$getProperty(_runtime(runtime), name);
    return value is $null ? null : value;
  }

  static void setProperty(
    Runtime? runtime,
    Object? receiver,
    String name,
    $Value? value,
  ) {
    if (receiver is TypedInstance) {
      receiver.setProperty(name, value, runtime: runtime);
    } else {
      (receiver as $Instance).$setProperty(
        _runtime(runtime),
        name,
        value ?? const $null(),
      );
    }
  }

  @pragma('vm:never-inline')
  static bool equals(Runtime? runtime, Object? left, Object? right) {
    final a = left as $Value?, b = right as $Value?;
    if (isNull(a) || isNull(b)) return isNull(a) && isNull(b);
    if (a is EvalFunction) return a == b;
    // $Object is the explicit adapter for a native host object's operators.
    // Subclasses may override bridge dispatch and must use their own methods.
    if (a.runtimeType == $Object) {
      return (a as $Object).$value == exportExternal(b, runtime: runtime);
    }
    return toBool(invoke(runtime, a, '==', [b]));
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
        List() || Map() || Set() => TypedHostCollections.box(value, runtime),
        _ => runtime == null ? $Object(value) : runtime.wrap(value),
      };

  /// Export scalar wrappers once when control returns to host Dart.
  /// Guest-only instances retain their identity; bridge subclasses expose their
  /// existing native bridge object.
  static Object? exportExternal(Object? value, {Runtime? runtime}) =>
      switch (value) {
        $null() => null,
        TypedHostFunction() => value.function,
        TypedInstance() => value.bridge ?? value,
        EvalFunction() => value,
        $List() => TypedHostCollections.export(value.$value, value, runtime),
        $Map() => TypedHostCollections.export(value.$value, value, runtime),
        $Set() => TypedHostCollections.export(value.$value, value, runtime),
        $Value() => value.$value,
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

  $Value? invokeHost(
    Runtime? runtime,
    List<$Value?> arguments, {
    Map<String, $Value?> named = const {},
  }) => TypedInterop.boxExternal(
    Function.apply(
      function,
      arguments
          .map((value) => TypedInterop.exportExternal(value, runtime: runtime))
          .toList(),
      named.isEmpty
          ? null
          : {
              for (final entry in named.entries)
                Symbol(entry.key): TypedInterop.exportExternal(
                  entry.value,
                  runtime: runtime,
                ),
            },
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
