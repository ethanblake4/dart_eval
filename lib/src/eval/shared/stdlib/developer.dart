import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/developer/functions.dart';
import 'developer/timeline.dart';

/// [EvalPlugin] for the `dart:developer` library.
class DartDeveloperPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:developer';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeTopLevelFunction($logFn.$declaration);
    registry.defineBridgeTopLevelFunction($postEventFn.$declaration);
    $Flow.configureForCompile(registry);
    $Timeline.configureForCompile(registry);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $logFn.configureForRuntime(runtime);
    $postEventFn.configureForRuntime(runtime);
    $Flow.configureForRuntime(runtime);
    $Timeline.configureForRuntime(runtime);
  }
}
