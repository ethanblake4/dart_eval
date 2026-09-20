import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/completer.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_controller.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_sink.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_subscription.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_transformer.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_view.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/timer.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/zone.dart';

/// [EvalPlugin] for the `dart:async` library
class DartAsyncPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:async';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    $Completer.configureForCompile(registry);
    $StreamSubscription.configureForCompile(registry);
    $StreamSink.configureForCompile(registry);
    $StreamController.configureForCompile(registry);
    $Zone.configureForCompile(registry);
    $StreamView.configureForCompile(registry);
    $Timer.configureForCompile(registry);
    $StreamTransformer.configureForCompile(registry);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $Completer.configureForRuntime(runtime);
    $StreamSubscription.configureForRuntime(runtime);
    $StreamSink.configureForRuntime(runtime);
    $StreamController.configureForRuntime(runtime);
    $Zone.configureForRuntime(runtime);
    $StreamView.configureForRuntime(runtime);
    $Timer.configureForRuntime(runtime);
    $StreamTransformer.configureForRuntime(runtime);
  }
}
