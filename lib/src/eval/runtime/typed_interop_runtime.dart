part of 'runtime.dart';

final _typedAdapters = Expando<Map<int, _TypedLegacyAdapter>>();

/// Dynamic calls use boxed values, including when entering reference bytecode.
extension TypedRuntimeInterop on Runtime {
  /// Reference functions require a complete positional argument vector.
  /// Optional defaults and named argument binding need compiler-side lowering.
  $Value? invokeTypedObject(
    Object? receiver,
    String name,
    List<$Value?> arguments,
  ) {
    _setup();
    final result = _dispatchTypedObject(receiver, name, arguments);
    return result is $null ? null : result;
  }

  $Value? _dispatchTypedObject(
    Object? receiver,
    String name,
    List<$Value?> arguments,
  ) {
    if (name == 'call') {
      if (receiver is _RegisterClosure) {
        return _invokeTypedReference(receiver.offset, [
          if (receiver.boundReceiver) receiver.captures.first as $Value?,
          ...arguments,
        ], receiver.captures);
      }
      if (receiver is EvalStaticFunctionPtr) {
        return _invokeTypedReference(receiver.offset, [
          if (receiver.$this != null) receiver.$this,
          ...arguments,
        ]);
      }
      if (receiver is $Closure) {
        // $Closure.call expects the old VM's three signature-header arguments.
        // Its bridge function already has the canonical boxed signature.
        return receiver.func(this, receiver.$this, arguments);
      }
      if (receiver is EvalCallable) {
        return receiver.call(this, receiver as $Value?, arguments);
      }
    }
    var object = receiver as $Instance;
    while (object is $InstanceImpl) {
      final offset = object.evalClass.methods[name];
      if (offset != null) {
        return _invokeTypedReference(offset, [object, ...arguments]);
      }
      if (object.evalSuperclass == null) break;
      object = object.evalSuperclass!;
    }
    final callable = object.$getProperty(this, name);
    if (callable is! EvalCallable) throw StateError('$name is not callable');
    if (callable is $Closure) {
      return callable.func(this, callable.$this ?? object, arguments);
    }
    return (callable as EvalCallable).call(this, object, arguments);
  }

  $Value? _invokeTypedReference(
    int offset,
    List<$Value?> arguments, [
    List<Object?> captures = const [],
  ]) {
    final cache = _typedAdapters[this] ??= {};
    final adapter = cache.putIfAbsent(
      offset,
      () => _TypedLegacyAdapter.read(pr, offset),
    );
    return adapter.boxResult(
      _executeRegisters(offset, adapter.prepare(arguments), captures),
    );
  }
}

/// A conversion plan emitted by the compiler, never inferred from argument values.
final class _TypedLegacyAdapter {
  _TypedLegacyAdapter(this.parameters, this.result);
  final List<int> parameters;
  final int result;

  factory _TypedLegacyAdapter.read(List<Object?> words, int offset) {
    if (offset < 0 ||
        offset + 4 > words.length ||
        words[offset] != RegisterOp.entry.index) {
      throw StateError('Invalid reference function entry $offset');
    }
    final dataStart = offset + 4 + (words[offset + 2] as int);
    final dataCount = words[dataStart - 1] as int;
    if (dataCount < 5 || words[dataStart + 2] != 104) {
      throw StateError(
        'Reference function $offset has no typed-call signature. Recompile the program.',
      );
    }
    final count = words[dataStart + 3] as int;
    if (count < 0 || dataCount != count + 5) {
      throw StateError('Invalid typed-call signature at $offset');
    }
    return _TypedLegacyAdapter([
      for (var i = 0; i < count; i++) words[dataStart + 4 + i] as int,
    ], words[dataStart + 4 + count] as int);
  }

  List<Object?> prepare(List<$Value?> arguments) {
    if (arguments.length != parameters.length) {
      throw ArgumentError(
        'Expected ${parameters.length} arguments, got ${arguments.length}',
      );
    }
    return [
      for (var i = 0; i < arguments.length; i++)
        switch (parameters[i]) {
          0 => (arguments[i] as $int).$value,
          1 => (arguments[i] as $double).$value,
          2 => (arguments[i] as $bool).$value,
          3 => (arguments[i] as $String).$value,
          4 => arguments[i],
          _ => throw StateError(
            'Invalid argument representation ${parameters[i]}',
          ),
        },
    ];
  }

  $Value? boxResult(Object? value) => switch (result) {
    -1 => null,
    0 => $int(value as int),
    1 => $double(value as double),
    2 => $bool(value as bool),
    3 => $String(value as String),
    4 => value as $Value?,
    _ => throw StateError('Invalid result representation $result'),
  };
}
