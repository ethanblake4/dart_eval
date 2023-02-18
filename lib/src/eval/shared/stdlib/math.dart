import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'math/point.dart';

/// [EvalPlugin] for the dart:math library
class DartMathPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:math';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    $Point.configureForCompile(registry);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $Point.configureForRuntime(runtime);
  }
}
