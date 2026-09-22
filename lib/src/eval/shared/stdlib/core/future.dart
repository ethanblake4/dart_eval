// ignore_for_file: camel_case_types

import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop, WrappedException;
import 'package:dart_eval/src/eval/runtime/typed/typed_instance.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/stdlib/core.dart';

/// Wrapper for [Future]
class $Future<T> implements Future<T>, $Instance {
  /// Configure [$Future] for runtime in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Future.',
      _futureNew,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Future.delayed',
      _futureDelayed,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Future.value',
      _futureValue,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Future.error',
      _futureError,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Future.sync',
      _futureSync,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Future.microtask',
      _futureMicrotask,
    );
  }

  static const $declaration = BridgeClassDef(
    BridgeClassType(BridgeTypeRef(CoreTypes.future), isAbstract: true),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
          params: [
            BridgeParameter(
              'computation',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
          namedParams: [],
        ),
        isFactory: true,
      ),
      'delayed': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
          params: [
            BridgeParameter(
              'duration',
              BridgeTypeAnnotation($Duration.$type),
              false,
            ),
            BridgeParameter(
              'computation',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.function),
                nullable: true,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
      ),
      'value': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.dynamic),
                nullable: true,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
        isFactory: true,
      ),
      'error': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
          params: [
            BridgeParameter(
              'error',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)),
              false,
            ),
            BridgeParameter(
              'stackTrace',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.stackTrace),
                nullable: true,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
        isFactory: true,
      ),
      'sync': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
          params: [
            BridgeParameter(
              'computation',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
          namedParams: [],
        ),
        isFactory: true,
      ),
      'microtask': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
          params: [
            BridgeParameter(
              'computation',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
          namedParams: [],
        ),
        isFactory: true,
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
      'asStream': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream)),
          params: [],
          namedParams: [],
        ),
      ),
      'timeout': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
          params: [
            BridgeParameter(
              'timeLimit',
              BridgeTypeAnnotation($Duration.$type),
              false,
            ),
          ],
          namedParams: [
            BridgeParameter(
              'onTimeout',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.function),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),
      'whenComplete': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
          params: [
            BridgeParameter(
              'action',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
      'catchError': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
          params: [
            BridgeParameter(
              'onError',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
          namedParams: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.function),
                nullable: true,
              ),
              true,
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
        return $Closure(__then.func, this);
      case 'asStream':
        return $Closure(__asStream.func, this);
      case 'timeout':
        return $Closure(__timeout.func, this);
      case 'whenComplete':
        return $Closure(__whenComplete.func, this);
      case 'catchError':
        return $Closure(__catchError.func, this);
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

  static const $Function __asStream = $Function(_asStream);

  static $Value? _asStream(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $Stream.wrap((target as $Future).$value.asStream());
  }

  static const $Function __timeout = $Function(_timeout);

  static $Value? _timeout(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $t = target as $Future;
    final timeLimit = (r as $Value).$value as Duration;
    final onTimeout = s as EvalFunction?;
    FutureOr<dynamic> onTimeoutCb() =>
        onTimeout!.call(runtime, target, null, null, 0)?.$value;
    return $Future.wrap(
      $t.$value.timeout(
        timeLimit,
        onTimeout: onTimeout == null ? null : onTimeoutCb,
      ),
    );
  }

  static const $Function __whenComplete = $Function(_whenComplete);

  static $Value? _whenComplete(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final action = r as EvalFunction;
    return $Future.wrap(
      (target as $Future).$value.whenComplete(() {
        action.call(runtime, target, null, null, 0);
      }),
    );
  }

  static const $Function __catchError = $Function(_catchError);

  static $Value? _catchError(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $t = target as $Future;
    final onError = r as EvalFunction;
    final test = s as EvalFunction?;
    FutureOr<dynamic> onErrorCb(Object error, StackTrace stackTrace) =>
        onError
            .call(
              runtime,
              target,
              runtime.wrap(error),
              runtime.wrap(stackTrace),
              2,
            )
            ?.$value;
    bool testCb(Object error) =>
        test!.call(runtime, target, runtime.wrap(error), null, 1)?.$value
            as bool? ??
        false;
    return $Future.wrap(
      $t.$value.catchError(
        onErrorCb,
        test: test == null ? null : testCb,
      ),
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
  final computation = s as EvalFunction?;
  return $Future.wrap(
    Future.delayed(
      (r as $Value).$value,
      computation == null
          ? null
          : () => computation.call(runtime, null, null, null, 0)?.$value,
    ),
  );
}

/// Eval objects ([TypedInstance]) have no host value — the future completes
/// with the instance itself so `then` hands it back via [Runtime.wrap].
Object? _futureArg(Object? arg) =>
    arg is TypedInstance ? arg : (arg is $Value ? arg.$value : arg);

$Value? _futureValue(Runtime runtime, Object? r, Object? s, Object? c) {
  return $Future.wrap(Future.value(_futureArg(r)));
}

$Value? _futureError(Runtime runtime, Object? r, Object? s, Object? c) {
  final error = _futureArg(r);
  final stackTrace = _futureArg(s);
  return $Future.wrap(Future.error(error ?? Object(), stackTrace as StackTrace?));
}

// `Future(computation)` queues on the event loop (after microtasks), so it
// must not reuse the microtask/sync paths.
$Value? _futureNew(Runtime runtime, Object? r, Object? s, Object? c) {
  final computation = r as EvalFunction;
  return $Future.wrap(
    Future(() => computation.call(runtime, null, null, null, 0)?.$value),
  );
}

$Value? _futureSync(Runtime runtime, Object? r, Object? s, Object? c) {
  final computation = r as EvalFunction;
  return $Future.wrap(
    Future.sync(() => computation.call(runtime, null, null, null, 0)?.$value),
  );
}

$Value? _futureMicrotask(Runtime runtime, Object? r, Object? s, Object? c) {
  final computation = r as EvalFunction;
  return $Future.wrap(
    Future.microtask(() => computation.call(runtime, null, null, null, 0)?.$value),
  );
}
