import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/pattern.dart';

/// dart_eval wrapper for [RegExp]
class $RegExp implements $Instance {
  /// Compile-time type reference to [RegExp]
  static const $type = BridgeTypeRef(BridgeTypeSpec('dart:core', 'RegExp'));

  /// Compile-time bridge declaration of [RegExp]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type, isAbstract: true, $extends: $Pattern.$type),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
          BridgeParameter('source',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
        ], namedParams: [
          BridgeParameter('multiLine',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), false),
          BridgeParameter('caseSensitive',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), false),
          BridgeParameter('unicode',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), false),
          BridgeParameter('dotAll',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), false),
        ]))
      },
      methods: {
        'hasMatch': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
            params: [
              BridgeParameter('input',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
            ])),
      },
      wrap: true);

  /// Wrap a [RegExp] in a [$RegExp]
  $RegExp.wrap(this.$value) : _superclass = $Pattern.wrap($value);

  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $RegExp.wrap(RegExp(args[0]!.$value,
        multiLine: args[1]?.$value ?? false,
        caseSensitive: args[2]?.$value ?? false,
        unicode: args[3]?.$value ?? false,
        dotAll: args[4]?.$value ?? false));
  }

  @override
  final RegExp $value;

  @override
  RegExp get $reified => $value;

  final $Instance _superclass;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'hasMatch':
        return __hasMatch;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  static const $Function __hasMatch = $Function(_hasMatch);

  static $Value? _hasMatch(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $Value;
    final input = (args[0] as $String).$value;
    return $bool((target.$value as RegExp).hasMatch(input));
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);
}
