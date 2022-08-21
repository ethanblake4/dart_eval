import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/date_time.dart';
import 'core/duration.dart';
import 'core/future.dart';
import 'core/print.dart';

/// Configure dart:core classes and functions for compilation.
void configureCoreForCompile(Compiler compiler) {
  configurePrintForCompile(compiler);
  $Future.configureForCompile(compiler);
  $Duration.configureForCompile(compiler);
  $DateTime.configureForCompile(compiler);
}

/// Configure dart:core classes and functions for runtime in the dart_eval VM.
void configureCoreForRuntime(Runtime runtime) {
  configurePrintForRuntime(runtime);
  $Duration.configureForRuntime(runtime);
  $Future.configureForRuntime(runtime);
  $DateTime.configureForRuntime(runtime);
}
