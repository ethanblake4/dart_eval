import 'dart:async';
import 'dart:collection';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/async.dart' show $Stream;
import 'package:dart_eval/stdlib/core.dart';
import 'typed_frame.dart';
import 'typed_interop.dart';
import 'typed_program.dart';
import 'typed_async.dart';

/// An internal return completion. Guest catch clauses must not intercept it.
final class TypedGeneratorCancellation {
  const TypedGeneratorCancellation();
}

/// One single-subscription async* invocation. Await continues independently of
/// subscription pauses; only yield boundaries wait for the listener to resume.
final class TypedAsyncGenerator {
  TypedAsyncGenerator(
    this.program,
    this.frame,
    this.pc,
    this.runtime,
    this.resume,
  ) {
    controller = StreamController<Object?>(
      sync: true,
      onListen: _schedule,
      onResume: _schedule,
      onCancel: _cancel,
    );
  }

  final TypedProgram program;
  final TypedFrame frame;
  int pc;
  final Runtime? runtime;
  final TypedAsyncResume resume;
  late final StreamController<Object?> controller;
  Completer<void>? _cancelCompletion;
  bool _suspended = true;
  bool _scheduled = false;
  bool _closed = false;

  bool get _cancelled => !controller.hasListener;

  static $Stream begin(
    TypedProgram program,
    TypedFrame frame,
    int pc,
    int typeId,
    Runtime? runtime,
    TypedAsyncResume resume,
  ) {
    frame.detachAsync();
    final generator = TypedAsyncGenerator(program, frame, pc, runtime, resume);
    frame.asyncGenerator = generator;
    return _GeneratorStream(generator.controller.stream, typeId);
  }

  void _schedule() {
    if (_scheduled ||
        !_suspended ||
        _closed ||
        (controller.isPaused && !_cancelled)) {
      return;
    }
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      if (!_suspended || _closed || (controller.isPaused && !_cancelled)) {
        return;
      }
      _suspended = false;
      resume(
        program,
        frame,
        pc,
        null,
        _cancelled ? const TypedGeneratorCancellation() : null,
        _cancelled ? StackTrace.current : null,
        runtime,
      );
    });
  }

  Future<void>? _cancel() {
    if (_closed) return null;
    final completion = _cancelCompletion ??= Completer<void>();
    _schedule();
    return completion.future;
  }

  void suspend(Object? value, int resumePc) {
    pc = resumePc;
    _suspended = true;
    if (!_cancelled) controller.add(value);
    _schedule();
  }

  void delegate(Object? value, int resumePc) {
    pc = resumePc;
    if (_cancelled) {
      _suspended = true;
      _schedule();
      return;
    }
    final stream = runtime == null
        ? (value as $Value).$value as Stream<Object?>
        : TypedInterop.stream(value, runtime!);
    // addStream forwards errors as events, and owns pause/cancel propagation.
    controller
        .addStream(
          stream.map(
            (event) => TypedInterop.boxExternal(event, runtime: runtime),
          ),
        )
        .then<void>(
          (_) {
            _suspended = true;
            _schedule();
          },
          onError: (Object error, StackTrace trace) {
            resume(program, frame, pc, null, error, trace, runtime);
          },
        );
  }

  void complete() {
    if (_closed) return;
    _closed = true;
    frame.asyncGenerator = null;
    _cancelCompletion?.complete();
    controller.close();
  }

  void fail(Object error, StackTrace trace) {
    if (error is TypedGeneratorCancellation) {
      complete();
      return;
    }
    if (_cancelled) {
      // Cleanup failures belong to the future returned by cancel.
      final completion = _cancelCompletion ??= Completer<void>();
      completion.completeError(error, trace);
      _cancelCompletion = null;
    } else {
      controller.addError(error, trace);
    }
    complete();
  }
}

final class _GeneratorStream extends $Stream {
  _GeneratorStream(super.value, this.typeId) : super.wrap();
  final int typeId;

  @override
  int $getRuntimeType(Runtime runtime) => typeId;
}

typedef TypedSyncResume =
    void Function(
      TypedProgram program,
      TypedFrame frame,
      int pc,
      Runtime? runtime,
      Object? error,
      StackTrace? trace,
    );

/// A suspended function invocation. Each iterator starts from its own spills.
final class TypedSyncIterable extends IterableBase<Object?> {
  TypedSyncIterable(
    this.program,
    this.template,
    this.pc,
    this.runtime,
    this.resume,
  );

  final TypedProgram program;
  final TypedFrame template;
  final int pc;
  final Runtime? runtime;
  final TypedSyncResume resume;

  static $Iterable<Object?> begin(
    TypedProgram program,
    TypedFrame frame,
    int pc,
    int typeId,
    Runtime? runtime,
    TypedSyncResume resume,
  ) {
    frame.detachAsync();
    return _GeneratorIterable(
      TypedSyncIterable(program, frame, pc, runtime, resume),
      typeId,
    );
  }

  @override
  Iterator<Object?> get iterator {
    final frame = TypedFrame(template.function)
      ..environment = template.environment
      ..typeEnvironmentReceiver = template.typeEnvironmentReceiver
      ..typeArguments = template.typeArguments
      ..lexicalTypeEnvironmentReceiver = template.lexicalTypeEnvironmentReceiver
      ..lexicalTypeArguments = template.lexicalTypeArguments
      ..lexicalTypeEnvironment = template.lexicalTypeEnvironment;
    frame.intSpills.setAll(0, template.intSpills);
    frame.doubleSpills.setAll(0, template.doubleSpills);
    frame.boolSpills.setAll(0, template.boolSpills);
    frame.objectSpills.setAll(0, template.objectSpills);
    final iterator = TypedSyncIterator(this, frame, pc);
    frame.syncIterator = iterator;
    return iterator;
  }
}

final class _GeneratorIterable extends $Iterable<Object?> {
  _GeneratorIterable(super.value, this.typeId) : super.wrap();
  final int typeId;

  @override
  int $getRuntimeType(Runtime runtime) => typeId;
}

final class TypedSyncIterator implements Iterator<Object?> {
  TypedSyncIterator(this.iterable, this.frame, this.pc);
  final TypedSyncIterable iterable;
  final TypedFrame frame;
  int pc;
  bool _running = false;
  bool _closed = false;
  bool _yielded = false;
  Iterator<Object?>? _delegate;

  @override
  Object? current;

  void suspend(Object? value, int resumePc) {
    current = value;
    pc = resumePc;
    _yielded = true;
  }

  void delegate(Object? iterator, int resumePc) {
    _delegate = iterator is $Iterator
        ? iterator.$value
        : _GuestIterator(iterator, iterable.runtime);
    pc = resumePc;
  }

  @override
  bool moveNext() {
    if (_running) throw StateError('Iterator is already running');
    if (_closed) return false;
    _running = true;
    _yielded = false;
    current = null;
    try {
      while (true) {
        Object? error;
        StackTrace? trace;
        final delegated = _delegate;
        if (delegated != null) {
          try {
            if (delegated.moveNext()) {
              final value = delegated.current;
              current =
                  delegated is TypedSyncIterator || delegated is _GuestIterator
                  ? value
                  : iterable.runtime?.wrapAlways(value, recursive: true) ??
                        TypedInterop.boxExternal(value);
              return true;
            }
          } catch (caught, stack) {
            error = caught;
            trace = stack;
          }
          _delegate = null;
        }
        iterable.resume(
          iterable.program,
          frame,
          pc,
          iterable.runtime,
          error,
          trace,
        );
        if (_yielded) return true;
        if (_delegate != null) continue;
        _closed = true;
        return false;
      }
    } catch (_) {
      _closed = true;
      rethrow;
    } finally {
      _running = false;
    }
  }
}

/// Guest-defined iterators retain ordinary virtual dispatch.
final class _GuestIterator implements Iterator<Object?> {
  _GuestIterator(this.receiver, this.runtime);
  final Object? receiver;
  final Runtime? runtime;

  @override
  Object? get current => TypedInterop.getProperty(runtime, receiver, 'current');

  @override
  bool moveNext() => TypedInterop.toBool(
    TypedInterop.invoke(runtime, receiver, 'moveNext', 0, null, null),
  );
}
