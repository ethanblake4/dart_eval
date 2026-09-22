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

/// dart_eval wrapper binding for [Base64Codec]
class $Base64Codec implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'Base64Codec.',
      $Base64Codec.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'Base64Codec.urlSafe',
      $Base64Codec.$urlSafe,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Base64Codec]
  static const $spec = BridgeTypeSpec('dart:convert', 'Base64Codec');

  /// Compile-time type declaration of [$Base64Codec]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Base64Codec]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(ConvertTypes.codec, [
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
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),

      'urlSafe': BridgeConstructorDef(
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
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'input',
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

      'decode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(TypedDataTypes.uint8List, []),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'encoded',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
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
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(ConvertTypes.codec, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'normalize': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'source',
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
    },
    getters: {
      'encoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.base64Encoder, []),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'decoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.base64Decoder, []),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'inverted': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.codec, [
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
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Base64Codec.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Base64Codec.wrap(Base64Codec());
  }

  /// Wrapper for the [Base64Codec.urlSafe] constructor
  static $Value? $urlSafe(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Base64Codec.wrap(Base64Codec.urlSafe());
  }

  final $Instance _superclass;

  @override
  final Base64Codec $value;

  @override
  Base64Codec get $reified => $value;

  /// Wrap a [Base64Codec] in a [$Base64Codec]
  $Base64Codec.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'encoder':
        final _encoder = $value.encoder;
        return $Base64Encoder.wrap(_encoder);
      case 'decoder':
        final _decoder = $value.decoder;
        return $Base64Decoder.wrap(_decoder);
      case 'inverted':
        final _inverted = $value.inverted;
        return $Codec.wrap(_inverted);
      case 'encode':
        return $Closure(__encode.func, this);

      case 'decode':
        return $Closure(__decode.func, this);

      case 'fuse':
        return $Closure(__fuse.func, this);

      case 'normalize':
        return $Closure(__normalize.func, this);
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
    final self = target! as $Base64Codec;
    final result = self.$value.encode(
      ((r as $Value?)!.$reified as List).cast<int>(),
    );
    return $String(result);
  }

  static const $Function __decode = $Function(_decode);
  static $Value? _decode(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Base64Codec;
    final result = self.$value.decode((r as $String).$value);
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
    final self = target! as $Base64Codec;
    final result = self.$value.fuse((r as $Value?)!.$value);
    return $Codec.wrap(result);
  }

  static const $Function __normalize = $Function(_normalize);
  static $Value? _normalize(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Base64Codec;
    final result = self.$value.normalize(
      (r as $String).$value,
      (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
      (c is List && (c as List).length > 0 ? (c as List)[0] as $Value? : null)
          ?.$value,
    );
    return $String(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [Base64Encoder]
class $Base64Encoder implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'Base64Encoder.',
      $Base64Encoder.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'Base64Encoder.urlSafe',
      $Base64Encoder.$urlSafe,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Base64Encoder]
  static const $spec = BridgeTypeSpec('dart:convert', 'Base64Encoder');

  /// Compile-time type declaration of [$Base64Encoder]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Base64Encoder]
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
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),

      'urlSafe': BridgeConstructorDef(
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
              'input',
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
          generics: {'TT': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.converter, [
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              BridgeTypeAnnotation(BridgeTypeRef.ref('TT')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(ConvertTypes.converter, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
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

  /// Wrapper for the [Base64Encoder.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Base64Encoder.wrap(Base64Encoder());
  }

  /// Wrapper for the [Base64Encoder.urlSafe] constructor
  static $Value? $urlSafe(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Base64Encoder.wrap(Base64Encoder.urlSafe());
  }

  final $Instance _superclass;

  @override
  final Base64Encoder $value;

  @override
  Base64Encoder get $reified => $value;

  /// Wrap a [Base64Encoder] in a [$Base64Encoder]
  $Base64Encoder.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'bind':
        return $Closure(__bind.func, this);

      case 'cast':
        return $Closure(__cast.func, this);

      case 'convert':
        return $Closure(__convert.func, this);

      case 'fuse':
        return $Closure(__fuse.func, this);

      case 'startChunkedConversion':
        return $Closure(__startChunkedConversion.func, this);
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
    final self = target! as $Base64Encoder;
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
    final self = target! as $Base64Encoder;
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
    final self = target! as $Base64Encoder;
    final result = self.$value.convert(
      ((r as $Value?)!.$reified as List).cast<int>(),
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
    final self = target! as $Base64Encoder;
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
    final self = target! as $Base64Encoder;
    final result = self.$value.startChunkedConversion((r as $Value?)!.$value);
    return $ByteConversionSink.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [Base64Decoder]
class $Base64Decoder implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'Base64Decoder.',
      $Base64Decoder.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Base64Decoder]
  static const $spec = BridgeTypeSpec('dart:convert', 'Base64Decoder');

  /// Compile-time type declaration of [$Base64Decoder]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Base64Decoder]
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
              'input',
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

  /// Wrapper for the [Base64Decoder.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Base64Decoder.wrap(Base64Decoder());
  }

  final $Instance _superclass;

  @override
  final Base64Decoder $value;

  @override
  Base64Decoder get $reified => $value;

  /// Wrap a [Base64Decoder] in a [$Base64Decoder]
  $Base64Decoder.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'bind':
        return $Closure(__bind.func, this);

      case 'cast':
        return $Closure(__cast.func, this);

      case 'convert':
        return $Closure(__convert.func, this);

      case 'fuse':
        return $Closure(__fuse.func, this);

      case 'startChunkedConversion':
        return $Closure(__startChunkedConversion.func, this);
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
    final self = target! as $Base64Decoder;
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
    final self = target! as $Base64Decoder;
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
    final self = target! as $Base64Decoder;
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
    final self = target! as $Base64Decoder;
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
    final self = target! as $Base64Decoder;
    final result = self.$value.startChunkedConversion((r as $Value?)!.$value);
    return $Object(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
