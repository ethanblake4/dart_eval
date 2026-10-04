import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/developer/functions.dart';

/// [EvalPlugin] for the `dart:developer` library.
class DartDeveloperPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:developer';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeTopLevelFunction($logFn.$declaration);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $logFn.configureForRuntime(runtime);
  }
}
