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
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

/// dart_eval bridge binding for [ByteConversionSink]
class $ByteConversionSink$bridge extends ByteConversionSink
    with $Bridge<ByteConversionSink> {
  /// Forwarded constructor for [ByteConversionSink.new]
  $ByteConversionSink$bridge();

  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'ByteConversionSink.',
      $ByteConversionSink$bridge.$new,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'ByteConversionSink.withCallback',
      $ByteConversionSink$bridge.$withCallback,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'ByteConversionSink.from',
      $ByteConversionSink$bridge.$from,
      isBridge: true,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$ByteConversionSink$bridge]
  static const $spec = BridgeTypeSpec('dart:convert', 'ByteConversionSink');

  /// Compile-time type declaration of [$ByteConversionSink$bridge]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ByteConversionSink]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,
      isMixinClass: true,

      $implements: [
        BridgeTypeRef(ConvertTypes.chunkedConversionSink, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
        ]),
        BridgeTypeRef(CoreTypes.sink, [
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
                          BridgeTypeRef(CoreTypes.list, [
                            BridgeTypeAnnotation(
                              BridgeTypeRef(CoreTypes.int, []),
                            ),
                          ]),
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
              'chunk',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
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
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: false,
    bridge: true,
  );

  /// Proxy for the [ByteConversionSink.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $ByteConversionSink$bridge();
  }

  /// Wrapper for the [ByteConversionSink.withCallback] constructor
  static $Value? $withCallback(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = ByteConversionSink.withCallback(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "void Function(List<int>);export=true",
        (_callable) => (List<int> accumulated) {
          _callable.call(
            runtime,
            null,
            $List.view(
              accumulated,
              (e) => $int(e),
              runtime: runtime,
              runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
                runtime.lookupType(CoreTypes.int),
              ]),
            ),
            null,
            1,
          );
        },
      ),
    );
    return $ByteConversionSink.wrap(result);
  }

  /// Wrapper for the [ByteConversionSink.from] constructor
  static $Value? $from(Runtime runtime, Object? r, Object? s, Object? c) {
    final result = ByteConversionSink.from((r as $Value?)!.$value);
    return $ByteConversionSink.wrap(result);
  }

  @override
  $Value? $bridgeGet(String identifier) {
    final runtime = $runtime;
    switch (identifier) {
      case 'addSlice':
        return $Function((runtime, target, r, s, c) {
          super.addSlice(
            (TypedInterop.exportExternal(
              (r as $Value?),
              runtime: runtime,
            ) as List).cast(),
            (s as $int).$value,
            ((c as List)[0] as $int).$value,
            ((c as List)[1] as $bool).$value,
          );
          return null;
        });
    }
    return null;
  }

  @override
  void $bridgeSet(String identifier, $Value value) {}

  @override
  void add(List<int> chunk) {
    final runtime = $runtime;
    $_invoke('add', [
      TypedInterop.boxExternal(
        chunk,
        runtime: runtime,
        runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
          runtime.lookupType(CoreTypes.int),
        ]),
      )!,
    ]);
  }

  @override
  void close() {
    final runtime = $runtime;
    $_invoke('close', []);
  }

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    final runtime = $runtime;
    $_invoke('addSlice', [
      TypedInterop.boxExternal(
        chunk,
        runtime: runtime,
        runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
          runtime.lookupType(CoreTypes.int),
        ]),
      )!,
      $int(start),
      $int(end),
      $bool(isLast),
    ]);
  }
}

/// dart_eval lightweight wrapper binding for [ByteConversionSink]
class $ByteConversionSink implements $Instance {
  /// Compile-time type specification of [$ByteConversionSink]
  static const $spec = BridgeTypeSpec('dart:convert', 'ByteConversionSink');

  /// Compile-time type declaration of [$ByteConversionSink]
  static const $type = BridgeTypeRef($spec);

  final $Instance _superclass;

  @override
  final ByteConversionSink $value;

  @override
  ByteConversionSink get $reified => $value;

  /// Wrap a [ByteConversionSink] in a [$ByteConversionSink]
  $ByteConversionSink.wrap(this.$value) : _superclass = $Object($value);

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
    final self = target! as $ByteConversionSink;
    self.$value.add(
      (TypedInterop.exportExternal((r as $Value?), runtime: runtime) as List)
          .cast<int>(),
    );
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
    final self = target! as $ByteConversionSink;
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
    final self = target! as $ByteConversionSink;
    self.$value.addSlice(
      (TypedInterop.exportExternal((r as $Value?), runtime: runtime) as List)
          .cast<int>(),
      (s as $int).$value,
      ((c as List)[0] as $int).$value,
      ((c as List)[1] as $bool).$value,
    );
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
