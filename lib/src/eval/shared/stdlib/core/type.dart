import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval [$Value] representation of [Type]
class $Type implements $Instance, Type {
  $Type(this.$value) : _superclass = $Object($value);

  static const $declaration = BridgeClassDef(
    BridgeClassType(BridgeTypeRef(CoreTypes.type), isAbstract: true),
    constructors: {},
    wrap: true,
  );

  final $Instance _superclass;

  @override
  final Type $value;

  @override
  Type get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.type);

  @override
  bool operator ==(Object other) => other is $Type && $value == other.$value;

  @override
  int get hashCode => -12121212;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

class $TypeImpl implements $Type {
  $TypeImpl(this._typeId, [this._runtime]) : _superclass = $Object(_typeId);

  final int _typeId;
  final Runtime? _runtime;

  /// Rebind a guest Type without exposing or transferring its owning runtime.
  int typeIdIn(Runtime runtime) =>
      _runtime == null ? _typeId : runtime.importRuntimeType(_runtime, _typeId);

  @override
  final $Instance _superclass;

  @override
  Type get $value => throw UnimplementedError();

  @override
  Type get $reified => throw UnimplementedError();

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.type);

  @override
  bool operator ==(Object other) =>
      other is $TypeImpl &&
      (_runtime == null || other._runtime == null
          ? identical(_runtime, other._runtime) && other._typeId == _typeId
          : _runtime.runtimeTypesEqual(_typeId, other._runtime, other._typeId));

  @override
  int get hashCode => _runtime?.runtimeTypeHash(_typeId) ?? _typeId;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'toString':
        return $Closure.withNamed(
          _toString,
          $Object(this),
          positionalParameterCount: 0,
          namedParameters: const [],
        );
      case '==':
        return $Function((runtime, target, r, s, c) {
          final other = (r as $Value?);
          return $bool(this == other);
        });
      case 'hashCode':
        return $int(hashCode);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static $Value? _toString(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final type = target!.$value as $TypeImpl;
    return $String(
      type._runtime?.runtimeTypeToString(type._typeId) ?? "Instance of 'Type'",
    );
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
