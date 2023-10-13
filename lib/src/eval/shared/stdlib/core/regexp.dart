import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/pattern.dart';

class $RegExp implements $Instance {
  static const $type = BridgeTypeRef(BridgeTypeSpec('dart:core', 'RegExp'));
  static const $declaration = BridgeClassDef(
      BridgeClassType($type, isAbstract: true, $extends: $Pattern.$type),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
          BridgeParameter(
              'source',
              BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.stringType)),
              false),
        ], namedParams: [
          BridgeParameter(
              'multiLine',
              BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType)),
              false),
          BridgeParameter(
              'caseSensitive',
              BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType)),
              false),
          BridgeParameter(
              'unicode',
              BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType)),
              false),
          BridgeParameter(
              'dotAll',
              BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType)),
              false),
        ]))
      },
      methods: {
        'hasMatch': BridgeMethodDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType)),
            params: [
              BridgeParameter(
                  'input',
                  BridgeTypeAnnotation(
                      BridgeTypeRef.type(RuntimeTypes.stringType)),
                  false),
            ])),
      },
      wrap: true);

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
