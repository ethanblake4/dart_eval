import 'dart:convert';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/codec.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/converter.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [Base64Decoder]
class $Base64Decoder implements $Instance {
  /// Compile-time bridge type reference for [$Base64Decoder]
  static const $type = BridgeTypeRef(ConvertTypes.base64Decoder);

  /// Compile-time bridge class declaration for [$Base64Decoder]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type,
          $extends: BridgeTypeRef(ConvertTypes.converter, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))])),
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
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))])),
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
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
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type))),
        'urlSafe': BridgeConstructorDef(
            BridgeFunctionDef(
              returns:
                  BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.base64Codec)),
            ),
            isFactory: true),
      },
      methods: {
        'encode': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            params: [
              BridgeParameter(
                  'input',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                      [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))])),
                  false),
            ])),
        'decode': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))])),
            params: [
              BridgeParameter('input',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
            ])),
      },
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

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        'dart:convert', 'Base64Encoder.', $Base64Encoder.$new);
    runtime.registerBridgeFunc(
        'dart:convert', 'Base64Decoder.', $Base64Decoder.$new);
    runtime.registerBridgeFunc(
        'dart:convert', 'Base64Codec.', $Base64Codec.$new);
    runtime.registerBridgeFunc('dart:convert', 'Base64Codec.urlSafe', _urlSafe);
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
      case 'encode':
        return __encode;
      case 'decode':
        return __decode;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  static const $Function __encode = $Function(_encode);
  static $Value? _encode(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    final input = (args[0]!.$value as List)
        .map((e) => (e is $Value ? e.$reified : e) as int)
        .toList();
    return $String((target as $Base64Codec).$value.encode(input));
  }

  static const $Function __decode = $Function(_decode);
  static $Value? _decode(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    return $List.wrap((target as $Base64Codec)
        .$value
        .decode(args[0]!.$value)
        .map((e) => $int(e))
        .toList());
  }

  static $Value? _urlSafe(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    return $Base64Codec.wrap(Base64Codec.urlSafe());
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
