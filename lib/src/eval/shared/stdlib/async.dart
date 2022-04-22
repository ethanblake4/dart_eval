import 'package:dart_eval/dart_eval.dart';
import 'async/future.dart';

void configureAsyncForCompile(Compiler compiler) {
  $Completer.configureForCompile(compiler);
}

void configureAsyncForRuntime(Runtime runtime) {
  $Completer.configureForRuntime(runtime);
}
