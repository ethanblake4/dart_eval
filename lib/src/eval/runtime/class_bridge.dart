// ignore_for_file: depend_on_referenced_packages

import 'package:dart_eval/src/eval/runtime/class.dart';

import '../../../dart_eval_bridge.dart';
import '../bridge/runtime_bridge.dart';

mixin $InstanceDefaultBridge<T extends Object> on $Bridge<T> {
  InstanceDefaultProps get props;

  @override
  $Value? $bridgeGet(Runtime runtime, String identifier) {
    return props.getProperty(
      runtime,
      identifier,
      this,
    );
  }

  @override
  void $bridgeSet(Runtime runtime, String identifier, $Value value) {
    props.setProperty(
      runtime,
      identifier,
      value,
      this,
    );
  }

  @override
  String toString() {
    return "\$${super.toString()}";
  }

  void changeBridgeData($Bridge<T> newData) {
    final BridgeData? oldData = Runtime.bridgeData[this];

    if (oldData == null) {
      return;
    }

    if (oldData.subclass is $InstanceImpl) {
      final superClass = (oldData.subclass as $InstanceImpl).evalSuperclass;

      if (superClass is BridgeSuperShim) {
        superClass.bridge = newData;
      }
    }
    Runtime.bridgeData[newData] = oldData;
  }
}
