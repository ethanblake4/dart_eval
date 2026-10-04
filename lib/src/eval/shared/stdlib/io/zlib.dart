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

import 'dart:io';
import 'dart:convert';

import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart'
    hide
        $Platform,
        $SocketException,
        $HttpException,
        $OSError,
        $HttpHeaders,
        $RedirectInfo,
        $Socket,
        $ZLibCodec,
        $GZipCodec,
        $ZLibEncoder,
        $ZLibDecoder;

import '../convert/codec.dart';

import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/stdlib/async.dart'
    hide
        $Platform,
        $SocketException,
        $HttpException,
        $OSError,
        $HttpHeaders,
        $RedirectInfo,
        $Socket,
        $ZLibCodec,
        $GZipCodec,
        $ZLibEncoder,
        $ZLibDecoder;

import '../convert/converter.dart';
import '../convert/byte_conversion.dart';

/// dart_eval wrapper binding for [ZLibCodec]
class $ZLibCodec implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'ZLibCodec.',
      $ZLibCodec.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$ZLibCodec]
  static const $spec = BridgeTypeSpec('dart:io', 'ZLibCodec');

  /// Compile-time type declaration of [$ZLibCodec]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ZLibCodec]
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
              'level',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "ZLibOption.defaultLevel",
            ),

            BridgeParameter(
              'windowBits',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "ZLibOption.defaultWindowBits",
            ),

            BridgeParameter(
              'memLevel',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "ZLibOption.defaultMemLevel",
            ),

            BridgeParameter(
              'strategy',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "ZLibOption.strategyDefault",
            ),

            BridgeParameter(
              'dictionary',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'raw',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
            ),

            BridgeParameter(
              'gzip',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
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
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
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
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
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
    },
    getters: {
      'encoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(IoTypes.zLibEncoder, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'decoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(IoTypes.zLibDecoder, [])),
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
    fields: {
      'gzip': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),

      'level': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),

      'memLevel': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),

      'strategy': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),

      'windowBits': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),

      'raw': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),

      'dictionary': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.list, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          ]),
          nullable: true,
        ),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [ZLibCodec.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;
    final _arg5OrNull = c is List && c.length > 3 ? c[3] as $Value? : null;
    final _arg6OrNull = c is List && c.length > 4 ? c[4] as $Value? : null;

    return $ZLibCodec.wrap(
      ZLibCodec(
        level: (r is $Value ? r : null) == null
            ? ZLibOption.defaultLevel
            : (r as $int).$value,
        windowBits: (s is $Value ? s : null) == null
            ? ZLibOption.defaultWindowBits
            : (s as $int).$value,
        memLevel: _arg2OrNull == null
            ? ZLibOption.defaultMemLevel
            : (_arg2OrNull as $int).$value,
        strategy: _arg3OrNull == null
            ? ZLibOption.strategyDefault
            : (_arg3OrNull as $int).$value,
        dictionary: (TypedInterop.exportExternal(
          _arg4OrNull,
          runtime: runtime,
        ) as List?)?.cast<int>(),
        raw: _arg5OrNull == null ? false : (_arg5OrNull as $bool).$value,
        gzip: _arg6OrNull == null ? false : (_arg6OrNull as $bool).$value,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final ZLibCodec $value;

  @override
  ZLibCodec get $reified => $value;

  /// Wrap a [ZLibCodec] in a [$ZLibCodec]
  $ZLibCodec.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'encoder':
        final _encoder = $value.encoder;
        return $ZLibEncoder.wrap(_encoder);
      case 'decoder':
        final _decoder = $value.decoder;
        return $ZLibDecoder.wrap(_decoder);
      case 'inverted':
        final _inverted = $value.inverted;
        return $Codec.wrap(_inverted);
      case 'gzip':
        final _gzip = $value.gzip;
        return $bool(_gzip);
      case 'level':
        final _level = $value.level;
        return $int(_level);
      case 'memLevel':
        final _memLevel = $value.memLevel;
        return $int(_memLevel);
      case 'strategy':
        final _strategy = $value.strategy;
        return $int(_strategy);
      case 'windowBits':
        final _windowBits = $value.windowBits;
        return $int(_windowBits);
      case 'raw':
        final _raw = $value.raw;
        return $bool(_raw);
      case 'dictionary':
        final _dictionary = $value.dictionary;
        return _dictionary == null
            ? const $null()
            : $List.view(
                _dictionary,
                (e) => $int(e),
                runtime: runtime,
                runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
                  runtime.lookupType(CoreTypes.int),
                ]),
              );
      case 'encode':
        return $Closure(__encode.func, this);

      case 'decode':
        return $Closure(__decode.func, this);

      case 'fuse':
        return $Closure(__fuse.func, this);
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
    final self = target! as $ZLibCodec;
    final result = self.$value.encode(
      (TypedInterop.exportExternal((r as $Value?), runtime: runtime) as List)
          .cast<int>(),
    );
    return $List.view(
      result,
      (e) => $int(e),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.lookupType(CoreTypes.int),
      ]),
    );
  }

  static const $Function __decode = $Function(_decode);
  static $Value? _decode(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ZLibCodec;
    final result = self.$value.decode(
      (TypedInterop.exportExternal((r as $Value?), runtime: runtime) as List)
          .cast<int>(),
    );
    return $List.view(
      result,
      (e) => $int(e),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.lookupType(CoreTypes.int),
      ]),
    );
  }

  static const $Function __fuse = $Function(_fuse);
  static $Value? _fuse(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ZLibCodec;
    final result = self.$value.fuse((r as $Value?)!.$value);
    return $Codec.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [GZipCodec]
class $GZipCodec implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'GZipCodec.',
      $GZipCodec.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$GZipCodec]
  static const $spec = BridgeTypeSpec('dart:io', 'GZipCodec');

  /// Compile-time type declaration of [$GZipCodec]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$GZipCodec]
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
              'level',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "ZLibOption.defaultLevel",
            ),

            BridgeParameter(
              'windowBits',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "ZLibOption.defaultWindowBits",
            ),

            BridgeParameter(
              'memLevel',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "ZLibOption.defaultMemLevel",
            ),

            BridgeParameter(
              'strategy',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "ZLibOption.strategyDefault",
            ),

            BridgeParameter(
              'dictionary',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'raw',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
            ),

            BridgeParameter(
              'gzip',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "true",
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
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
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
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
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
    },
    getters: {
      'encoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(IoTypes.zLibEncoder, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'decoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(IoTypes.zLibDecoder, [])),
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
    fields: {
      'gzip': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),

      'level': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),

      'memLevel': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),

      'strategy': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),

      'windowBits': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),

      'dictionary': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.list, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          ]),
          nullable: true,
        ),
        isStatic: false,
      ),

      'raw': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [GZipCodec.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;
    final _arg5OrNull = c is List && c.length > 3 ? c[3] as $Value? : null;
    final _arg6OrNull = c is List && c.length > 4 ? c[4] as $Value? : null;

    return $GZipCodec.wrap(
      GZipCodec(
        level: (r is $Value ? r : null) == null
            ? ZLibOption.defaultLevel
            : (r as $int).$value,
        windowBits: (s is $Value ? s : null) == null
            ? ZLibOption.defaultWindowBits
            : (s as $int).$value,
        memLevel: _arg2OrNull == null
            ? ZLibOption.defaultMemLevel
            : (_arg2OrNull as $int).$value,
        strategy: _arg3OrNull == null
            ? ZLibOption.strategyDefault
            : (_arg3OrNull as $int).$value,
        dictionary: (TypedInterop.exportExternal(
          _arg4OrNull,
          runtime: runtime,
        ) as List?)?.cast<int>(),
        raw: _arg5OrNull == null ? false : (_arg5OrNull as $bool).$value,
        gzip: _arg6OrNull == null ? true : (_arg6OrNull as $bool).$value,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final GZipCodec $value;

  @override
  GZipCodec get $reified => $value;

  /// Wrap a [GZipCodec] in a [$GZipCodec]
  $GZipCodec.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'encoder':
        final _encoder = $value.encoder;
        return $ZLibEncoder.wrap(_encoder);
      case 'decoder':
        final _decoder = $value.decoder;
        return $ZLibDecoder.wrap(_decoder);
      case 'inverted':
        final _inverted = $value.inverted;
        return $Codec.wrap(_inverted);
      case 'gzip':
        final _gzip = $value.gzip;
        return $bool(_gzip);
      case 'level':
        final _level = $value.level;
        return $int(_level);
      case 'memLevel':
        final _memLevel = $value.memLevel;
        return $int(_memLevel);
      case 'strategy':
        final _strategy = $value.strategy;
        return $int(_strategy);
      case 'windowBits':
        final _windowBits = $value.windowBits;
        return $int(_windowBits);
      case 'dictionary':
        final _dictionary = $value.dictionary;
        return _dictionary == null
            ? const $null()
            : $List.view(
                _dictionary,
                (e) => $int(e),
                runtime: runtime,
                runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
                  runtime.lookupType(CoreTypes.int),
                ]),
              );
      case 'raw':
        final _raw = $value.raw;
        return $bool(_raw);
      case 'encode':
        return $Closure(__encode.func, this);

      case 'decode':
        return $Closure(__decode.func, this);

      case 'fuse':
        return $Closure(__fuse.func, this);
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
    final self = target! as $GZipCodec;
    final result = self.$value.encode(
      (TypedInterop.exportExternal((r as $Value?), runtime: runtime) as List)
          .cast<int>(),
    );
    return $List.view(
      result,
      (e) => $int(e),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.lookupType(CoreTypes.int),
      ]),
    );
  }

  static const $Function __decode = $Function(_decode);
  static $Value? _decode(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $GZipCodec;
    final result = self.$value.decode(
      (TypedInterop.exportExternal((r as $Value?), runtime: runtime) as List)
          .cast<int>(),
    );
    return $List.view(
      result,
      (e) => $int(e),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.lookupType(CoreTypes.int),
      ]),
    );
  }

  static const $Function __fuse = $Function(_fuse);
  static $Value? _fuse(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $GZipCodec;
    final result = self.$value.fuse((r as $Value?)!.$value);
    return $Codec.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [ZLibEncoder]
class $ZLibEncoder implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'ZLibEncoder.',
      $ZLibEncoder.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$ZLibEncoder]
  static const $spec = BridgeTypeSpec('dart:io', 'ZLibEncoder');

  /// Compile-time type declaration of [$ZLibEncoder]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ZLibEncoder]
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
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
        ]),
        BridgeTypeRef(AsyncTypes.streamTransformerBase, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
        ]),
        BridgeTypeRef(AsyncTypes.streamTransformer, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
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
              'gzip',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
            ),

            BridgeParameter(
              'level',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "ZLibOption.defaultLevel",
            ),

            BridgeParameter(
              'windowBits',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "ZLibOption.defaultWindowBits",
            ),

            BridgeParameter(
              'memLevel',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "ZLibOption.defaultMemLevel",
            ),

            BridgeParameter(
              'strategy',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "ZLibOption.strategyDefault",
            ),

            BridgeParameter(
              'dictionary',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'raw',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
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
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'bytes',
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
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.byteConversionSink, []),
          ),
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
    fields: {
      'gzip': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),

      'level': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),

      'memLevel': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),

      'strategy': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),

      'windowBits': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),

      'dictionary': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.list, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          ]),
          nullable: true,
        ),
        isStatic: false,
      ),

      'raw': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [ZLibEncoder.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;
    final _arg5OrNull = c is List && c.length > 3 ? c[3] as $Value? : null;
    final _arg6OrNull = c is List && c.length > 4 ? c[4] as $Value? : null;

    return $ZLibEncoder.wrap(
      ZLibEncoder(
        gzip: (r is $Value ? r : null) == null ? false : (r as $bool).$value,
        level: (s is $Value ? s : null) == null
            ? ZLibOption.defaultLevel
            : (s as $int).$value,
        windowBits: _arg2OrNull == null
            ? ZLibOption.defaultWindowBits
            : (_arg2OrNull as $int).$value,
        memLevel: _arg3OrNull == null
            ? ZLibOption.defaultMemLevel
            : (_arg3OrNull as $int).$value,
        strategy: _arg4OrNull == null
            ? ZLibOption.strategyDefault
            : (_arg4OrNull as $int).$value,
        dictionary: (TypedInterop.exportExternal(
          _arg5OrNull,
          runtime: runtime,
        ) as List?)?.cast<int>(),
        raw: _arg6OrNull == null ? false : (_arg6OrNull as $bool).$value,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final ZLibEncoder $value;

  @override
  ZLibEncoder get $reified => $value;

  /// Wrap a [ZLibEncoder] in a [$ZLibEncoder]
  $ZLibEncoder.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'gzip':
        final _gzip = $value.gzip;
        return $bool(_gzip);
      case 'level':
        final _level = $value.level;
        return $int(_level);
      case 'memLevel':
        final _memLevel = $value.memLevel;
        return $int(_memLevel);
      case 'strategy':
        final _strategy = $value.strategy;
        return $int(_strategy);
      case 'windowBits':
        final _windowBits = $value.windowBits;
        return $int(_windowBits);
      case 'dictionary':
        final _dictionary = $value.dictionary;
        return _dictionary == null
            ? const $null()
            : $List.view(
                _dictionary,
                (e) => $int(e),
                runtime: runtime,
                runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
                  runtime.lookupType(CoreTypes.int),
                ]),
              );
      case 'raw':
        final _raw = $value.raw;
        return $bool(_raw);
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
    final self = target! as $ZLibEncoder;
    final result = self.$value.bind((r as $Value?)!.$value);
    return $Stream.wrap(
      result.map(
        (e) => $List.view(
          e,
          (e) => $int(e),
          runtime: runtime,
          runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
            runtime.lookupType(CoreTypes.int),
          ]),
        ),
      ),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
        runtime.internParameterizedType(CoreTypes.list, [
          runtime.lookupType(CoreTypes.int),
        ]),
      ]),
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
    final self = target! as $ZLibEncoder;
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
    final self = target! as $ZLibEncoder;
    final result = self.$value.convert(
      (TypedInterop.exportExternal((r as $Value?), runtime: runtime) as List)
          .cast<int>(),
    );
    return $List.view(
      result,
      (e) => $int(e),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.lookupType(CoreTypes.int),
      ]),
    );
  }

  static const $Function __fuse = $Function(_fuse);
  static $Value? _fuse(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ZLibEncoder;
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
    final self = target! as $ZLibEncoder;
    final result = self.$value.startChunkedConversion((r as $Value?)!.$value);
    return $ByteConversionSink.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [ZLibDecoder]
class $ZLibDecoder implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'ZLibDecoder.',
      $ZLibDecoder.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$ZLibDecoder]
  static const $spec = BridgeTypeSpec('dart:io', 'ZLibDecoder');

  /// Compile-time type declaration of [$ZLibDecoder]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ZLibDecoder]
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
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
        ]),
        BridgeTypeRef(AsyncTypes.streamTransformerBase, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
        ]),
        BridgeTypeRef(AsyncTypes.streamTransformer, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
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
              'gzip',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
            ),

            BridgeParameter(
              'windowBits',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "ZLibOption.defaultWindowBits",
            ),

            BridgeParameter(
              'dictionary',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'raw',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
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
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'bytes',
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
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.byteConversionSink, []),
          ),
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
    fields: {
      'gzip': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),

      'windowBits': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),

      'dictionary': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.list, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          ]),
          nullable: true,
        ),
        isStatic: false,
      ),

      'raw': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [ZLibDecoder.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;

    return $ZLibDecoder.wrap(
      ZLibDecoder(
        gzip: (r is $Value ? r : null) == null ? false : (r as $bool).$value,
        windowBits: (s is $Value ? s : null) == null
            ? ZLibOption.defaultWindowBits
            : (s as $int).$value,
        dictionary: (TypedInterop.exportExternal(
          _arg2OrNull,
          runtime: runtime,
        ) as List?)?.cast<int>(),
        raw: _arg3OrNull == null ? false : (_arg3OrNull as $bool).$value,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final ZLibDecoder $value;

  @override
  ZLibDecoder get $reified => $value;

  /// Wrap a [ZLibDecoder] in a [$ZLibDecoder]
  $ZLibDecoder.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'gzip':
        final _gzip = $value.gzip;
        return $bool(_gzip);
      case 'windowBits':
        final _windowBits = $value.windowBits;
        return $int(_windowBits);
      case 'dictionary':
        final _dictionary = $value.dictionary;
        return _dictionary == null
            ? const $null()
            : $List.view(
                _dictionary,
                (e) => $int(e),
                runtime: runtime,
                runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
                  runtime.lookupType(CoreTypes.int),
                ]),
              );
      case 'raw':
        final _raw = $value.raw;
        return $bool(_raw);
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
    final self = target! as $ZLibDecoder;
    final result = self.$value.bind((r as $Value?)!.$value);
    return $Stream.wrap(
      result.map(
        (e) => $List.view(
          e,
          (e) => $int(e),
          runtime: runtime,
          runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
            runtime.lookupType(CoreTypes.int),
          ]),
        ),
      ),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
        runtime.internParameterizedType(CoreTypes.list, [
          runtime.lookupType(CoreTypes.int),
        ]),
      ]),
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
    final self = target! as $ZLibDecoder;
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
    final self = target! as $ZLibDecoder;
    final result = self.$value.convert(
      (TypedInterop.exportExternal((r as $Value?), runtime: runtime) as List)
          .cast<int>(),
    );
    return $List.view(
      result,
      (e) => $int(e),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.lookupType(CoreTypes.int),
      ]),
    );
  }

  static const $Function __fuse = $Function(_fuse);
  static $Value? _fuse(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ZLibDecoder;
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
    final self = target! as $ZLibDecoder;
    final result = self.$value.startChunkedConversion((r as $Value?)!.$value);
    return $ByteConversionSink.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
