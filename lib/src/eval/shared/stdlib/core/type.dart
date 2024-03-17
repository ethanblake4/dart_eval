import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval [$Value] representation of [Type]
class $Type implements $Instance, Type {
  $Type(this.$value) : _superclass = $Object($value);

  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.type), isAbstract: true),
      constructors: {},
      wrap: true);

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
  $TypeImpl(this._typeId) : _superclass = $Object(_typeId);

  final int _typeId;

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
      other is $TypeImpl && other._typeId == _typeId;

  @override
  int get hashCode => _typeId;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'toString':
        return $Function(
            ((runtime, target, args) => $String("Instance of 'Type'")));
      case '==':
        return $Function((runtime, target, args) {
          final other = args[0];
          return $bool(other is $TypeImpl && other._typeId == _typeId);
        });
      case 'hashCode':
        return $int(_typeId);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
