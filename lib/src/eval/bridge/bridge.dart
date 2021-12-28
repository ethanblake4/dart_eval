import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

mixin BridgeInstance on Object implements EvalValue, EvalInstance {

  EvalValue? $bridgeGet(String identifier);

  void $bridgeSet(String identifier, EvalValue value);

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    try {
      return Runtime.bridgeData[this]!.subclass!.$getProperty(runtime, identifier);
    } on UnimplementedError catch (_) {
      return $bridgeGet(identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {
    try {
      return Runtime.bridgeData[this]!.subclass!.$setProperty(runtime, identifier, value);
    } on UnimplementedError catch (_) {
      $bridgeSet(identifier, value);
    }
  }

  dynamic $_get(String prop) {
    final runtime = Runtime.bridgeData[this]!.runtime;
    return ($getProperty(runtime, prop) as EvalValue).$reified;
  }

  void $_set(String prop, EvalValue value) {
    final runtime = Runtime.bridgeData[this]!.runtime;
    $setProperty(runtime, prop, value);
  }

  dynamic $_invoke(String method, List<EvalValue?> args) {
    final runtime = Runtime.bridgeData[this]!.runtime;
    return ($getProperty(runtime, method) as EvalFunction).call(runtime, this, args)?.$reified;
  }

  @override
  BridgeInstance get $value => this;

  @override
  BridgeInstance get $reified => this;
}

class BridgeSuperShim implements EvalInstance {
  BridgeSuperShim();

  late BridgeInstance bridge;

  @override
  EvalValue? $getProperty(Runtime runtime, String name) => bridge.$bridgeGet(name);

  @override
  void $setProperty(Runtime runtime, String name, EvalValue value) => bridge.$bridgeSet(name, value);

  @override
  BridgeInstance get $reified => bridge;

  @override
  BridgeInstance get $value => bridge;
}

class BridgeDelegatingShim implements EvalInstance {
  const BridgeDelegatingShim();

  @override
  EvalValue? $getProperty(Runtime runtime, String name) => throw UnimplementedError();

  @override
  void $setProperty(Runtime runtime, String name, EvalValue value) => throw UnimplementedError();

  @override
  BridgeInstance get $reified => throw UnimplementedError();

  @override
  BridgeInstance get $value => throw UnimplementedError();
}

class BridgeData {
  final Runtime runtime;
  final EvalInstance? subclass;

  const BridgeData(this.runtime, this.subclass);
}