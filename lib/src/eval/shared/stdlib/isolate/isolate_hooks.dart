import 'dart:isolate';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop;
import 'package:dart_eval/src/eval/runtime/typed/typed_transfer.dart';
import 'isolate.dart';
import 'ports.dart';

// This top-level native entrypoint captures no Runtime, plugin or host closure.
void _guestWorker(List<Object?> envelope) async {
  final bytes = envelope[0] as Uint8List;
  final runtime = Runtime(bytes.buffer)..initialize();
  runtime.maxCallDepth = envelope[2] as int;
  final pair = TypedTransfer.decode(runtime, envelope[1]) as $List;
  final callable = pair.$value[0] as EvalCallable;
  final result = callable.call(runtime, null, pair.$value[1], null, 1);
  if (result is $Future) await result.$value;
}

$Value? guestIsolateSpawn(Runtime runtime, $Value? _, List<$Value?> args) {
  final bytes = runtime.guestIsolateProgram();
  final graph = TypedTransfer.encode(runtime, $List.wrap([args[0], args[1]]));
  Object? argument(int index) =>
      index < args.length ? args[index]?.$value : null;
  return $Future.wrap(
    Isolate.spawn<List<Object?>>(
      _guestWorker,
      [bytes, graph, runtime.maxCallDepth],
      paused: argument(2) as bool? ?? false,
      errorsAreFatal: argument(3) as bool? ?? true,
      onExit: TypedTransfer.nativeSendPort(argument(4)),
      onError: TypedTransfer.nativeSendPort(argument(5)),
      debugName: argument(6) as String?,
    ).then($Isolate.wrap),
    runtime: runtime,
    runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
      runtime.lookupType(IsolateTypes.isolate),
    ]),
  );
}

$Value? guestIsolateExit(Runtime runtime, $Value? _, List<$Value?> args) {
  final port = TypedTransfer.nativeSendPort(args[0]?.$value);
  final graph = port == null ? null : TypedTransfer.encode(runtime, args[1]);
  Isolate.exit(port, graph);
}

void _setHandler(Runtime runtime, RawReceivePort port, $Value? value) {
  if (value == null || value is $null) {
    port.handler = null;
    return;
  }
  final callable = value as EvalCallable;
  port.handler = (Object? message) {
    callable.call(
      runtime,
      null,
      TypedTransfer.decode(runtime, message),
      null,
      1,
    );
  };
}

$Value? guestRawReceivePort(Runtime runtime, $Value? _, List<$Value?> args) {
  final port = RawReceivePort(
    null,
    args.length > 1 ? args[1]?.$value as String? ?? '' : '',
  );
  try {
    _setHandler(runtime, port, args.isEmpty ? null : args[0]);
  } catch (_) {
    port.close();
    rethrow;
  }
  return $RawReceivePort.wrap(port);
}

void guestRawReceivePortHandler(
  Runtime runtime,
  $Value? target,
  $Value value,
) => _setHandler(runtime, (target as $RawReceivePort).$value, value);

$Value? guestSendPortSend(
  Runtime runtime,
  $Value? target,
  Object? r,
  Object? s,
  Object? c,
) {
  TypedTransfer.nativeSendPort(
    (target as $SendPort).$value,
  )!.send(TypedTransfer.encode(runtime, r));
  return null;
}

$Value? guestIsolatePing(
  Runtime runtime,
  $Value? target,
  Object? r,
  Object? s,
  Object? c,
) {
  final priority = c is List && c.isNotEmpty ? (c[0] as $int?)?.$value : null;
  (target as $Isolate).$value.ping(
    TypedTransfer.nativeSendPort((r as $SendPort).$value)!,
    response: TypedTransfer.encode(runtime, s),
    priority: priority ?? Isolate.immediate,
  );
  return null;
}

$Value? guestIsolateAddOnExitListener(
  Runtime runtime,
  $Value? target,
  Object? r,
  Object? s,
  Object? c,
) {
  (target as $Isolate).$value.addOnExitListener(
    TypedTransfer.nativeSendPort((r as $SendPort).$value)!,
    response: TypedTransfer.encode(runtime, s),
  );
  return null;
}
