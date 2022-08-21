import 'package:dart_eval/dart_eval.dart';
import 'async/future.dart';

/// Configure dart:async classes and functions for compilation.
void configureAsyncForCompile(Compiler compiler) {
  $Completer.configureForCompile(compiler);
}

/// Configure dart:async classes and functions for runtime.
void configureAsyncForRuntime(Runtime runtime) {
  $Completer.configureForRuntime(runtime);
}
