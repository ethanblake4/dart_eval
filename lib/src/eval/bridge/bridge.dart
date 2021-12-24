import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

mixin DbcBridgeInstance on Object implements IDbcValue, DbcInstance {

  IDbcValue? $bridgeGet(String identifier);

  void $bridgeSet(String identifier, IDbcValue value);

  @override
  IDbcValue? $getProperty(Runtime runtime, String identifier) {
    try {
      return Runtime.bridgeData[this]!.subclass!.$getProperty(runtime, identifier);
    } on UnimplementedError catch (_) {
      return $bridgeGet(identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, IDbcValue value) {
    try {
      return Runtime.bridgeData[this]!.subclass!.$setProperty(runtime, identifier, value);
    } on UnimplementedError catch (_) {
      $bridgeSet(identifier, value);
    }
  }

  dynamic $invoke(String method, List<IDbcValue?> args) {
    final runtime = Runtime.bridgeData[this]!.runtime;
    return ($getProperty(runtime, method) as DbcFunction).call(runtime, this, args)?.$reified;
  }

  @override
  DbcBridgeInstance get $value => this;

  @override
  DbcBridgeInstance get $reified => this;
}

class BridgeSuperShim implements DbcInstance {
  BridgeSuperShim();

  late DbcBridgeInstance bridge;

  @override
  IDbcValue? $getProperty(Runtime runtime, String name) => bridge.$bridgeGet(name);

  @override
  void $setProperty(Runtime runtime, String name, IDbcValue value) => bridge.$bridgeSet(name, value);

  @override
  DbcBridgeInstance get $reified => bridge;

  @override
  DbcBridgeInstance get $value => bridge;
}

class BridgeDelegatingShim implements DbcInstance {
  const BridgeDelegatingShim();

  @override
  IDbcValue? $getProperty(Runtime runtime, String name) => throw UnimplementedError();

  @override
  void $setProperty(Runtime runtime, String name, IDbcValue value) => throw UnimplementedError();

  @override
  DbcBridgeInstance get $reified => throw UnimplementedError();

  @override
  DbcBridgeInstance get $value => throw UnimplementedError();
}