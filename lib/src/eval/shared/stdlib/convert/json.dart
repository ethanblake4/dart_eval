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
import 'chunked_conversion.dart';

/// dart_eval wrapper binding for [JsonCodec]
class $JsonCodec implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'JsonCodec.',
      $JsonCodec.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'JsonCodec.withReviver',
      $JsonCodec.$withReviver,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$JsonCodec]
  static const $spec = BridgeTypeSpec('dart:convert', 'JsonCodec');

  /// Compile-time type declaration of [$JsonCodec]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$JsonCodec]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(ConvertTypes.codec, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.object, []),
            nullable: true,
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
              'reviver',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.object, []),
                      nullable: true,
                    ),
                    params: [
                      BridgeParameter(
                        'key',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.object, []),
                          nullable: true,
                        ),
                        false,
                      ),

                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.object, []),
                          nullable: true,
                        ),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'toEncodable',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.object, []),
                      nullable: true,
                    ),
                    params: [
                      BridgeParameter(
                        'null',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [],
        ),
        isFactory: false,
      ),

      'withReviver': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'reviver',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.dynamic),
                    ),
                    params: [
                      BridgeParameter(
                        'key',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.object, []),
                          nullable: true,
                        ),
                        false,
                      ),

                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.object, []),
                          nullable: true,
                        ),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {
      'encode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [
            BridgeParameter(
              'toEncodable',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.object, []),
                      nullable: true,
                    ),
                    params: [
                      BridgeParameter(
                        'object',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
            ),
          ],
        ),
      ),

      'decode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
          namedParams: [
            BridgeParameter(
              'reviver',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.object, []),
                      nullable: true,
                    ),
                    params: [
                      BridgeParameter(
                        'key',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.object, []),
                          nullable: true,
                        ),
                        false,
                      ),

                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.object, []),
                          nullable: true,
                        ),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'source',
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
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
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
    },
    getters: {
      'encoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.jsonEncoder, []),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'decoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.jsonDecoder, []),
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
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
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

  /// Wrapper for the [JsonCodec.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $JsonCodec.wrap(
      JsonCodec(
        reviver:
            (r is $Value ? r : null) == null ||
                (r is $Value ? r : null) is $null
            ? null
            : (Object? key, Object? value) {
                return ((r is $Value ? r : null)! as EvalCallable?)
                    ?.call(
                      runtime,
                      null,
                      (key == null ? const $null() : $Object(key)),
                      (value == null ? const $null() : $Object(value)),
                      2,
                    )
                    ?.$value;
              },
        toEncodable:
            (s is $Value ? s : null) == null ||
                (s is $Value ? s : null) is $null
            ? null
            : (dynamic arg0) {
                return ((s is $Value ? s : null)! as EvalCallable?)
                    ?.call(
                      runtime,
                      null,
                      runtime.wrapAlways(arg0, recursive: true),
                      null,
                      1,
                    )
                    ?.$value;
              },
      ),
    );
  }

  /// Wrapper for the [JsonCodec.withReviver] constructor
  static $Value? $withReviver(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $JsonCodec.wrap(
      JsonCodec.withReviver((Object? key, Object? value) {
        return ((r as $Value?)! as EvalCallable)(
          runtime,
          null,
          (key == null ? const $null() : $Object(key)),
          (value == null ? const $null() : $Object(value)),
          2,
        )?.$value;
      }),
    );
  }

  final $Instance _superclass;

  @override
  final JsonCodec $value;

  @override
  JsonCodec get $reified => $value;

  /// Wrap a [JsonCodec] in a [$JsonCodec]
  $JsonCodec.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'encoder':
        final _encoder = $value.encoder;
        return $JsonEncoder.wrap(_encoder);
      case 'decoder':
        final _decoder = $value.decoder;
        return $JsonDecoder.wrap(_decoder);
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
  static $Value? _encode(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $JsonCodec;
    final result = self.$value.encode(
      (r as $Value?)!.$reified,
      toEncodable:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : (dynamic object) {
              return ((s is $Value ? s : null)! as EvalCallable?)
                  ?.call(
                    runtime,
                    null,
                    runtime.wrapAlways(object, recursive: true),
                    null,
                    1,
                  )
                  ?.$value;
            },
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
    final self = target! as $JsonCodec;
    final result = self.$value.decode(
      (r as $String).$value,
      reviver:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : (Object? key, Object? value) {
              return ((s is $Value ? s : null)! as EvalCallable?)
                  ?.call(
                    runtime,
                    null,
                    (key == null ? const $null() : $Object(key)),
                    (value == null ? const $null() : $Object(value)),
                    2,
                  )
                  ?.$value;
            },
    );
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
    final self = target! as $JsonCodec;
    final result = self.$value.fuse((r as $Value?)!.$value);
    return $Codec.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [JsonEncoder]
class $JsonEncoder implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'JsonEncoder.',
      $JsonEncoder.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'JsonEncoder.withIndent',
      $JsonEncoder.$withIndent,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$JsonEncoder]
  static const $spec = BridgeTypeSpec('dart:convert', 'JsonEncoder');

  /// Compile-time type declaration of [$JsonEncoder]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$JsonEncoder]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(ConvertTypes.converter, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.object, []),
            nullable: true,
          ),
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        ]),
        BridgeTypeRef(CoreTypes.object, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.object, []),
            nullable: true,
          ),
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        ]),
        BridgeTypeRef(AsyncTypes.streamTransformer, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.object, []),
            nullable: true,
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
          params: [
            BridgeParameter(
              'toEncodable',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.object, []),
                      nullable: true,
                    ),
                    params: [
                      BridgeParameter(
                        'object',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: false,
      ),

      'withIndent': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'indent',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              false,
            ),

            BridgeParameter(
              'toEncodable',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.object, []),
                      nullable: true,
                    ),
                    params: [
                      BridgeParameter(
                        'object',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
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
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
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
              'object',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
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
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
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
            BridgeTypeRef(ConvertTypes.chunkedConversionSink, [
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
            ]),
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
    fields: {
      'indent': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.string, []),
          nullable: true,
        ),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [JsonEncoder.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $JsonEncoder.wrap(
      JsonEncoder(
        (r is $Value ? r : null) == null || (r is $Value ? r : null) is $null
            ? null
            : (dynamic object) {
                return ((r is $Value ? r : null)! as EvalCallable?)
                    ?.call(
                      runtime,
                      null,
                      runtime.wrapAlways(object, recursive: true),
                      null,
                      1,
                    )
                    ?.$value;
              },
      ),
    );
  }

  /// Wrapper for the [JsonEncoder.withIndent] constructor
  static $Value? $withIndent(Runtime runtime, Object? r, Object? s, Object? c) {
    return $JsonEncoder.wrap(
      JsonEncoder.withIndent(
        (r as $Value?)!.$value,
        (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
            ? null
            : (dynamic object) {
                return ((s is $Value ? s : null)! as EvalCallable?)
                    ?.call(
                      runtime,
                      null,
                      runtime.wrapAlways(object, recursive: true),
                      null,
                      1,
                    )
                    ?.$value;
              },
      ),
    );
  }

  final $Instance _superclass;

  @override
  final JsonEncoder $value;

  @override
  JsonEncoder get $reified => $value;

  /// Wrap a [JsonEncoder] in a [$JsonEncoder]
  $JsonEncoder.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'indent':
        final _indent = $value.indent;
        return _indent == null ? const $null() : $String(_indent);
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
    final self = target! as $JsonEncoder;
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
    final self = target! as $JsonEncoder;
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
    final self = target! as $JsonEncoder;
    final result = self.$value.convert((r as $Value?)!.$reified);
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
    final self = target! as $JsonEncoder;
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
    final self = target! as $JsonEncoder;
    final result = self.$value.startChunkedConversion((r as $Value?)!.$value);
    return $ChunkedConversionSink.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [JsonDecoder]
class $JsonDecoder implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'JsonDecoder.',
      $JsonDecoder.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$JsonDecoder]
  static const $spec = BridgeTypeSpec('dart:convert', 'JsonDecoder');

  /// Compile-time type declaration of [$JsonDecoder]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$JsonDecoder]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(ConvertTypes.converter, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.object, []),
            nullable: true,
          ),
        ]),
        BridgeTypeRef(CoreTypes.object, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.object, []),
            nullable: true,
          ),
        ]),
        BridgeTypeRef(AsyncTypes.streamTransformer, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.object, []),
            nullable: true,
          ),
        ]),
      ],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'reviver',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.object, []),
                      nullable: true,
                    ),
                    params: [
                      BridgeParameter(
                        'key',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.object, []),
                          nullable: true,
                        ),
                        false,
                      ),

                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.object, []),
                          nullable: true,
                        ),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
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
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
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
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
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
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
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
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
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

  /// Wrapper for the [JsonDecoder.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $JsonDecoder.wrap(
      JsonDecoder(
        (r is $Value ? r : null) == null || (r is $Value ? r : null) is $null
            ? null
            : (Object? key, Object? value) {
                return ((r is $Value ? r : null)! as EvalCallable?)
                    ?.call(
                      runtime,
                      null,
                      (key == null ? const $null() : $Object(key)),
                      (value == null ? const $null() : $Object(value)),
                      2,
                    )
                    ?.$value;
              },
      ),
    );
  }

  final $Instance _superclass;

  @override
  final JsonDecoder $value;

  @override
  JsonDecoder get $reified => $value;

  /// Wrap a [JsonDecoder] in a [$JsonDecoder]
  $JsonDecoder.wrap(this.$value) : _superclass = $Object($value);

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
    final self = target! as $JsonDecoder;
    final result = self.$value.bind((r as $Value?)!.$value);
    return $Stream.wrap(
      result.map((e) => e == null ? const $null() : $Object(e)),
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
    final self = target! as $JsonDecoder;
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
    final self = target! as $JsonDecoder;
    final result = self.$value.convert((r as $String).$value);
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
    final self = target! as $JsonDecoder;
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
    final self = target! as $JsonDecoder;
    final result = self.$value.startChunkedConversion((r as $Value?)!.$value);
    return $Object(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
