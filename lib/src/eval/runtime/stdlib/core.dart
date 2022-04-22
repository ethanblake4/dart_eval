import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/stdlib/core/duration.dart';
import 'package:dart_eval/src/eval/runtime/stdlib/core/future.dart';
import 'package:dart_eval/src/eval/runtime/stdlib/core/print.dart';

void configureCoreForCompile(Compiler compiler) {
  configurePrintForCompile(compiler);
  $Future.configureForCompile(compiler);
  $Duration.configureForCompile(compiler);
}

void configureCoreForRuntime(Runtime runtime) {
  configurePrintForRuntime(runtime);
  $Duration.configureForRuntime(runtime);
  $Future.configureForRuntime(runtime);
}
