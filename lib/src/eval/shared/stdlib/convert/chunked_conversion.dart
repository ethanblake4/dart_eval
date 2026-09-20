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

/// dart_eval wrapper binding for [ChunkedConversionSink]
class $ChunkedConversionSink<T> implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'ChunkedConversionSink.withCallback',
      $ChunkedConversionSink.$withCallback,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$ChunkedConversionSink]
  static const $spec = BridgeTypeSpec('dart:convert', 'ChunkedConversionSink');

  /// Compile-time type declaration of [$ChunkedConversionSink]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ChunkedConversionSink]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      generics: {'T': BridgeGenericParam()},

      $implements: [
        BridgeTypeRef(CoreTypes.sink, [
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
                            BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
    },

    methods: {
      'add': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'chunk',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [ChunkedConversionSink.withCallback] constructor
  static $Value? $withCallback(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $ChunkedConversionSink.wrap(
      ChunkedConversionSink.withCallback((List<dynamic> accumulated) {
        ((r as $Value?)! as EvalCallable)(
          runtime,
          null,
          $List.view(
            accumulated,
            (e) => runtime.wrapAlways(e, recursive: true),
          ),
          null,
          1,
        );
      }),
    );
  }

  final $Instance _superclass;

  @override
  final ChunkedConversionSink<T> $value;

  @override
  ChunkedConversionSink get $reified => $value;

  /// Wrap a [ChunkedConversionSink] in a [$ChunkedConversionSink]
  $ChunkedConversionSink.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'add':
        return __add;

      case 'close':
        return __close;
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
    final self = target! as $ChunkedConversionSink;
    self.$value.add((r as $Value?)!.$value);
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
    final self = target! as $ChunkedConversionSink;
    self.$value.close();
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
