import 'dart:async';
import 'dart:convert';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/object.dart';

/// dart_eval wrapper for [Converter].
class $Converter implements $Instance {
  /// Wrap a [Converter] in a [$Converter].
  $Converter.wrap(this.$value);

  /// Bridge type reference for [$Converter].
  static const $type =
      BridgeTypeRef(BridgeTypeSpec('dart:convert', 'Converter'));

  /// Bridge class definition for [$Converter].
  static const $declaration = BridgeClassDef(BridgeClassType($type),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation($type), params: [], namedParams: []))
      },
      methods: {
        'bind': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream)),
            params: [
              BridgeParameter('stream',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream)), false)
            ],
            namedParams: []))
      },
      getters: {
        'startChunkedConversion': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(AsyncTypes.streamSink)),
            params: [
              BridgeParameter(
                  'sink',
                  BridgeTypeAnnotation(BridgeTypeRef(AsyncTypes.streamSink)),
                  false)
            ],
            namedParams: []))
      },
      setters: {},
      fields: {},
      wrap: true);

  late final $Instance _superclass = $Object($value);

  @override
  final Converter $value;

  @override
  get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'startChunkedConversion':
        return __startChunkedConversion;
      case 'bind':
        return __bind;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  static const $Function __startChunkedConversion =
      $Function(_startChunkedConversion);

  static $Value _startChunkedConversion(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final sink = args[0]!.$value as StreamSink;
    return $StreamSink.wrap((target!.$value as Converter)
        .startChunkedConversion(sink) as StreamSink);
  }

  static const $Function __bind = $Function(_bind);

  static $Value _bind(Runtime runtime, $Value? target, List<$Value?> args) {
    final stream = args[0]!.$value as Stream;
    return $Stream.wrap((target!.$value as Converter).bind(stream));
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
