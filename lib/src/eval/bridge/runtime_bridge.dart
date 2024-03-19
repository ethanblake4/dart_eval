// ignore_for_file: non_constant_identifier_names

import 'package:dart_eval/dart_eval_bridge.dart';

/// A bridge class can be extended inside the dart_eval VM and used both in
/// and outside of it.
mixin $Bridge<T> on Object implements $Value, $Instance {
  $Value? $bridgeGet(String identifier);

  void $bridgeSet(String identifier, $Value value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    try {
      return Runtime.bridgeData[this]!.subclass!
          .$getProperty(runtime, identifier);
    } on UnimplementedError catch (_) {
      return $bridgeGet(identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    try {
      return Runtime.bridgeData[this]!.subclass!
          .$setProperty(runtime, identifier, value);
    } on UnimplementedError catch (_) {
      $bridgeSet(identifier, value);
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
    return ($getProperty(runtime, method) as EvalFunction)
        .call(runtime, this, [this, ...args])?.$reified;
  }

  @override
  $Bridge get $value => this;

  @override
  T get $reified => this as T;

  Runtime get $runtime => Runtime.bridgeData[this]!.runtime;

  @override
  int $getRuntimeType(Runtime runtime) {
    final data = Runtime.bridgeData[this]!;
    return data.subclass?.$getRuntimeType(runtime) ?? data.$runtimeType;
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

class BridgeDelegatingShim implements $Instance {
  const BridgeDelegatingShim();

  @override
  $Value? $getProperty(Runtime runtime, String name) =>
      throw UnimplementedError();

  @override
  void $setProperty(Runtime runtime, String name, $Value value) =>
      throw UnimplementedError();

  @override
  $Bridge get $reified => throw UnimplementedError();

  @override
  $Bridge get $value => throw UnimplementedError();

  @override
  int $getRuntimeType(Runtime runtime) => throw UnimplementedError();
}

class BridgeData {
  final Runtime runtime;
  final $Instance? subclass;
  final int $runtimeType;

  const BridgeData(this.runtime, this.$runtimeType, this.subclass);
}
