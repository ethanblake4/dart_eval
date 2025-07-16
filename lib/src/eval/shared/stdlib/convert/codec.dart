import 'dart:convert';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/converter.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/object.dart';

/// dart_eval wrapper for [Codec]
class $Codec implements $Instance {
  /// Compile-type type definition for [$Codec]
  static const $type = BridgeTypeRef(ConvertTypes.codec);

  /// Compile-time bridge class declaration for [$Codec]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type, isAbstract: true, generics: {
        'S': BridgeGenericParam(),
        'T': BridgeGenericParam(),
      }),
      constructors: {},
      methods: {
        'encode': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            params: [
              BridgeParameter(
                  'input', BridgeTypeAnnotation(BridgeTypeRef.ref('S')), false)
            ])),
        'decode': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
            params: [
              BridgeParameter('encoded',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')), false)
            ])),
      },
      getters: {
        'encoder': BridgeMethodDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.converter, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('T'))
            ])),
            params: [])),
        'decoder': BridgeMethodDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.converter, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('S'))
            ])),
            params: [])),
      },
      wrap: true);

  /// Wrap a [Codec] in a [$Codec].
  $Codec.wrap(this.$value);

  late final $Instance _superclass = $Object($value);

  @override
  final Codec $value;

  @override
  Codec get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'encode':
        return __encode;
      case 'decode':
        return __decode;
      case 'encoder':
        return $Converter.wrap($value.encoder);
      case 'decoder':
        return $Converter.wrap($value.decoder);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  static const $Function __encode = $Function(_encode);

  static $Value? _encode(Runtime runtime, $Value? target, List<$Value?> args) {
    final input = args[0]!.$reified;
    final result = (target!.$value as Codec).encode(input);
    return runtime.wrap(result);
  }

  static const $Function __decode = $Function(_decode);

  static $Value? _decode(Runtime runtime, $Value? target, List<$Value?> args) {
    final encoded = args[0]!.$value;
    final result = (target!.$value as Codec).decode(encoded);
    return runtime.wrap(result, recursive: true);
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(ConvertTypes.codec);

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
