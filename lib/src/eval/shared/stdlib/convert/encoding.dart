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
import 'codec.dart';
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

/// dart_eval wrapper binding for [Encoding]
class $Encoding implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'Encoding.getByName',
      $Encoding.$getByName,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Encoding]
  static const $spec = BridgeTypeSpec('dart:convert', 'Encoding');

  /// Compile-time type declaration of [$Encoding]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Encoding]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      $implements: [
        BridgeTypeRef(ConvertTypes.codec, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
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
      'encode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'input',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
      ),

      'decode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'encoded',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
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
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(ConvertTypes.codec, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.list, [
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                    ]),
                  ),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'decodeStream': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteStream',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.stream, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.list, [
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                    ]),
                  ),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'getByName': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.encoding, []),
            nullable: true,
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),
    },
    getters: {
      'encoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.converter, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
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
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
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
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'name': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
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

  /// Wrapper for the [Encoding.getByName] method
  static $Value? $getByName(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Encoding.getByName((r as $Value?)!.$value);
    return value == null ? const $null() : $Encoding.wrap(value);
  }

  final $Instance _superclass;

  @override
  final Encoding $value;

  @override
  Encoding get $reified => $value;

  /// Wrap a [Encoding] in a [$Encoding]
  $Encoding.wrap(this.$value) : _superclass = $Object($value);

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
      case 'name':
        final _name = $value.name;
        return $String(_name);
      case 'encode':
        return __encode;

      case 'decode':
        return __decode;

      case 'fuse':
        return __fuse;

      case 'decodeStream':
        return __decodeStream;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __encode = $Function(_encode);
  static $Value? _encode(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $Encoding;
    final result = self.$value.encode(args[0]!.$value);
    return $List.view(result, (e) => $int(e));
  }

  static const $Function __decode = $Function(_decode);
  static $Value? _decode(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $Encoding;
    final result = self.$value.decode((args[0]!.$reified as List).cast<int>());
    return $String(result);
  }

  static const $Function __fuse = $Function(_fuse);
  static $Value? _fuse(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $Encoding;
    final result = self.$value.fuse(args[0]!.$value);
    return $Codec.wrap(result);
  }

  static const $Function __decodeStream = $Function(_decodeStream);
  static $Value? _decodeStream(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final self = target! as $Encoding;
    final result = self.$value.decodeStream(args[0]!.$value);
    return $Future.wrap(result.then((e) => $String(e)));
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
