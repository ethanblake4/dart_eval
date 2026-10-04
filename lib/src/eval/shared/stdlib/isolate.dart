import 'package:dart_eval/dart_eval_bridge.dart';
import 'isolate/isolate.dart';
import 'isolate/ports.dart';

/// Native same-program workers with explicit guest graph transport.
class DartIsolatePlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:isolate';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    $Isolate.configureForCompile(registry);
    $RawReceivePort.configureForCompile(registry);
    $SendPort.configureForCompile(registry);
    $Capability.configureForCompile(registry);
    $RemoteError.configureForCompile(registry);
    $TransferableTypedData.configureForCompile(registry);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $Isolate.configureForRuntime(runtime);
    $RawReceivePort.configureForRuntime(runtime);
    $SendPort.configureForRuntime(runtime);
    $Capability.configureForRuntime(runtime);
    $RemoteError.configureForRuntime(runtime);
    $TransferableTypedData.configureForRuntime(runtime);
  }
}
