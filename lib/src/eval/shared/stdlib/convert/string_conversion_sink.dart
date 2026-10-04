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

import './byte_conversion.dart';
import '../core/string_sink.dart';

/// dart_eval bridge binding for [StringConversionSink]
class $StringConversionSink$bridge extends StringConversionSink
    with $Bridge<StringConversionSink> {
  /// Forwarded constructor for [StringConversionSink.new]
  $StringConversionSink$bridge();

  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'StringConversionSink.',
      $StringConversionSink$bridge.$new,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'StringConversionSink.withCallback',
      $StringConversionSink$bridge.$withCallback,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'StringConversionSink.from',
      $StringConversionSink$bridge.$from,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'StringConversionSink.fromStringSink',
      $StringConversionSink$bridge.$fromStringSink,
      isBridge: true,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$StringConversionSink$bridge]
  static const $spec = BridgeTypeSpec('dart:convert', 'StringConversionSink');

  /// Compile-time type declaration of [$StringConversionSink$bridge]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$StringConversionSink]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,
      isMixinClass: true,

      $implements: [
        BridgeTypeRef(ConvertTypes.chunkedConversionSink, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        ]),
        BridgeTypeRef(CoreTypes.sink, [
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

      'withCallback': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'callback',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'accumulated',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.string, []),
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
        isFactory: true,
      ),

      'from': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
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
        isFactory: true,
      ),

      'fromStringSink': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'sink',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stringSink, [])),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'add': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'str',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
      ),

      'close': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'addSlice': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'chunk',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'isLast',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'asUtf8Sink': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.byteConversionSink, []),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'allowMalformed',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              false,
            ),
          ],
        ),
      ),

      'asStringSink': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(ConvertTypes.closableStringSink, []),
          ),
          namedParams: [],
          params: [],
        ),
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: false,
    bridge: true,
  );

  /// Proxy for the [StringConversionSink.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $StringConversionSink$bridge();
  }

  /// Wrapper for the [StringConversionSink.withCallback] constructor
  static $Value? $withCallback(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = StringConversionSink.withCallback(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "void Function(String);export=true",
        (_callable) => (String accumulated) {
          _callable.call(runtime, null, $String(accumulated), null, 1);
        },
      ),
    );
    return $StringConversionSink.wrap(result);
  }

  /// Wrapper for the [StringConversionSink.from] constructor
  static $Value? $from(Runtime runtime, Object? r, Object? s, Object? c) {
    final result = StringConversionSink.from((r as $Value?)!.$value);
    return $StringConversionSink.wrap(result);
  }

  /// Wrapper for the [StringConversionSink.fromStringSink] constructor
  static $Value? $fromStringSink(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = StringConversionSink.fromStringSink((r as $Value?)!.$value);
    return $StringConversionSink.wrap(result);
  }

  @override
  $Value? $bridgeGet(String identifier) {
    final runtime = $runtime;
    switch (identifier) {
      case 'add':
        return $Function((runtime, target, r, s, c) {
          super.add((r as $String).$value);
          return null;
        });
      case 'asUtf8Sink':
        return $Function((runtime, target, r, s, c) {
          final result = super.asUtf8Sink((r as $bool).$value);
          return $ByteConversionSink.wrap(result);
        });
      case 'asStringSink':
        return $Function((runtime, target, r, s, c) {
          final result = super.asStringSink();
          return $ClosableStringSink.wrap(result);
        });
    }
    return null;
  }

  @override
  void $bridgeSet(String identifier, $Value value) {}

  @override
  void add(String str) {
    final runtime = $runtime;
    $_invoke('add', [$String(str)]);
  }

  @override
  void close() {
    final runtime = $runtime;
    $_invoke('close', []);
  }

  @override
  void addSlice(String chunk, int start, int end, bool isLast) {
    final runtime = $runtime;
    $_invoke('addSlice', [
      $String(chunk),
      $int(start),
      $int(end),
      $bool(isLast),
    ]);
  }

  @override
  ByteConversionSink asUtf8Sink(bool allowMalformed) {
    final runtime = $runtime;
    return $_invoke('asUtf8Sink', [$bool(allowMalformed)]);
  }

  @override
  ClosableStringSink asStringSink() {
    final runtime = $runtime;
    return $_invoke('asStringSink', []);
  }
}

/// dart_eval lightweight wrapper binding for [StringConversionSink]
class $StringConversionSink implements $Instance {
  /// Compile-time type specification of [$StringConversionSink]
  static const $spec = BridgeTypeSpec('dart:convert', 'StringConversionSink');

  /// Compile-time type declaration of [$StringConversionSink]
  static const $type = BridgeTypeRef($spec);

  final $Instance _superclass;

  @override
  final StringConversionSink $value;

  @override
  StringConversionSink get $reified => $value;

  /// Wrap a [StringConversionSink] in a [$StringConversionSink]
  $StringConversionSink.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'add':
        return $Closure(__add.func, this);

      case 'close':
        return $Closure(__close.func, this);

      case 'addSlice':
        return $Closure(__addSlice.func, this);

      case 'asUtf8Sink':
        return $Closure(__asUtf8Sink.func, this);

      case 'asStringSink':
        return $Closure(__asStringSink.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __add = $Function(_add);
  static $Value? _add(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringConversionSink;
    self.$value.add((r as $String).$value);
    return null;
  }

  static const $Function __close = $Function(_close);
  static $Value? _close(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringConversionSink;
    self.$value.close();
    return null;
  }

  static const $Function __addSlice = $Function(_addSlice);
  static $Value? _addSlice(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringConversionSink;
    self.$value.addSlice(
      (r as $String).$value,
      (s as $int).$value,
      ((c as List)[0] as $int).$value,
      ((c as List)[1] as $bool).$value,
    );
    return null;
  }

  static const $Function __asUtf8Sink = $Function(_asUtf8Sink);
  static $Value? _asUtf8Sink(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringConversionSink;
    final result = self.$value.asUtf8Sink((r as $bool).$value);
    return $ByteConversionSink.wrap(result);
  }

  static const $Function __asStringSink = $Function(_asStringSink);
  static $Value? _asStringSink(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringConversionSink;
    final result = self.$value.asStringSink();
    return $ClosableStringSink.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [ClosableStringSink]
class $ClosableStringSink implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'ClosableStringSink.fromStringSink',
      $ClosableStringSink.$fromStringSink,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$ClosableStringSink]
  static const $spec = BridgeTypeSpec('dart:convert', 'ClosableStringSink');

  /// Compile-time type declaration of [$ClosableStringSink]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ClosableStringSink]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      $implements: [BridgeTypeRef(CoreTypes.stringSink, [])],
    ),
    constructors: {
      'fromStringSink': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'sink',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stringSink, [])),
              false,
            ),

            BridgeParameter(
              'onClose',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'close': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [ClosableStringSink.fromStringSink] constructor
  static $Value? $fromStringSink(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $ClosableStringSink.wrap(
      ClosableStringSink.fromStringSink(
        (r as $Value?)!.$value,
        runtime.cachedCallback(
          (s as $Value?)! as EvalCallable,
          "void Function();export=false",
          (_callable) => () {
            _callable.call(runtime, null, null, null, 0);
          },
        ),
      ),
    );
  }

  final $Instance _superclass;

  @override
  final ClosableStringSink $value;

  @override
  ClosableStringSink get $reified => $value;

  /// Wrap a [ClosableStringSink] in a [$ClosableStringSink]
  $ClosableStringSink.wrap(this.$value)
    : _superclass = $StringSink.wrap($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'close':
        return $Closure(__close.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __close = $Function(_close);
  static $Value? _close(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ClosableStringSink;
    self.$value.close();
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
