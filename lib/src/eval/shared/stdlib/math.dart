import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/plugin.dart';
import 'math/point.dart';

class DartMathPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:math';

  @override
  void configureForCompile(Compiler compiler) {
    $Point.configureForCompile(compiler);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $Point.configureForRuntime(runtime);
  }
}
