import 'package:dart_eval/dart_eval.dart';
import 'math/point.dart';

/// Configure dart:math classes and functions for compilation.
void configureMathForCompile(Compiler compiler) {
  $Point.configureForCompile(compiler);
}

/// Configure dart:math classes and functions for runtime.
void configureMathForRuntime(Runtime runtime) {
  $Point.configureForRuntime(runtime);
}
