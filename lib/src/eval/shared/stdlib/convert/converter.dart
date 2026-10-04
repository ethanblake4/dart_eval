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
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

import '../core/sink.dart';

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

/// dart_eval bridge binding for [Converter]
class $Converter$bridge<S, T> extends Converter<S, T>
    with $Bridge<Converter<S, T>> {
  /// Forwarded constructor for [Converter.new]
  $Converter$bridge();

  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'Converter.',
      $Converter$bridge.$new,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'Converter.castFrom',
      $Converter$bridge.$castFrom,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Converter$bridge]
  static const $spec = BridgeTypeSpec('dart:convert', 'Converter');

  /// Compile-time type declaration of [$Converter$bridge]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Converter]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,
      isMixinClass: true,

      generics: {'S': BridgeGenericParam(), 'T': BridgeGenericParam()},

      $implements: [
        BridgeTypeRef(AsyncTypes.streamTransformerBase, [
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

        isAbstract: true,
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
    wrap: false,
    bridge: true,
  );

  /// Proxy for the [Converter.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Converter$bridge();
  }

  /// Wrapper for the [Converter.castFrom] method
  static $Value? $castFrom(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Converter.castFrom((r as $Value?)!.$value);
    return $Converter.wrap(value);
  }

  @override
  $Value? $bridgeGet(String identifier) {
    final runtime = $runtime;
    switch (identifier) {
      case 'bind':
        return $Function((runtime, target, r, s, c) {
          final result = super.bind((r as $Value?)!.$value);
          return $Stream.wrap(
            result.map(
              (e) => (e is List || e is Map || e is Set
                  ? TypedInterop.boxExternal(e, runtime: runtime)!
                  : runtime.wrapAlways(e)),
            ),
            runtime: runtime,
            runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
              runtime.runtimeTypeArgumentAt(
                    Runtime.bridgeData[this]!.$runtimeType,
                    1,
                  ) ??
                  runtime.lookupType(CoreTypes.dynamic),
            ]),
          );
        });
      case 'cast':
        return $Function((runtime, target, r, s, c) {
          final result = super.cast();
          return $Converter.wrap(result);
        });
      case 'fuse':
        return $Function((runtime, target, r, s, c) {
          final result = super.fuse((r as $Value?)!.$value);
          return $Converter.wrap(result);
        });
      case 'startChunkedConversion':
        return $Function((runtime, target, r, s, c) {
          final result = super.startChunkedConversion(
            TypedInterop.exportSink<T>(
              (r as $Value?),
              runtime,
              runtime.internParameterizedType(CoreTypes.sink, [
                runtime.runtimeTypeArgumentAt(
                      Runtime.bridgeData[this]!.$runtimeType,
                      1,
                    ) ??
                    runtime.lookupType(CoreTypes.dynamic),
              ]),
            ),
          );
          return $Sink.wrap(result);
        });
    }
    return $bridgeGetObject(
      identifier,
      hashCode: () => super.hashCode,
      equals: (other) => super == other,
      toString: () => super.toString(),
    );
  }

  @override
  void $bridgeSet(String identifier, $Value value) {}

  @override
  Stream<T> bind(Stream<S> stream) {
    final runtime = $runtime;
    return $_invoke('bind', [
      $Stream.wrap(stream.map((e) => runtime.wrapAlways(e, recursive: true))),
    ]);
  }

  @override
  Converter<RS, RT> cast<RS, RT>() {
    final runtime = $runtime;
    return $_invoke('cast', []);
  }

  @override
  T convert(S input) {
    final runtime = $runtime;
    return $_invoke('convert', [
      (input is List || input is Map || input is Set
          ? TypedInterop.boxExternal(input, runtime: runtime)!
          : runtime.wrapAlways(input)),
    ]);
  }

  @override
  Converter<S, TT> fuse<TT>(Converter<T, TT> other) {
    final runtime = $runtime;
    return $_invoke('fuse', [$Converter.wrap(other)]);
  }

  @override
  Sink<S> startChunkedConversion(Sink<T> sink) {
    final runtime = $runtime;
    return $_invoke('startChunkedConversion', [$Sink.wrap(sink)]);
  }
}

/// dart_eval lightweight wrapper binding for [Converter]
class $Converter<S, T> implements $Instance {
  /// Compile-time type specification of [$Converter]
  static const $spec = BridgeTypeSpec('dart:convert', 'Converter');

  /// Compile-time type declaration of [$Converter]
  static const $type = BridgeTypeRef($spec);

  final $Instance _superclass;

  @override
  final Converter<S, T> $value;

  @override
  Converter<S, T> get $reified => $value;

  /// Wrap a [Converter] in a [$Converter]
  $Converter.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) {
    final data = Runtime.bridgeData[this];
    return data == null
        ? runtime.lookupType($spec)
        : runtime.importRuntimeType(data.runtime, data.$runtimeType);
  }

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
    final self = target! as $Converter;
    final result = self.$value.bind((r as $Value?)!.$value);
    return $Stream.wrap(
      result.map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
        runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 1) ??
            runtime.lookupType(CoreTypes.dynamic),
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
    final result = self.$value.convert(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as dynamic,
    );
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
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
    final result = self.$value.startChunkedConversion(
      TypedInterop.exportSink<dynamic>(
        (r as $Value?),
        runtime,
        runtime.internParameterizedType(CoreTypes.sink, [
          runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 1) ??
              runtime.lookupType(CoreTypes.dynamic),
        ]),
      ),
    );
    return $Sink.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
