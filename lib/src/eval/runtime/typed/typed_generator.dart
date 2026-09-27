import 'dart:collection';

import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'typed_frame.dart';
import 'typed_program.dart';

typedef TypedSyncResume =
    void Function(
      TypedProgram program,
      TypedFrame frame,
      int pc,
      Runtime? runtime,
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
      ..lexicalTypeArguments = template.lexicalTypeArguments;
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

  @override
  Object? current;

  void suspend(Object? value, int resumePc) {
    current = value;
    pc = resumePc;
    _yielded = true;
  }

  @override
  bool moveNext() {
    if (_running) throw StateError('Iterator is already running');
    if (_closed) return false;
    _running = true;
    _yielded = false;
    current = null;
    try {
      iterable.resume(iterable.program, frame, pc, iterable.runtime);
      _closed = !_yielded;
      return _yielded;
    } catch (_) {
      _closed = true;
      rethrow;
    } finally {
      _running = false;
    }
  }
}
