// ignore_for_file: non_constant_identifier_names

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_instance.dart';

/// A bridge class can be extended inside the dart_eval VM and used both in
/// and outside of it.
mixin $Bridge<T> on Object implements $Value, $Instance {
  $Value? $bridgeGet(String identifier);

  void $bridgeSet(String identifier, $Value value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    final subclass = Runtime.bridgeData[this]!.subclass;
    return subclass == null
        ? $bridgeGet(identifier)
        : subclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    final subclass = Runtime.bridgeData[this]!.subclass;
    if (subclass == null) {
      $bridgeSet(identifier, value);
    } else {
      subclass.$setProperty(runtime, identifier, value);
    }
  }

  dynamic $_get(String prop) {
    final runtime = Runtime.bridgeData[this]!.runtime;
    return ($getProperty(runtime, prop) as $Value).$reified;
  }

  void $_set(String prop, $Value value) {
    final runtime = Runtime.bridgeData[this]!.runtime;
    $setProperty(runtime, prop, value);
  }

  dynamic $_invoke(String method, List<$Value?> args) {
    final runtime = Runtime.bridgeData[this]!.runtime;
    final subclass = Runtime.bridgeData[this]!.subclass;
    if (subclass is TypedInstance) {
      return subclass.invokeBridge(method, args, runtime: runtime)?.$reified;
    }
    return ($getProperty(runtime, method) as EvalFunction)
        .call(
          runtime,
          this,
          args.isEmpty ? null : args[0],
          args.length > 1 ? args[1] : null,
          args.length < 3 ? args.length : args.sublist(2),
        )
        ?.$reified;
  }

  @override
  $Bridge get $value => this;

  @override
  T get $reified => this as T;

  Runtime get $runtime => Runtime.bridgeData[this]!.runtime;

  @override
  int $getRuntimeType(Runtime runtime) {
    final data = Runtime.bridgeData[this]!;
    return data.subclass?.$getRuntimeType(runtime) ??
        runtime.importRuntimeType(data.runtime, data.$runtimeType);
  }
}

class BridgeSuperShim implements $Instance {
  BridgeSuperShim();

  late $Bridge bridge;

  @override
  $Value? $getProperty(Runtime runtime, String name) => bridge.$bridgeGet(name);

  @override
  void $setProperty(Runtime runtime, String name, $Value value) =>
      bridge.$bridgeSet(name, value);

  @override
  $Bridge get $reified => bridge;

  @override
  $Bridge get $value => bridge;

  @override
  int $getRuntimeType(Runtime runtime) => bridge.$getRuntimeType(runtime);
}

class BridgeData {
  final Runtime runtime;
  final $Instance? subclass;
  final int $runtimeType;

  const BridgeData(this.runtime, this.$runtimeType, this.subclass);
}
