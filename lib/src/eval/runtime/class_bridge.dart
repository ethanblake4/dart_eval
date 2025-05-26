// ignore_for_file: depend_on_referenced_packages

import '../../../dart_eval_bridge.dart';

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
}
