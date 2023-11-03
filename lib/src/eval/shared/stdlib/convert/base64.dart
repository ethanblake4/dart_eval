/*
import 'dart:convert';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/codec.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/converter.dart';

/// dart_eval wrapper for [Base64Decoder]
class $Base64Decoder implements $Instance {
  /// Compile-time bridge type reference for [$Base64Decoder]
  static const $type = BridgeTypeRef(ConvertTypes.base64Decoder);

  /// Compile-time bridge class declaration for [$Base64Decoder]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type,
          $extends: BridgeTypeRef(ConvertTypes.converter, [
            BridgeTypeRef(CoreTypes.string),
            BridgeTypeRef(CoreTypes.list, [BridgeTypeRef(CoreTypes.int)]),
          ])),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type)))
      },
      methods: {},
      getters: {},
      setters: {},
      fields: {},
      wrap: true);

  /// Wrap a [Base64Decoder] in a [$Base64Decoder].
  $Base64Decoder.wrap(this.$value);

  static $Base64Decoder $new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $Base64Decoder.wrap(Base64Decoder());
  }

  late final $Instance _superclass = $Converter.wrap($value);

  @override
  final Base64Decoder $value;

  @override
  get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        return _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);
}

/// dart_eval wrapper for [Base64Encoder]
class $Base64Encoder implements $Instance {
  /// Compile-time bridge type reference for [$Base64Encoder]
  static const $type = BridgeTypeRef(ConvertTypes.base64Encoder);

  /// Compile-time bridge class declaration for [$Base64Encoder]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type,
          $extends: BridgeTypeRef(ConvertTypes.converter, [
            BridgeTypeRef(CoreTypes.list, [BridgeTypeRef(CoreTypes.int)]),
            BridgeTypeRef(CoreTypes.string),
          ])),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type)))
      },
      methods: {},
      getters: {},
      setters: {},
      fields: {},
      wrap: true);

  /// Wrap a [Base64Encoder] in a [$Base64Encoder].
  $Base64Encoder.wrap(this.$value);

  static $Base64Encoder $new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $Base64Encoder.wrap(Base64Encoder());
  }

  late final $Instance _superclass = $Converter.wrap($value);

  @override
  final Base64Encoder $value;

  @override
  get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        return _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);
}

/// dart_eval wrapper for [Base64Codec]
class $Base64Codec implements $Instance {
  /// Compile-time bridge type reference for [$Base64Codec]
  static const $type = BridgeTypeRef(ConvertTypes.base64Codec);

  /// Compile-time bridge class declaration for [$Base64Codec]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type, $extends: BridgeTypeRef(ConvertTypes.encoding)),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type)))
      },
      methods: {},
      getters: {
        'decoder': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(ConvertTypes.base64Decoder)))),
        'encoder': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(ConvertTypes.base64Encoder)))),
      },
      setters: {},
      fields: {},
      wrap: true);

  /// Wrap a [Base64Codec] in a [$Base64Codec].
  $Base64Codec.wrap(this.$value);

  static $Base64Codec $new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $Base64Codec.wrap(Base64Codec());
  }

  late final $Instance _superclass = $Codec.wrap($value);

  @override
  final Base64Codec $value;

  @override
  get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'decoder':
        return $Base64Decoder.wrap($value.decoder);
      case 'encoder':
        return $Base64Encoder.wrap($value.encoder);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        return _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(ConvertTypes.base64Codec);
}
*/