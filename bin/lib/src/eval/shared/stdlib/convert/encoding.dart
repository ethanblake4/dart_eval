import 'dart:convert';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/codec.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';

/// dart_eval wrapper for [Encoding]
class $Encoding implements $Instance {
  /// Compile-type type definition for [$Encoding]
  static const $type = BridgeTypeRef(ConvertTypes.encoding);

  /// Compile-time bridge class declaration for [$Encoding]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type,
          isAbstract: true,
          $extends: BridgeTypeRef(ConvertTypes.codec, [
            BridgeTypeRef(CoreTypes.string),
            BridgeTypeRef(CoreTypes.list, [BridgeTypeRef(CoreTypes.int)]),
          ])),
      constructors: {},
      methods: {},
      getters: {
        'name': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            params: [])),
      },
      wrap: true);

  /// Wrap am [Encoding] in an [$Encoding].
  $Encoding.wrap(this.$value);

  late final $Instance _superclass = $Codec.wrap($value);

  @override
  final Encoding $value;

  @override
  Codec get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'name':
        return $String($value.name);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(ConvertTypes.encoding);

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
