import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart' show WrappedException;
import 'typed_exception.dart';
import 'typed_frame.dart';
import 'typed_interop.dart';
import 'typed_program.dart';
import 'typed_async.dart';
import 'typed_generator.dart';
import 'typed_instance.dart';

/// Snapshot names before unwinding or reusing the interpreter's cached frames.
/// Host callbacks can enter another machine root; each root contributes once.
final class _GuestStackTrace implements StackTrace {
  _GuestStackTrace(this.names, this.roots, this.hostTrace);

  static final _rootIds = Expando<Object>();
  final List<String> names;
  final List<Object> roots;
  final StackTrace hostTrace;

  static StackTrace capture(TypedFrame frame, StackTrace trace) {
    var root = frame;
    final names = <String>[];
    while (true) {
      final name = root.function.debugName;
      if (name != null) names.add(name);
      final parent = root.parent;
      if (parent == null) break;
      root = parent;
    }
    if (names.isEmpty) return trace;
    final id = _rootIds[root] ??= Object();
    if (trace is _GuestStackTrace) {
      if (trace.roots.contains(id)) return trace;
      return _GuestStackTrace(
        List.unmodifiable([...trace.names, ...names]),
        List.unmodifiable([...trace.roots, id]),
        trace.hostTrace,
      );
    }
    return _GuestStackTrace(
      List.unmodifiable(names),
      List.unmodifiable([id]),
      trace,
    );
  }

  late final String _text = [
    for (var i = 0; i < names.length; i++) '#$i      ${names[i]} (guest)',
    hostTrace.toString(),
  ].join('\n');

  @override
  String toString() => _text;
}

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
      if (handler.phase == 0 &&
          handler.region.catchTarget >= 0 &&
          error is! TypedGeneratorCancellation) {
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

  /// Box a host error surfacing through an async boundary (future error,
  /// stream error) for delivery into guest `catch`/`onError` handlers.
  static $Value? boxException(Object error, Runtime? runtime) => _boxException(
    error is WrappedException ? error.exception : error,
    runtime,
  );

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
      StackOverflowError() => $StackOverflowError.wrap(error),
      OutOfMemoryError() => $OutOfMemoryError.wrap(error),
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
  static final _suppliedTraces = Expando<bool>('supplied stack trace');

  /// User-supplied traces retain their exact text and identity across rethrows.
  static StackTrace preserveTrace(StackTrace trace) {
    _suppliedTraces[trace] = true;
    return trace;
  }

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
    Runtime? runtime, {
    bool captureNativeTrace = true,
  }) {
    if (!captureNativeTrace && trace is! _GuestStackTrace) {
      preserveTrace(trace);
    }
    if (_suppliedTraces[trace] != true) {
      trace = _GuestStackTrace.capture(frame, trace);
    }
    final thrown = error is WrappedException ? error.exception : error;
    final hostError = switch (thrown) {
      TypedInstance() => thrown.bridge,
      $Error() ||
      $StackOverflowError() ||
      $OutOfMemoryError() => (thrown as $Value).$value,
      Error() => thrown is $Value ? (thrown as $Value).$value : thrown,
      _ => null,
    };
    if (hostError is Error && hostError.stackTrace == null) {
      // Guest throws wrap bridge errors, so the VM has not yet recorded
      // the original error's first throw trace.
      try {
        Error.throwWithStackTrace(hostError, trace);
      } catch (_) {}
    }
    while (true) {
      final target = frame.exceptions?.handle(error, trace, runtime) ?? -1;
      if (target >= 0) return TypedExceptionTransfer(frame, target);
      if (frame.asyncGenerator case final generator?) {
        final thrown = error is WrappedException ? error.exception : error;
        generator.fail(thrown, trace);
        return const TypedExceptionTransfer(null, -1);
      }
      if (frame.asyncState != null) {
        final future = TypedAsync.fail(frame, error, trace);
        if (frame.parent == null) {
          return TypedExceptionTransfer(null, -1, future);
        }
        final pc = frame.returnPc;
        return TypedExceptionTransfer(frame.leave(), pc, future);
      }
      if (frame.parent == null) {
        // Escape a nested machine entry with its guest frames intact, so the
        // outer entry can append its caller frames on the same cold path.
        Error.throwWithStackTrace(error, trace);
      }
      frame = frame.leave();
    }
  }
}
