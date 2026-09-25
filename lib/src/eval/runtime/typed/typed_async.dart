import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show Runtime, TypedRuntimeInterop, WrappedException;
import 'typed_frame.dart';
import 'typed_instance.dart';
import 'typed_interop.dart';
import 'typed_program.dart';

/// One invocation's result, independent of the frame's cached caller chain.
final class TypedAsyncState {
  TypedAsyncState(this.runtimeTypeId, this.runtime);

  final int runtimeTypeId;
  final Runtime? runtime;
  Completer<Object?>? _completer;
  $Future<Object?>? _future;
  $Future<Object?> get future => _future ??= $Future.wrap(
    (_completer ??= Completer<Object?>()).future,
    runtimeTypeId: runtimeTypeId < 0 ? null : runtimeTypeId,
    runtime: runtime,
  );

  Future<Object?> _checked(Object? value) =>
      Future<Object?>.value(value).then((payload) {
        final boxed = TypedInterop.boxExternal(payload, runtime: runtime);
        if (runtimeTypeId >= 0) {
          runtime?.assertTypedFuturePayload(boxed, runtimeTypeId);
        }
        return boxed;
      });

  $Future<Object?> complete(Object? value) {
    var completer = _completer;
    final runtime = this.runtime;
    if (runtime != null && _isGuestFuture(value, runtime)) {
      // A returned guest Future is adopted like `await`: this state's future
      // completes when the guest's own `then` reports a value or an error.
      final c = _completer ??= Completer<Object?>();
      try {
        _attachGuestThen(
          value as TypedInstance,
          runtime,
          (payload) => c.complete(_checked(payload)),
          (error, trace) => c.completeError(
            error is WrappedException ? error.exception : error,
            trace ?? StackTrace.current,
          ),
        );
      } catch (error, trace) {
        c.completeError(
          error is WrappedException ? error.exception : error,
          trace,
        );
      }
      return future;
    }
    if (completer == null) {
      return $Future.wrap(
        _checked(value),
        runtimeTypeId: runtimeTypeId < 0 ? null : runtimeTypeId,
        runtime: runtime,
      );
    }
    completer.complete(_checked(value));
    return future;
  }

  $Future<Object?> completeError(Object error, StackTrace trace) {
    final thrown = error is WrappedException ? error.exception : error;
    final completer = _completer;
    if (completer == null) {
      return $Future.wrap(
        Future<Object?>.error(thrown, trace),
        runtimeTypeId: runtimeTypeId < 0 ? null : runtimeTypeId,
        runtime: runtime,
      );
    }
    completer.completeError(thrown, trace);
    return future;
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

/// Whether [value] is a guest class instance implementing `Future` —
/// `Future.value` cannot adopt it, so its own `then` must be called.
bool _isGuestFuture(Object? value, Runtime runtime) =>
    value is TypedInstance &&
    runtime.isTypedValueType(value, runtime.lookupType(CoreTypes.future));

/// Attach host completion callbacks to a guest Future's own `then`.
/// [onValue] receives the exported (unboxed) completion payload.
void _attachGuestThen(
  TypedInstance subject,
  Runtime runtime,
  void Function(Object?) onValue,
  void Function(Object, StackTrace?) onError,
) => subject.invoke(
  'then',
  1,
  TypedHostFunction(onValue),
  TypedHostFunction(
    (error, [StackTrace? trace]) => onError(error, trace),
  ),
  namedNames: const ['onError'],
  runtime: runtime,
);

/// Await is a clobber boundary. The compiler has saved all live values in the
/// frame's typed spills before this helper detaches the suspended invocation.
abstract final class TypedAsync {
  @pragma('vm:never-inline')
  static TypedAsyncState begin(
    TypedFrame frame,
    int runtimeTypeId,
    Runtime? runtime,
  ) => frame.asyncState = TypedAsyncState(runtimeTypeId, runtime);

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
    // A guest class may implement `Future` directly — `Future.value` cannot
    // adopt it, so call its `then` and forward the completion ourselves.
    if (runtime != null && _isGuestFuture(subject, runtime)) {
      try {
        _attachGuestThen(
          subject as TypedInstance,
          runtime,
          (value) {
            try {
              resume(
                program,
                frame,
                pc,
                TypedInterop.boxExternal(value, runtime: runtime),
                null,
                null,
                runtime,
              );
            } catch (error, trace) {
              resume(program, frame, pc, null, error, trace, runtime);
            }
          },
          (error, trace) => resume(
            program,
            frame,
            pc,
            null,
            error,
            trace ?? StackTrace.current,
            runtime,
          ),
        );
      } catch (error, trace) {
        resume(program, frame, pc, null, error, trace, runtime);
      }
      return future;
    }
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
