import 'dart:io';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/string_sink.dart';

/// dart_eval wrapper for [IOSink]
class $IOSink implements $Instance {
  $IOSink.wrap(this.$value);

  /// Compile-time bridged type reference for [$IOSink]
  static const $type = BridgeTypeRef(IoTypes.ioSink);

  /// Compile-time bridged class declaration for [$IOSink]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type, isAbstract: true, $implements: [
        $StringSink.$type,
        BridgeTypeRef(AsyncTypes.streamSink, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
              [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))]))
        ])
      ]),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation($type), params: [], namedParams: []))
      },
      methods: {},
      getters: {},
      setters: {},
      fields: {},
      wrap: true);

  late final $Instance _stringSink = $StringSink.wrap($value);

  late final $Instance _streamSink = $StreamSink.wrap($value);

  @override
  final IOSink $value;

  @override
  get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'close':
      case 'done':
        return _streamSink.$getProperty(runtime, identifier);
    }
    return _stringSink.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _stringSink.$setProperty(runtime, identifier, value);
  }
}
