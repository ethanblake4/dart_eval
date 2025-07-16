// ignore_for_file: unused_import
// ignore_for_file: unnecessary_import
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'dart:typed_data';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper binding for [ByteConversionSink]
class $ByteConversionSink implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:convert',
        'ByteConversionSink.withCallback', $ByteConversionSink.$withCallback);

    runtime.registerBridgeFunc(
        'dart:convert', 'ByteConversionSink.from', $ByteConversionSink.$from);
  }

  /// Compile-time type specification of [$ByteConversionSink]
  static const $spec = ConvertTypes.byteConversionSink;

  /// Compile-time type declaration of [$ByteConversionSink]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ByteConversionSink]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,
      $implements: [
        BridgeTypeRef(ConvertTypes.chunkedConversionSink, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
              [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))]))
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
      'from': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'sink',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.sink)),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
    },
    methods: {
      'addSlice': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'chunk',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list)),
              false,
            ),
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'end',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'isLast',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
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
  );

  /// Wrapper for the [ByteConversionSink.withCallback] constructor
  static $Value? $withCallback(
      Runtime runtime, $Value? thisValue, List<$Value?> args) {
    return $ByteConversionSink.wrap(
      ByteConversionSink.withCallback((accumulated) {
        (args[0] as EvalCallable)(
            runtime, null, [$List.view(accumulated, (e) => $int(e))])?.$value;
      }),
    );
  }

  /// Wrapper for the [ByteConversionSink.from] constructor
  static $Value? $from(Runtime runtime, $Value? thisValue, List<$Value?> args) {
    return $ByteConversionSink.wrap(
      ByteConversionSink.from(args[0]!.$value),
    );
  }

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
      case 'addSlice':
        return __addSlice;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __addSlice = $Function(_addSlice);
  static $Value? _addSlice(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteConversionSink;
    self.$value.addSlice((args[0]!.$reified as List).cast(), args[1]!.$value,
        args[2]!.$value, args[3]!.$value);
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
