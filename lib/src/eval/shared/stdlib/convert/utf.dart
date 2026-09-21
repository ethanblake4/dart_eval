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

import 'codec.dart';

import 'package:dart_eval/stdlib/typed_data.dart'
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

import 'converter.dart';
import 'byte_conversion.dart';

/// dart_eval wrapper binding for [Utf8Codec]
class $Utf8Codec implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'Utf8Codec.',
      $Utf8Codec.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Utf8Codec]
  static const $spec = BridgeTypeSpec('dart:convert', 'Utf8Codec');

  /// Compile-time type declaration of [$Utf8Codec]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Utf8Codec]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(ConvertTypes.encoding, []),
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
          namedParams: [
            BridgeParameter(
              'allowMalformed',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
            ),
          ],
          params: [],
        ),
        isFactory: false,
      ),
    },

    methods: {
      'encode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(TypedDataTypes.uint8List, []),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'string',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
      ),

      'decode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [
            BridgeParameter(
              'allowMalformed',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.bool, []),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'codeUnits',
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
    },
    getters: {
      'encoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.utf8Encoder, []),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'decoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.utf8Decoder, []),
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
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Utf8Codec.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Utf8Codec.wrap(
      Utf8Codec(
        allowMalformed: (r is $Value ? r : null) == null
            ? false
            : (r as $bool).$value,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final Utf8Codec $value;

  @override
  Utf8Codec get $reified => $value;

  /// Wrap a [Utf8Codec] in a [$Utf8Codec]
  $Utf8Codec.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'encoder':
        final _encoder = $value.encoder;
        return $Utf8Encoder.wrap(_encoder);
      case 'decoder':
        final _decoder = $value.decoder;
        return $Utf8Decoder.wrap(_decoder);
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
  static $Value? _encode(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Utf8Codec;
    final result = self.$value.encode((r as $String).$value);
    return $Uint8List.wrap(result);
  }

  static const $Function __decode = $Function(_decode);
  static $Value? _decode(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Utf8Codec;
    final result = self.$value.decode(
      ((r as $Value?)!.$reified as List).cast<int>(),
      allowMalformed: (s is $Value ? s : null)?.$value,
    );
    return $String(result);
  }

  static const $Function __fuse = $Function(_fuse);
  static $Value? _fuse(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Utf8Codec;
    final result = self.$value.fuse((r as $Value?)!.$value);
    return $Codec.wrap(result);
  }

  static const $Function __decodeStream = $Function(_decodeStream);
  static $Value? _decodeStream(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Utf8Codec;
    final result = self.$value.decodeStream((r as $Value?)!.$value);
    return $Future.wrap(result.then((e) => $String(e)));
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [Utf8Encoder]
class $Utf8Encoder implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'Utf8Encoder.',
      $Utf8Encoder.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Utf8Encoder]
  static const $spec = BridgeTypeSpec('dart:convert', 'Utf8Encoder');

  /// Compile-time type declaration of [$Utf8Encoder]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Utf8Encoder]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(ConvertTypes.converter, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
        ]),
        BridgeTypeRef(CoreTypes.object, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
        ]),
        BridgeTypeRef(AsyncTypes.streamTransformer, [
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
      'bind': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'stream',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.stream, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
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

      'convert': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(TypedDataTypes.uint8List, []),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'string',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'fuse': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'TT': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.converter, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              BridgeTypeAnnotation(BridgeTypeRef.ref('TT')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(ConvertTypes.converter, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.list, [
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                    ]),
                  ),
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
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'sink',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.sink, [
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
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Utf8Encoder.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Utf8Encoder.wrap(Utf8Encoder());
  }

  final $Instance _superclass;

  @override
  final Utf8Encoder $value;

  @override
  Utf8Encoder get $reified => $value;

  /// Wrap a [Utf8Encoder] in a [$Utf8Encoder]
  $Utf8Encoder.wrap(this.$value) : _superclass = $Object($value);

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
    final self = target! as $Utf8Encoder;
    final result = self.$value.bind((r as $Value?)!.$value);
    return $Stream.wrap(result.map((e) => $List.view(e, (e) => $int(e))));
  }

  static const $Function __cast = $Function(_cast);
  static $Value? _cast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Utf8Encoder;
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
    final self = target! as $Utf8Encoder;
    final result = self.$value.convert(
      (r as $String).$value,
      (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
      (c is List && (c as List).length > 0 ? (c as List)[0] as $Value? : null)
          ?.$value,
    );
    return $Uint8List.wrap(result);
  }

  static const $Function __fuse = $Function(_fuse);
  static $Value? _fuse(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Utf8Encoder;
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
    final self = target! as $Utf8Encoder;
    final result = self.$value.startChunkedConversion((r as $Value?)!.$value);
    return $Object(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [Utf8Decoder]
class $Utf8Decoder implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'Utf8Decoder.',
      $Utf8Decoder.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Utf8Decoder]
  static const $spec = BridgeTypeSpec('dart:convert', 'Utf8Decoder');

  /// Compile-time type declaration of [$Utf8Decoder]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Utf8Decoder]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(ConvertTypes.converter, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        ]),
        BridgeTypeRef(CoreTypes.object, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        ]),
        BridgeTypeRef(AsyncTypes.streamTransformer, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        ]),
      ],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'allowMalformed',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
            ),
          ],
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
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'stream',
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

      'convert': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'codeUnits',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              false,
            ),

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'fuse': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.converter, [
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'next',
              BridgeTypeAnnotation(
                BridgeTypeRef(ConvertTypes.converter, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
            BridgeTypeRef(ConvertTypes.byteConversionSink, []),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'sink',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.sink, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
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

  /// Wrapper for the [Utf8Decoder.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Utf8Decoder.wrap(
      Utf8Decoder(
        allowMalformed: (r is $Value ? r : null) == null
            ? false
            : (r as $bool).$value,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final Utf8Decoder $value;

  @override
  Utf8Decoder get $reified => $value;

  /// Wrap a [Utf8Decoder] in a [$Utf8Decoder]
  $Utf8Decoder.wrap(this.$value) : _superclass = $Object($value);

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
    final self = target! as $Utf8Decoder;
    final result = self.$value.bind((r as $Value?)!.$value);
    return $Stream.wrap(result.map((e) => $String(e)));
  }

  static const $Function __cast = $Function(_cast);
  static $Value? _cast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Utf8Decoder;
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
    final self = target! as $Utf8Decoder;
    final result = self.$value.convert(
      ((r as $Value?)!.$reified as List).cast<int>(),
      (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
      (c is List && (c as List).length > 0 ? (c as List)[0] as $Value? : null)
          ?.$value,
    );
    return $String(result);
  }

  static const $Function __fuse = $Function(_fuse);
  static $Value? _fuse(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Utf8Decoder;
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
    final self = target! as $Utf8Decoder;
    final result = self.$value.startChunkedConversion((r as $Value?)!.$value);
    return $ByteConversionSink.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
