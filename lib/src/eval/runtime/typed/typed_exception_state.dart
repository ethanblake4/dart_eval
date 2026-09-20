import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart' show WrappedException;
import 'typed_exception.dart';
import 'typed_frame.dart';
import 'typed_interop.dart';
import 'typed_program.dart';
import 'typed_async.dart';

final class _Handler {
  late TypedExceptionRegion region;
  int phase = 0; // Protected body, catch, finally.
  Object? error;
  StackTrace? trace;
  $Value? caught;
  TypedCompletionJump? jump;
  bool throwing = false;

  void clear() {
    error = null;
    trace = null;
    caught = null;
    jump = null;
    throwing = false;
  }
}

/// Allocated only by frames that execute a protected region. Entries are reused
/// by nesting depth, so a loop containing try does not allocate on each entry.
final class TypedExceptionState {
  final _handlers = <_Handler>[];
  int depth = 0;

  void enter(TypedExceptionRegion region) {
    if (depth == _handlers.length) _handlers.add(_Handler());
    final handler = _handlers[depth++];
    handler.clear();
    handler.region = region;
    handler.phase = 0;
  }

  void _pop() => _handlers[--depth].clear();

  void leave() {
    final handler = _handlers[depth - 1];
    if (handler.region.finallyTarget < 0) {
      _pop();
    } else {
      handler.phase = 2;
      handler.throwing = false;
      handler.jump = null;
    }
  }

  int jump(TypedCompletionJump completion) {
    if (completion.targetDepth > depth) {
      throw StateError('Invalid completion depth');
    }
    while (depth > completion.targetDepth) {
      final handler = _handlers[depth - 1];
      if (handler.phase != 2 && handler.region.finallyTarget >= 0) {
        handler.phase = 2;
        handler.throwing = false;
        handler.jump = completion;
        return handler.region.finallyTarget;
      }
      _pop();
    }
    return completion.target;
  }

  int resume(int nextPc) {
    final handler = _handlers[depth - 1];
    final completion = handler.jump;
    final error = handler.error, trace = handler.trace;
    final throwing = handler.throwing;
    _pop();
    if (throwing) Error.throwWithStackTrace(error!, trace!);
    return completion == null ? nextPc : jump(completion);
  }

  int handle(Object error, StackTrace trace, Runtime? runtime) {
    while (depth > 0) {
      final handler = _handlers[depth - 1];
      if (handler.phase == 0 && handler.region.catchTarget >= 0) {
        handler.phase = 1;
        handler.error = error;
        handler.trace = trace;
        handler.caught = _boxException(
          error is WrappedException ? error.exception : error,
          runtime,
        );
        return handler.region.catchTarget;
      }
      if (handler.phase != 2 && handler.region.finallyTarget >= 0) {
        handler.phase = 2;
        handler.error = error;
        handler.trace = trace;
        handler.throwing = true;
        handler.jump = null;
        return handler.region.finallyTarget;
      }
      _pop();
    }
    return -1;
  }

  _Handler get _caught =>
      _handlers.take(depth).lastWhere((h) => h.caught != null);
  $Value? get exception => _caught.caught;
  $StackTrace get stackTrace => $StackTrace.wrap(_caught.trace!);
  Never rethrowCaught(TypedExceptionRegion region) {
    final handler = _handlers
        .take(depth)
        .lastWhere((h) => identical(h.region, region));
    Error.throwWithStackTrace(handler.error!, handler.trace!);
  }

  static $Value? _boxException(Object error, Runtime? runtime) {
    if (error is $Value) return error;
    return switch (error) {
      TypeError() => $TypeError.wrap(error),
      NoSuchMethodError() => $NoSuchMethodError.wrap(error),
      StateError() => $StateError.wrap(error),
      RangeError() => $RangeError.wrap(error),
      ArgumentError() => $ArgumentError.wrap(error),
      AssertionError() => $AssertionError.wrap(error),
      UnimplementedError() => $UnimplementedError.wrap(error),
      UnsupportedError() => $UnsupportedError.wrap(error),
      Error() => $Error.wrap(error),
      FormatException() => $FormatException.wrap(error),
      Exception() => $Exception.wrap(error),
      _ => TypedInterop.boxExternal(error, runtime: runtime),
    };
  }
}

final class TypedExceptionTransfer {
  const TypedExceptionTransfer(this.frame, this.pc, [this.result]);
  final TypedFrame? frame;
  final int pc;
  final Object? result;
}

abstract final class TypedExceptions {
  @pragma('vm:never-inline')
  static void enter(TypedProgram program, TypedFrame frame, int index) =>
      (frame.exceptions ??= TypedExceptionState()).enter(
        program.exceptionRegions[index],
      );
  @pragma('vm:never-inline')
  static void leave(TypedFrame frame) => frame.exceptions!.leave();
  @pragma('vm:never-inline')
  static int jump(TypedProgram program, TypedFrame frame, int index) =>
      frame.exceptions == null
      ? program.completionJumps[index].target
      : frame.exceptions!.jump(program.completionJumps[index]);
  @pragma('vm:never-inline')
  static int resume(TypedFrame frame, int pc) => frame.exceptions!.resume(pc);
  @pragma('vm:never-inline')
  static $Value? caught(TypedFrame frame) => frame.exceptions!.exception;
  @pragma('vm:never-inline')
  static $StackTrace trace(TypedFrame frame) => frame.exceptions!.stackTrace;
  @pragma('vm:never-inline')
  static Never rethrowCaught(
    TypedProgram program,
    TypedFrame frame,
    int index,
  ) => frame.exceptions!.rethrowCaught(program.exceptionRegions[index]);
  @pragma('vm:never-inline')
  static TypedExceptionTransfer? handle(
    TypedFrame frame,
    Object error,
    StackTrace trace,
    Runtime? runtime,
  ) {
    while (true) {
      final target = frame.exceptions?.handle(error, trace, runtime) ?? -1;
      if (target >= 0) return TypedExceptionTransfer(frame, target);
      if (frame.asyncState != null) {
        final future = TypedAsync.fail(frame, error, trace);
        if (frame.parent == null) {
          return TypedExceptionTransfer(null, -1, future);
        }
        final pc = frame.returnPc;
        return TypedExceptionTransfer(frame.leave(), pc, future);
      }
      if (frame.parent == null) return null;
      frame = frame.leave();
    }
  }
}
