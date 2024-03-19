import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [Zone]
class $Zone implements $Instance {
  static const _$type = BridgeTypeRef(AsyncTypes.zone);

  static const $declaration = BridgeClassDef(BridgeClassType(_$type),
      constructors: {},
      methods: {
        '[]': BridgeMethodDef(BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
          params: [
            BridgeParameter(
                'key',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                    nullable: true),
                false)
          ],
        )),
      },
      getters: {
        'current': BridgeMethodDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation(_$type)),
            isStatic: true),
        'root': BridgeMethodDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation(_$type)),
            isStatic: true),
      },
      setters: {},
      fields: {},
      wrap: true);

  static $Value? $current(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Zone.wrap(Zone.current[1]);
  }

  static $Value? $root(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Zone.wrap(Zone.root);
  }

  final $Instance _superclass;

  /// Wrap a [Zone] in a [$Zone]
  $Zone.wrap(this.$value) : _superclass = $Object($value);

  @override
  final Zone $value;

  @override
  Zone get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => throw UnimplementedError();

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '[]':
        return __$index;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __$index = $Function(_$index);

  static $Value? _$index(Runtime runtime, $Value? target, List<$Value?> args) {
    return runtime.wrap((target!.$value as Zone)[args[0]?.$value]);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
