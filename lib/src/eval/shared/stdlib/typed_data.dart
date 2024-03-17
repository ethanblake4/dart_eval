import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/typed_data/typed_data.dart';

/// [EvalPlugin] for the `dart:typed_data` library
class DartTypedDataPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:typed_data';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($ByteBuffer.$declaration);
    registry.defineBridgeClass($TypedData.$declaration);
    registry.defineBridgeClass($ByteData.$declaration);
    registry.defineBridgeClass($Uint8List.$declaration);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:typed_data', 'ByteData.', $ByteData.$new);
    runtime.registerBridgeFunc(
        'dart:typed_data', 'ByteData.view', $ByteData.$view);
    runtime.registerBridgeFunc(
        'dart:typed_data', 'Uint8List.', $Uint8List.$new);
    runtime.registerBridgeFunc(
        'dart:typed_data', 'Uint8List.fromList', $Uint8List.$fromList);
    runtime.registerBridgeFunc(
        'dart:typed_data', 'Uint8List.view', $Uint8List.$view);
    runtime.registerBridgeFunc(
        'dart:typed_data', 'Uint8List.sublistView', $Uint8List.$sublistView);
  }
}
