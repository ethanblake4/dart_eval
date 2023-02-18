import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/http.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/io_sink.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/string_sink.dart';

/// [EvalPlugin] for the `dart:io` library
class DartIoPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:io';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($StringSink.$declaration);
    registry.defineBridgeClass($IOSink.$declaration);
    registry.defineBridgeClass($HttpClient.$declaration);
    registry.defineBridgeClass($HttpClientRequest.$declaration);
    registry.defineBridgeClass($HttpClientResponse.$declaration);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:io', 'HttpClient.', $HttpClient.$new);
  }
}
