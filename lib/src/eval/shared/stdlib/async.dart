import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/completer.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/event_sink.dart';
import 'async/exceptions.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/functions.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_controller.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_sink.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_iterator.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_subscription.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_transformer.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_transformer_base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/timer.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/typedefs.dart'
    as async_typedefs;
import 'package:dart_eval/src/eval/shared/stdlib/async/zone.dart';

final _streamViewSource = DartSource('dart:async', '''
class StreamView<T> implements Stream<T> {
  final Stream<T> _stream;
  const StreamView(this._stream);

  bool get isBroadcast => _stream.isBroadcast;

  StreamSubscription<T> listen(
    Function? onData, {
    Function? onError,
    Function? onDone,
    bool? cancelOnError,
  }) => _stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  Future<dynamic> pipe(dynamic sink) async {
    await for (final chunk in _stream) {
      sink.add(chunk);
    }
    return await sink.close();
  }
}
''');

final _sdkAsyncSource = DartSource(
  'dart:async',
  '${async_typedefs.sdkTypedefsSource.stringSource!}\n'
      '${_streamViewSource.stringSource!}',
);

/// [EvalPlugin] for the `dart:async` library
class DartAsyncPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:async';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeTopLevelFunction($unawaitedFn.$declaration);
    registry.defineBridgeTopLevelFunction($runZonedFn.$declaration);
    registry.defineBridgeTopLevelFunction($runZonedGuardedFn.$declaration);
    registry.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        'dart:async',
        'scheduleMicrotask',
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [
            BridgeParameter(
              'callback',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
        ),
      ),
    );
    $Completer.configureForCompile(registry);
    $EventSink.configureForCompile(registry);
    $StreamSubscription.configureForCompile(registry);
    $StreamSink.configureForCompile(registry);
    $StreamIterator.configureForCompile(registry);
    $StreamController.configureForCompile(registry);
    $Zone.configureForCompile(registry);
    $StreamTransformerBase$bridge.configureForCompile(registry);
    registry.addSource(_sdkAsyncSource);
    $Timer.configureForCompile(registry);
    $TimeoutException.configureForCompile(registry);
    $StreamTransformer.configureForCompile(registry);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $unawaitedFn.configureForRuntime(runtime);
    $runZonedFn.configureForRuntime(runtime);
    $runZonedGuardedFn.configureForRuntime(runtime);
    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'scheduleMicrotask',
      _scheduleMicrotask,
    );
    $Completer.configureForRuntime(runtime);
    $StreamSubscription.configureForRuntime(runtime);
    $EventSink.configureForRuntime(runtime);
    $StreamSink.configureForRuntime(runtime);
    $StreamIterator.configureForRuntime(runtime);
    $StreamController.configureForRuntime(runtime);
    $Zone.configureForRuntime(runtime);
    $StreamTransformerBase$bridge.configureForRuntime(runtime);
    $Timer.configureForRuntime(runtime);
    $TimeoutException.configureForRuntime(runtime);
    $StreamTransformer.configureForRuntime(runtime);
  }
}

$Value? _scheduleMicrotask(Runtime runtime, Object? r, Object? s, Object? c) {
  final callback = r as EvalFunction;
  scheduleMicrotask(() {
    callback.call(runtime, null, null, null, 0);
  });
  return null;
}
