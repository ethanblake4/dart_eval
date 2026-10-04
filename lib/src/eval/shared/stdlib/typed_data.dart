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
    $Endian.configureForCompile(registry);
    $Int8List.configureForCompile(registry);
    $Int16List.configureForCompile(registry);
    $Uint8List.configureForCompile(registry);
    $Uint8ClampedList.configureForCompile(registry);
    $Uint16List.configureForCompile(registry);
    $Uint32List.configureForCompile(registry);
    $Float32List.configureForCompile(registry);
    $Float64List.configureForCompile(registry);
    $Int32List.configureForCompile(registry);
    $Int64List.configureForCompile(registry);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $ByteBuffer.configureForRuntime(runtime);
    $TypedData.configureForRuntime(runtime);
    $ByteData.configureForRuntime(runtime);
    $Endian.configureForRuntime(runtime);
    $Int8List.configureForRuntime(runtime);
    $Int16List.configureForRuntime(runtime);
    $Uint8List.configureForRuntime(runtime);
    $Uint8ClampedList.configureForRuntime(runtime);
    $Uint16List.configureForRuntime(runtime);
    $Uint32List.configureForRuntime(runtime);
    $Float32List.configureForRuntime(runtime);
    $Float64List.configureForRuntime(runtime);
    $Int32List.configureForRuntime(runtime);
    $Int64List.configureForRuntime(runtime);
  }
}
