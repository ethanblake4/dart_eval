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
      // List-based callbacks may retain or mutate their argument vector. This is
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
      if (receiver is EvalCallable) {
        return receiver.call(this, receiver as $Value?, arguments);
      }
    }
    final object = receiver as $Instance;
    final callable = object.$getProperty(this, name);
    if (callable is! EvalCallable) throw StateError('$name is not callable');
    return (callable as EvalCallable).call(this, object, arguments);
  }
}
