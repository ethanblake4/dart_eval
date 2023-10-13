import 'dart:convert';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/converter.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [Utf8Decoder]
class $Utf8Decoder implements $Instance {
  /// Compile-time bridge type reference for [$Utf8Decoder]
  static const $type =
      BridgeTypeRef(BridgeTypeSpec('dart:convert', 'Utf8Decoder'));

  /// Compile-time bridge class declaration for [$Utf8Decoder]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type,
          $extends: BridgeTypeRef(ConvertTypes.converter, [
            BridgeTypeRef(CoreTypes.list, [BridgeTypeRef(CoreTypes.int)]),
            BridgeTypeRef(CoreTypes.string),
          ])),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation($type),
            params: [],
            namedParams: [
              BridgeParameter(
                  'allowMalformed',
                  BridgeTypeAnnotation(
                      BridgeTypeRef.type(RuntimeTypes.boolType)),
                  true)
            ]))
      },
      methods: {},
      getters: {},
      setters: {},
      fields: {},
      wrap: true);

  /// Wrap a [Utf8Decoder] in a [$Utf8Decoder].
  $Utf8Decoder.wrap(this.$value);

  static $Utf8Decoder $new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final allowMalformed = args[0]?.$value as bool? ?? false;
    return $Utf8Decoder.wrap(Utf8Decoder(allowMalformed: allowMalformed));
  }

  late final $Instance _superclass = $Converter.wrap($value);

  @override
  final Utf8Decoder $value;

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

/// dart_eval wrapper for [Utf8Codec]
class $Utf8Codec implements $Instance {
  /// Compile-time bridge type reference for [$Utf8Codec]
  static const $type = BridgeTypeRef(ConvertTypes.utf8Codec);

  /// Compile-time bridge class declaration for [$Utf8Codec]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type, $extends: BridgeTypeRef(ConvertTypes.encoding)),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation($type),
            params: [],
            namedParams: [
              BridgeParameter(
                  'allowMalformed',
                  BridgeTypeAnnotation(
                      BridgeTypeRef.type(RuntimeTypes.boolType)),
                  true)
            ]))
      },
      methods: {},
      getters: {
        'decoder': BridgeMethodDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.utf8Decoder, [
          BridgeTypeRef(CoreTypes.list, [BridgeTypeRef(CoreTypes.int)]),
          BridgeTypeRef(CoreTypes.string),
        ])))),
      },
      setters: {},
      fields: {},
      wrap: true);

  /// Wrap a [Utf8Codec] in a [$Utf8Codec].
  $Utf8Codec.wrap(this.$value);

  static $Utf8Codec $new(Runtime runtime, $Value? target, List<$Value?> args) {
    final allowMalformed = args[0]?.$value as bool? ?? false;
    return $Utf8Codec.wrap(Utf8Codec(allowMalformed: allowMalformed));
  }

  late final $Instance _superclass = /*$Codec.wrap($value);*/ $Object($value);

  @override
  final Utf8Codec $value;

  @override
  get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'decoder':
        return $Utf8Decoder.wrap($value.decoder);
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
