import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart' show WrappedException;
import 'typed_frame.dart';
import 'typed_interop.dart';
import 'typed_program.dart';

/// One invocation's result, independent of the frame's cached caller chain.
final class TypedAsyncState {
  Completer<Object?>? _completer;
  $Future<Object?>? _future;
  $Future<Object?> get future =>
      _future ??= $Future.wrap((_completer ??= Completer<Object?>()).future);

  $Future<Object?> complete(Object? value) {
    final completer = _completer;
    if (completer == null) return $Future.wrap(Future<Object?>.value(value));
    completer.complete(value);
    return _future!;
  }

  $Future<Object?> completeError(Object error, StackTrace trace) {
    final thrown = error is WrappedException ? error.exception : error;
    final completer = _completer;
    if (completer == null) {
      return $Future.wrap(Future<Object?>.error(thrown, trace));
    }
    completer.completeError(thrown, trace);
    return _future!;
  }
}

typedef TypedAsyncResume =
    void Function(
      TypedProgram program,
      TypedFrame frame,
      int pc,
      $Value? value,
      Object? error,
      StackTrace? trace,
      Runtime? runtime,
    );

/// Await is a clobber boundary. The compiler has saved all live values in the
/// frame's typed spills before this helper detaches the suspended invocation.
abstract final class TypedAsync {
  @pragma('vm:never-inline')
  static TypedAsyncState begin(TypedFrame frame) =>
      frame.asyncState = TypedAsyncState();

  @pragma('vm:never-inline')
  static $Future<Object?> suspend(
    TypedProgram program,
    TypedFrame frame,
    int pc,
    Object? subject,
    Runtime? runtime,
    TypedAsyncResume resume,
  ) {
    final future = frame.asyncState!.future;
    frame.detachAsync();
    // Future.value also schedules a non-Future await and adopts returned
    // Futures. Values enter the boxed guest ABI only at this host boundary.
    Future<Object?>.value(subject).then<void>(
      (value) {
        $Value? boxed;
        try {
          boxed = TypedInterop.boxExternal(value, runtime: runtime);
        } catch (error, trace) {
          resume(program, frame, pc, null, error, trace, runtime);
          return;
        }
        resume(program, frame, pc, boxed, null, null, runtime);
      },
      onError: (Object error, StackTrace trace) {
        resume(program, frame, pc, null, error, trace, runtime);
      },
    );
    return future;
  }

  @pragma('vm:never-inline')
  static $Future<Object?> complete(TypedFrame frame, Object? value) {
    final state = frame.asyncState!;
    frame.asyncState = null;
    return state.complete(value);
  }

  @pragma('vm:never-inline')
  static $Future<Object?> fail(
    TypedFrame frame,
    Object error,
    StackTrace trace,
  ) {
    final state = frame.asyncState!;
    frame.asyncState = null;
    return state.completeError(error, trace);
  }
}
