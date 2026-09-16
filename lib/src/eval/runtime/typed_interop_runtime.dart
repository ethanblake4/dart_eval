part of 'runtime.dart';

/// The bridge boundary accepts canonical language values. Function signatures
/// prescribe every conversion before entering the typed register loop.
extension TypedRuntimeInterop on Runtime {
  Object? typedConstant(int index) => _constantPool[index];

  /// Prepare bridge registrations and runtime-owned globals at a VM entry.
  @pragma('vm:never-inline')
  void prepareTypedRuntime() => _setup();

  @pragma('vm:never-inline')
  bool isTypedValueType(Object? value, int expected) {
    final actual = value == null
        ? lookupType(CoreTypes.nullType)
        : (value as $Value).$getRuntimeType(this);
    return actual == expected ||
        (actual >= 0 &&
            actual < _typeTypes.length &&
            _typeTypes[actual].contains(expected));
  }

  $Value? invokeTypedExternal(
    int functionId,
    int argumentCount,
    Object? first,
    Object? second,
    Object? rest,
  ) {
    _setup();
    if (functionId < 0 || functionId >= _bridgeFunctions.length) {
      throw ArgumentError.value(functionId, 'functionId', 'Invalid bridge ID');
    }
    final direct = _bridgeRegisterFunctions[functionId];
    final $Value? result;
    if (direct != null) {
      result = direct(this, first, second, rest);
    } else {
      // Legacy callbacks may retain or mutate their argument vector. This is
      // the only external-call path that materializes a fresh list.
      final arguments = switch (argumentCount) {
        0 => <$Value?>[],
        1 => <$Value?>[first as $Value?],
        2 => <$Value?>[first as $Value?, second as $Value?],
        3 => <$Value?>[first as $Value?, second as $Value?, rest as $Value?],
        _ => <$Value?>[
          first as $Value?,
          second as $Value?,
          for (var i = 0; i < argumentCount - 2; i++)
            (rest as List<Object?>)[i] as $Value?,
        ],
      };
      result = _bridgeFunctions[functionId](this, null, arguments);
    }
    return result is $null ? null : result;
  }

  bool isTypedExternalAssignable($Value value, String library, String name) {
    _setup();
    final expected = lookupType(BridgeTypeSpec(library, name));
    final actual = value.$getRuntimeType(this);
    return actual == expected ||
        (actual >= 0 &&
            actual < _typeTypes.length &&
            _typeTypes[actual].contains(expected));
  }

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
    if (receiver is TypedInstance) {
      return receiver.invoke(name, arguments, runtime: this);
    }
    if (name == 'call') {
      if (receiver is EvalStaticFunctionPtr) {
        return _invokeTypedFunction(receiver.offset, [
          if (receiver.$this != null) receiver.$this,
          ...arguments,
        ]);
      }
      if (receiver is $Closure) {
        return receiver.func(this, receiver.$this, arguments);
      }
      if (receiver is EvalCallable) {
        return receiver.call(this, receiver as $Value?, arguments);
      }
    }
    final object = receiver as $Instance;
    final callable = object.$getProperty(this, name);
    if (callable is! EvalCallable) throw StateError('$name is not callable');
    if (callable is $Closure) {
      return callable.func(this, callable.$this ?? object, arguments);
    }
    return (callable as EvalCallable).call(this, object, arguments);
  }

  $Value? _invokeTypedFunction(int functionId, List<$Value?> arguments) {
    _setup();
    final function = _typedProgram.functions[functionId];
    if (arguments.length != function.argumentKinds.length) {
      throw ArgumentError(
        'Invalid argument count for typed function $functionId',
      );
    }
    final entry = TypedEntry.fromValues(function, [
      for (var i = 0; i < arguments.length; i++)
        switch (function.argumentKinds[i]) {
          TypedArgumentKind.integer => (arguments[i] as $int).$value,
          TypedArgumentKind.doublePrecision => (arguments[i] as $double).$value,
          TypedArgumentKind.boolean => (arguments[i] as $bool).$value,
          TypedArgumentKind.string => (arguments[i] as $String).$value,
          TypedArgumentKind.object => arguments[i],
        },
    ]);
    final result = TypedMachine.runEntry(
      _typedProgram,
      entry,
      functionId,
      runtime: this,
    );
    return switch (function.resultKind) {
      null => null,
      TypedArgumentKind.integer => $int(result as int),
      TypedArgumentKind.doublePrecision => $double(result as double),
      TypedArgumentKind.boolean => $bool(result as bool),
      TypedArgumentKind.string => $String(result as String),
      TypedArgumentKind.object => result as $Value?,
    };
  }
}
