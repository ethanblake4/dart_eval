// ignore_for_file: unused_import
// ignore_for_file: unnecessary_import
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'chunked_conversion.dart';
import 'dart:async';
import 'dart:convert';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper binding for [ChunkedConversionSink]
class $ChunkedConversionSink implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        'dart:convert',
        'ChunkedConversionSink.withCallback',
        $ChunkedConversionSink.$withCallback);
  }

  /// Compile-time type specification of [$ChunkedConversionSink]
  static const $spec = ConvertTypes.chunkedConversionSink;

  /// Compile-time type declaration of [$ChunkedConversionSink]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ChunkedConversionSink]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,
      generics: {'T': BridgeGenericParam()},
      $implements: [BridgeTypeRef(CoreTypes.sink)],
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
                  BridgeTypeRef.genericFunction(BridgeFunctionDef(
                returns:
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
                params: [
                  BridgeParameter(
                    'accumulated',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list)),
                    false,
                  ),
                ],
                namedParams: [],
              ))),
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
  );

  /// Wrapper for the [ChunkedConversionSink.withCallback] constructor
  static $Value? $withCallback(
      Runtime runtime, $Value? thisValue, List<$Value?> args) {
    return $ChunkedConversionSink.wrap(
      ChunkedConversionSink.withCallback((v0) {
        (args[0] as EvalCallable)(
                runtime, null, [$List.view(v0, (e) => runtime.wrapAlways(e))])
            ?.$value;
      }),
    );
  }

  final $Instance _superclass;

  @override
  final ChunkedConversionSink $value;

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
  static $Value? _add(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ChunkedConversionSink;
    self.$value.add(args[0]!.$value);
    return null;
  }

  static const $Function __close = $Function(_close);
  static $Value? _close(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ChunkedConversionSink;
    self.$value.close();
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
