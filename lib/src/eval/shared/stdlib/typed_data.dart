import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/typed_data/typed_data.dart';

/// [EvalPlugin] for the `dart:typed_data` library
class DartTypedDataPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:typed_data';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    $ByteBuffer.configureForCompile(registry);
    $TypedData.configureForCompile(registry);
    $ByteData.configureForCompile(registry);
    $Uint8List.configureForCompile(registry);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $ByteBuffer.configureForRuntime(runtime);
    $TypedData.configureForRuntime(runtime);
    $ByteData.configureForRuntime(runtime);
    $Uint8List.configureForRuntime(runtime);
  }
}
