import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/plugin.dart';
import 'async/future.dart';

class DartAsyncPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:async';

  @override
  void configureForCompile(Compiler compiler) {
    $Completer.configureForCompile(compiler);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $Completer.configureForRuntime(runtime);
  }
}
