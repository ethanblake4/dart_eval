// ignore_for_file: unused_import, unnecessary_import
// ignore_for_file: always_specify_types, avoid_redundant_argument_values
// ignore_for_file: sort_constructors_first
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_is_empty
// ignore_for_file: undefined_hidden_name
// ignore_for_file: dead_code, unused_local_variable
// ignore_for_file: unnecessary_type_check, unnecessary_non_null_assertion
// ignore_for_file: unnecessary_cast
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
import 'package:dart_eval/stdlib/async.dart'
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

/// dart_eval wrapper binding for [Converter]
class $Converter<S, T> implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'Converter.castFrom',
      $Converter.$castFrom,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Converter]
  static const $spec = BridgeTypeSpec('dart:convert', 'Converter');

  /// Compile-time type declaration of [$Converter]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Converter]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      generics: {'S': BridgeGenericParam(), 'T': BridgeGenericParam()},

      $implements: [
        BridgeTypeRef(CoreTypes.object, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
          BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
        ]),
        BridgeTypeRef(AsyncTypes.streamTransformer, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
          BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
        ]),
      ],
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
      'bind': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'stream',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.stream, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'cast': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'RS': BridgeGenericParam(), 'RT': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.converter, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('RS')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('RT')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'castFrom': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {
            'SS': BridgeGenericParam(),
            'ST': BridgeGenericParam(),
            'TS': BridgeGenericParam(),
            'TT': BridgeGenericParam(),
          },
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.converter, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('TS')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('TT')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(
                BridgeTypeRef(ConvertTypes.converter, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('SS')),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('ST')),
                ]),
              ),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'convert': BridgeMethodDef(
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

      'fuse': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'TT': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.converter, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('TT')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(ConvertTypes.converter, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('TT')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'startChunkedConversion': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.sink, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'sink',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.sink, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Converter.castFrom] method
  static $Value? $castFrom(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Converter.castFrom((r as $Value?)!.$value);
    return $Converter.wrap(value);
  }

  final $Instance _superclass;

  @override
  final Converter<S, T> $value;

  @override
  Converter get $reified => $value;

  /// Wrap a [Converter] in a [$Converter]
  $Converter.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'bind':
        return __bind;

      case 'cast':
        return __cast;

      case 'convert':
        return __convert;

      case 'fuse':
        return __fuse;

      case 'startChunkedConversion':
        return __startChunkedConversion;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __bind = $Function(_bind);
  static $Value? _bind(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Converter;
    final result = self.$value.bind((r as $Value?)!.$value);
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __cast = $Function(_cast);
  static $Value? _cast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Converter;
    final result = self.$value.cast();
    return $Converter.wrap(result);
  }

  static const $Function __convert = $Function(_convert);
  static $Value? _convert(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Converter;
    final result = self.$value.convert((r as $Value?)!.$value);
    return runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __fuse = $Function(_fuse);
  static $Value? _fuse(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Converter;
    final result = self.$value.fuse((r as $Value?)!.$value);
    return $Converter.wrap(result);
  }

  static const $Function __startChunkedConversion = $Function(
    _startChunkedConversion,
  );
  static $Value? _startChunkedConversion(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Converter;
    final result = self.$value.startChunkedConversion((r as $Value?)!.$value);
    return $Sink.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
