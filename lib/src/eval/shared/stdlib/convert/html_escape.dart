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
        $AsciiCodec,
        $AsciiEncoder,
        $AsciiDecoder,
        $Utf8Decoder,
        $Utf8Codec,
        $Utf8Encoder,
        $Base64Encoder,
        $Base64Decoder,
        $Base64Codec,
        $ByteConversionSink,
        $ChunkedConversionSink,
        $HtmlEscapeMode,
        $HtmlEscape,
        $StringConversionSink,
        $ClosableStringSink,
        $LineSplitter;
import 'package:dart_eval/stdlib/async.dart'
    hide
        $Converter,
        $Codec,
        $Encoding,
        $JsonEncoder,
        $JsonDecoder,
        $JsonCodec,
        $AsciiCodec,
        $AsciiEncoder,
        $AsciiDecoder,
        $Utf8Decoder,
        $Utf8Codec,
        $Utf8Encoder,
        $Base64Encoder,
        $Base64Decoder,
        $Base64Codec,
        $ByteConversionSink,
        $ChunkedConversionSink,
        $HtmlEscapeMode,
        $HtmlEscape,
        $StringConversionSink,
        $ClosableStringSink,
        $LineSplitter;
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import './converter.dart';
import './string_conversion_sink.dart';

/// dart_eval wrapper binding for [HtmlEscapeMode]
class $HtmlEscapeMode implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'HtmlEscapeMode.',
      $HtmlEscapeMode.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'HtmlEscapeMode.unknown*g',
      $HtmlEscapeMode.$unknown,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'HtmlEscapeMode.attribute*g',
      $HtmlEscapeMode.$attribute,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'HtmlEscapeMode.sqAttribute*g',
      $HtmlEscapeMode.$sqAttribute,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'HtmlEscapeMode.element*g',
      $HtmlEscapeMode.$element,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$HtmlEscapeMode]
  static const $spec = BridgeTypeSpec('dart:convert', 'HtmlEscapeMode');

  /// Compile-time type declaration of [$HtmlEscapeMode]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$HtmlEscapeMode]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
              defaultValueSource: "\"custom\"",
            ),

            BridgeParameter(
              'escapeLtGt',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
            ),

            BridgeParameter(
              'escapeQuot',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
            ),

            BridgeParameter(
              'escapeApos',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
            ),

            BridgeParameter(
              'escapeSlash',
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

    methods: {},
    getters: {},
    setters: {},
    fields: {
      'escapeLtGt': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),

      'escapeQuot': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),

      'escapeApos': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),

      'escapeSlash': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),

      'unknown': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.htmlEscapeMode, [])),
        isStatic: true,
      ),

      'attribute': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.htmlEscapeMode, [])),
        isStatic: true,
      ),

      'sqAttribute': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.htmlEscapeMode, [])),
        isStatic: true,
      ),

      'element': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.htmlEscapeMode, [])),
        isStatic: true,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [HtmlEscapeMode.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;

    return $HtmlEscapeMode.wrap(
      HtmlEscapeMode(
        name: (r is $Value ? r : null) == null
            ? "custom"
            : (r as $String).$value,
        escapeLtGt: (s is $Value ? s : null) == null
            ? false
            : (s as $bool).$value,
        escapeQuot: _arg2OrNull == null ? false : (_arg2OrNull as $bool).$value,
        escapeApos: _arg3OrNull == null ? false : (_arg3OrNull as $bool).$value,
        escapeSlash: _arg4OrNull == null
            ? false
            : (_arg4OrNull as $bool).$value,
      ),
    );
  }

  /// Wrapper for the [HtmlEscapeMode.unknown] getter
  static $Value? $unknown(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = HtmlEscapeMode.unknown;
    return $HtmlEscapeMode.wrap(value);
  }

  /// Wrapper for the [HtmlEscapeMode.attribute] getter
  static $Value? $attribute(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = HtmlEscapeMode.attribute;
    return $HtmlEscapeMode.wrap(value);
  }

  /// Wrapper for the [HtmlEscapeMode.sqAttribute] getter
  static $Value? $sqAttribute(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HtmlEscapeMode.sqAttribute;
    return $HtmlEscapeMode.wrap(value);
  }

  /// Wrapper for the [HtmlEscapeMode.element] getter
  static $Value? $element(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = HtmlEscapeMode.element;
    return $HtmlEscapeMode.wrap(value);
  }

  final $Instance _superclass;

  @override
  final HtmlEscapeMode $value;

  @override
  HtmlEscapeMode get $reified => $value;

  /// Wrap a [HtmlEscapeMode] in a [$HtmlEscapeMode]
  $HtmlEscapeMode.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'escapeLtGt':
        final _escapeLtGt = $value.escapeLtGt;
        return $bool(_escapeLtGt);
      case 'escapeQuot':
        final _escapeQuot = $value.escapeQuot;
        return $bool(_escapeQuot);
      case 'escapeApos':
        final _escapeApos = $value.escapeApos;
        return $bool(_escapeApos);
      case 'escapeSlash':
        final _escapeSlash = $value.escapeSlash;
        return $bool(_escapeSlash);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [HtmlEscape]
class $HtmlEscape implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'HtmlEscape.',
      $HtmlEscape.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$HtmlEscape]
  static const $spec = BridgeTypeSpec('dart:convert', 'HtmlEscape');

  /// Compile-time type declaration of [$HtmlEscape]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$HtmlEscape]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(ConvertTypes.converter, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        ]),
        BridgeTypeRef(AsyncTypes.streamTransformerBase, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        ]),
        BridgeTypeRef(AsyncTypes.streamTransformer, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
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
              'mode',
              BridgeTypeAnnotation(
                BridgeTypeRef(ConvertTypes.htmlEscapeMode, []),
              ),
              true,
              defaultValueSource: "HtmlEscapeMode.unknown",
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
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'text',
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
            BridgeTypeRef(ConvertTypes.stringConversionSink, []),
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
      'mode': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.htmlEscapeMode, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [HtmlEscape.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $HtmlEscape.wrap(
      HtmlEscape(
        (r is $Value ? r : null) == null
            ? HtmlEscapeMode.unknown
            : (r is $Value ? r : null)!.$value,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final HtmlEscape $value;

  @override
  HtmlEscape get $reified => $value;

  /// Wrap a [HtmlEscape] in a [$HtmlEscape]
  $HtmlEscape.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'mode':
        final _mode = $value.mode;
        return $HtmlEscapeMode.wrap(_mode);
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
    final self = target! as $HtmlEscape;
    final result = self.$value.bind((r as $Value?)!.$value);
    return $Stream.wrap(
      result.map((e) => $String(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
        runtime.lookupType(CoreTypes.string),
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
    final self = target! as $HtmlEscape;
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
    final self = target! as $HtmlEscape;
    final result = self.$value.convert((r as $String).$value);
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
    final self = target! as $HtmlEscape;
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
    final self = target! as $HtmlEscape;
    final result = self.$value.startChunkedConversion((r as $Value?)!.$value);
    return $StringConversionSink.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
