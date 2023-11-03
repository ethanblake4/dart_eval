import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_controller.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/zone.dart';
import 'async/future.dart';

/// [EvalPlugin] for the `dart:async` library
class DartAsyncPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:async';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($Completer.$declaration);
    registry.defineBridgeClass($StreamSubscription.$declaration);
    registry.defineBridgeClass($StreamSink.$declaration);
    registry.defineBridgeClass($Stream.$declaration);
    registry.defineBridgeClass($StreamController.$declaration);
    registry.defineBridgeClass($Zone.$declaration);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        'dart:async', 'Completer.', const $Completer_new().call);
    runtime.registerBridgeFunc('dart:async', 'Stream.empty', $Stream.$empty);
    runtime.registerBridgeFunc('dart:async', 'Stream.value', $Stream.$_value);
    runtime.registerBridgeFunc(
        'dart:async', 'Stream.fromIterable', $Stream.$fromIterable);
    runtime.registerBridgeFunc(
        'dart:async', 'Stream.periodic', $Stream.$periodic);
    runtime.registerBridgeFunc(
        'dart:async', 'StreamController.', $StreamController.$new);
    runtime.registerBridgeFunc('dart:async', 'Zone.current*g', $Zone.$current);
    runtime.registerBridgeFunc('dart:async', 'Zone.root*g', $Zone.$root);
  }
}
