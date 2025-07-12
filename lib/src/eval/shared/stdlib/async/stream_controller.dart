import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [StreamController]
class $StreamController implements $Instance {
  /// Wrap a [StreamController] in a [$StreamController]
  $StreamController.wrap(this.$value);

  /// Compile-time bridged type reference for [$StreamController]
  static const $type =
      BridgeTypeRef(BridgeTypeSpec('dart:async', 'StreamController'));

  /// Compile-time bridged class declaration for [$StreamController]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type, isAbstract: true, generics: {
        'T': BridgeGenericParam()
      }, $implements: [
        BridgeTypeRef(AsyncTypes.streamSink,
            [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])
      ]),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type)))
      },
      methods: {
        'add': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [
              BridgeParameter(
                  'event', BridgeTypeAnnotation(BridgeTypeRef.ref('T')), false)
            ])),
        'addError': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)))),
        'close': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)))),
      },
      getters: {
        'done': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)))),
        'sink': BridgeMethodDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef(AsyncTypes.streamSink)))),
        'stream': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])))),
      },
      setters: {},
      fields: {},
      wrap: true);

  late final $Instance _superclass = $Object($value);

  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $StreamController.wrap(StreamController());
  }

  @override
  final StreamController $value;

  @override
  StreamController get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'add':
        return __add;
      case 'addError':
        return __addError;
      case 'close':
        return __close;
      case 'done':
        return $Future.wrap($value.done);
      case 'sink':
        return $StreamSink.wrap($value.sink);
      case 'stream':
        return $Stream.wrap($value.stream);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __add = $Function(_add);

  static $Value? _add(Runtime runtime, $Value? target, List<$Value?> args) {
    final $StreamController $target = target as $StreamController;
    final $Value $event = args[0]!;
    $target.$value.add($event.$value);
    return $null();
  }

  static const $Function __addError = $Function(_addError);

  static $Value? _addError(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $StreamController $target = target as $StreamController;
    final $Value $event = args[0]!;
    final $Value? $stackTrace = args[1];
    $target.$value.addError($event.$value, $stackTrace?.$value as StackTrace?);
    return $null();
  }

  static const $Function __close = $Function(_close);

  static $Value? _close(Runtime runtime, $Value? target, List<$Value?> args) {
    final $StreamController $target = target as $StreamController;
    return $Future.wrap($target.$value.close());
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
