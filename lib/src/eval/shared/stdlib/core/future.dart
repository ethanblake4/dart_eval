import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'base.dart';
import 'duration.dart';

/// Wrapper for [Future]
class $Future<T> implements Future<T>, $Instance {
  static void configureForCompile(Compiler compiler) {
    compiler.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:core', 'Future.delayed', const _$Future_delayed());
  }

  static const _$type = BridgeTypeRef.spec(BridgeTypeSpec('dart:core', 'Future'));

  static const $declaration = BridgeClassDef(BridgeClassType(_$type, isAbstract: true),
      constructors: {
        'delayed': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(_$type),
            params: [BridgeParameter('duration', BridgeTypeAnnotation($Duration.$type), false)],
            namedParams: []))
      },
      methods: {
        'then': BridgeMethodDef(BridgeFunctionDef(returns: BridgeTypeAnnotation(_$type), params: [
          BridgeParameter('onValue', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.functionType)), false)
        ], namedParams: []))
      },
      getters: {},
      setters: {},
      fields: {},
      wrap: true);

  $Future.wrap(this.$value, this.$typeMapper) : _superclass = $Object($value);

  @override
  final Future<T> $value;

  final $Value? Function(T value) $typeMapper;

  @override
  Future<T> get $reified => $value;

  final $Instance _superclass;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'then':
        return __then;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {}

  @override
  int get $runtimeType => RuntimeTypes.futureType;

  @override
  Stream<T> asStream() => $value.asStream();

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) => $value.catchError(onError, test: test);

  static const $Function __then = $Function(_then);

  static $Value? _then(Runtime runtime, $Value? target, List<$Value?> args) {
    final $t = target as $Future;
    return $Future.wrap(
        ($t.$value).then((value) => (args[0] as EvalFunction)(runtime, target, [$t.$typeMapper(value)])),
        $t.$typeMapper);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) =>
      $value.then(onValue, onError: onError);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      $value.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) => $value.whenComplete(action);
}

class _$Future_delayed implements EvalCallable {
  const _$Future_delayed();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Future.wrap(Future.delayed(args[0]!.$value), (value) => $null());
  }
}
