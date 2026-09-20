// ignore_for_file: camel_case_types

import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop, WrappedException;
import 'package:dart_eval/stdlib/core.dart';

/// Wrapper for [Future]
class $Future<T> implements Future<T>, $Instance {
  /// Configure [$Future] for runtime in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Future.delayed',
      _futureDelayed,
    );
  }

  static const $declaration = BridgeClassDef(
    BridgeClassType(BridgeTypeRef(CoreTypes.future), isAbstract: true),
    constructors: {
      'delayed': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
          params: [
            BridgeParameter(
              'duration',
              BridgeTypeAnnotation($Duration.$type),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
    },
    methods: {
      'then': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
          params: [
            BridgeParameter(
              'onValue',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
  );

  $Future.wrap(this.$value, {this.runtimeTypeId, this.runtime})
    : _superclass = $Object($value);

  @override
  final Future<T> $value;
  final int? runtimeTypeId;
  final Runtime? runtime;

  @override
  Future get $reified =>
      $value.then((value) => value is $Value ? value.$value : value);

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
  int $getRuntimeType(Runtime runtime) => runtimeTypeId == null
      ? runtime.lookupType(CoreTypes.future)
      : runtime.importRuntimeType(this.runtime ?? runtime, runtimeTypeId!);

  @override
  Stream<T> asStream() => $value.asStream();

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      $value.catchError(onError, test: test);

  static const $Function __then = $Function(_then);

  static $Value? _then(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $t = target as $Future;
    final $then = (r as $Value?) as EvalFunction;
    final runtimeTypeId = runtime.typedFutureTypeForCallback($then);
    final $result = ($t.$value).then((value) {
      try {
        return $then.call(runtime, target, runtime.wrap(value), null, 1);
      } on WrappedException catch (error, trace) {
        Error.throwWithStackTrace(error.exception, trace);
      }
    });
    return $Future.wrap(
      $result,
      runtimeTypeId: runtimeTypeId,
      runtime: runtime,
    );
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) => $value.then(onValue, onError: onError);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      $value.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      $value.whenComplete(action);
}

$Value? _futureDelayed(Runtime runtime, Object? r, Object? s, Object? c) {
  return $Future.wrap(Future.delayed((r as $Value).$value));
}
