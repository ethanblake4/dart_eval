import 'package:dart_eval/dart_eval.dart';
import 'core/duration.dart';
import 'core/future.dart';
import 'core/print.dart';

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
