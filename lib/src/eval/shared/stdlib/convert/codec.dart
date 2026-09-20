// ignore_for_file: unused_import, unnecessary_import
// ignore_for_file: always_specify_types, avoid_redundant_argument_values
// ignore_for_file: sort_constructors_first
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_is_empty
// ignore_for_file: undefined_hidden_name
// ignore_for_file: dead_code, unused_local_variable
// ignore_for_file: unnecessary_type_check, unnecessary_non_null_assertion
// ignore_for_file: sdk_version_since
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: argument_type_not_assignable_to_error_handler
// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import 'dart:convert';
import 'package:dart_eval/stdlib/core.dart'
    hide
        $Converter,
        $Codec,
        $Encoding,
        $JsonEncoder,
        $JsonDecoder,
        $JsonCodec,
        $Utf8Decoder,
        $Utf8Codec,
        $Utf8Encoder,
        $Base64Encoder,
        $Base64Decoder,
        $Base64Codec,
        $ByteConversionSink,
        $ChunkedConversionSink;
import 'converter.dart';

/// dart_eval wrapper binding for [Codec]
class $Codec<S, T> implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {}

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Codec]
  static const $spec = BridgeTypeSpec('dart:convert', 'Codec');

  /// Compile-time type declaration of [$Codec]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Codec]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      generics: {'S': BridgeGenericParam(), 'T': BridgeGenericParam()},
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),
    },

    methods: {
      'encode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
          namedParams: [],
          params: [
            BridgeParameter(
              'input',
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
              false,
            ),
          ],
        ),
      ),

      'decode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
          namedParams: [],
          params: [
            BridgeParameter(
              'encoded',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),
          ],
        ),
      ),

      'fuse': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'R': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.codec, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(ConvertTypes.codec, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),
    },
    getters: {
      'encoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.converter, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'decoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.converter, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'inverted': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.codec, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  final $Instance _superclass;

  @override
  final Codec<S, T> $value;

  @override
  Codec get $reified => $value;

  /// Wrap a [Codec] in a [$Codec]
  $Codec.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'encoder':
        final _encoder = $value.encoder;
        return $Converter.wrap(_encoder);
      case 'decoder':
        final _decoder = $value.decoder;
        return $Converter.wrap(_decoder);
      case 'inverted':
        final _inverted = $value.inverted;
        return $Codec.wrap(_inverted);
      case 'encode':
        return __encode;

      case 'decode':
        return __decode;

      case 'fuse':
        return __fuse;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __encode = $Function(_encode);
  static $Value? _encode(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $Codec;
    final result = self.$value.encode(args[0]!.$value);
    return runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __decode = $Function(_decode);
  static $Value? _decode(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $Codec;
    final result = self.$value.decode(args[0]!.$value);
    return runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __fuse = $Function(_fuse);
  static $Value? _fuse(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $Codec;
    final result = self.$value.fuse(args[0]!.$value);
    return $Codec.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
