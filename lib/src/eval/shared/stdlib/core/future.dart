// ignore_for_file: camel_case_types

import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop, WrappedException;
import 'package:dart_eval/src/eval/runtime/typed/typed_async.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_closure.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_exception_state.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_instance.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/stdlib/core.dart';

/// Wrapper for [Future]
class $Future<T> implements Future<T>, $Instance {
  /// Configure [$Future] for runtime in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:core', 'Future.', _futureNew);
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
    BridgeClassType(
      BridgeTypeRef(CoreTypes.future),
      isAbstract: true,
      generics: {'T': BridgeGenericParam()},
    ),
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
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(
                // FutureOr<T> is a union; constructor inference resolves T.
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
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
            ]),
          ),
          params: [
            BridgeParameter(
              'onValue',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(AsyncTypes.futureOr, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                      ]),
                    ),
                    params: [
                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                        false,
                      ),
                    ],
                  ),
                ),
              ),
              false,
            ),
          ],
          namedParams: [
            BridgeParameter(
              'onError',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.function),
                nullable: true,
              ),
              true,
            ),
          ],
          generics: {'S': BridgeGenericParam()},
        ),
      ),
      'asStream': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [],
          namedParams: [],
        ),
      ),
      'timeout': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
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
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(AsyncTypes.futureOr, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                      ]),
                    ),
                    params: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),
      'whenComplete': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'action',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(AsyncTypes.futureOr, [
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
                      ]),
                    ),
                    params: [],
                  ),
                ),
              ),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
      'catchError': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
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
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool),
                    ),
                    params: [
                      BridgeParameter(
                        'error',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)),
                        false,
                      ),
                    ],
                  ),
                ),
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
  int $getRuntimeType(Runtime runtime) {
    // Instances created inside the VM carry their instantiated type
    // (`Future<int>`) in bridgeData — the wrapper itself is erased.
    final data = Runtime.bridgeData[this];
    if (data != null) {
      return runtime.importRuntimeType(data.runtime, data.$runtimeType);
    }
    return runtimeTypeId == null
        ? runtime.lookupType(CoreTypes.future)
        : runtime.importRuntimeType(this.runtime ?? runtime, runtimeTypeId!);
  }

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
    final onError = s as EvalFunction?;
    final runtimeTypeId = runtime.typedFutureTypeForCallback($then);
    FutureOr<$Value?> onErrorCb(Object error, StackTrace stackTrace) {
      final handler = onError!;
      final twoArgs =
          handler is TypedClosure && handler.descriptor.accepts(2, const []);
      return handler.call(
        runtime,
        target,
        TypedExceptionState.boxException(error, runtime),
        twoArgs ? $StackTrace.wrap(stackTrace) : null,
        twoArgs ? 2 : 1,
      );
    }

    // A bridge callback can return either a boxed value or a Future of boxed
    // values. Inferring $Value? here treats $Future<Object?> as a plain value
    // instead of adopting it, because it is not a Future<$Value?>.
    final $result = ($t.$value).then<Object?>((value) {
      try {
        final unwrapped = unwrapGuestFuturePayload(value);
        return $then.call(
          runtime,
          target,
          unwrapped is $Value ? unwrapped : runtime.wrap(unwrapped),
          null,
          1,
        );
      } on WrappedException catch (error, trace) {
        Error.throwWithStackTrace(error.exception, trace);
      }
    }, onError: onError == null ? null : onErrorCb);
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
    final $t = target as $Future;
    final t = runtime.runtimeTypeArgumentAt($t.$getRuntimeType(runtime), 0);
    return $Stream.wrap(
      $t.$value.asStream(),
      runtime: runtime,
      runtimeTypeId: t == null
          ? null
          : runtime.internParameterizedType(CoreTypes.stream, [t]),
    );
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
    FutureOr<Object?> onTimeoutCb() =>
        _futureArg(runtime, onTimeout!.call(runtime, target, null, null, 0));
    // Host futures may hold boxed $Value payloads. Widen before a recovery
    // callback returns an exported value such as a native collection view.
    return $Future.wrap(
      $t.$value
          .then<Object?>((value) => value)
          .timeout(
            timeLimit,
            onTimeout: onTimeout == null ? null : onTimeoutCb,
          ),
      runtime: runtime,
      runtimeTypeId: $t.$getRuntimeType(runtime),
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
    FutureOr<Object?> complete() => action.call(runtime, target, null, null, 0);
    final $t = target as $Future;
    return $Future<Object?>.wrap(
      $t.$value.whenComplete(complete),
      runtime: runtime,
      runtimeTypeId: $t.$getRuntimeType(runtime),
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
    FutureOr<Object?> onErrorCb(Object error, StackTrace stackTrace) {
      final twoArgs =
          onError is TypedClosure && onError.descriptor.accepts(2, const []);
      return _futureArg(
        runtime,
        onError.call(
          runtime,
          target,
          TypedExceptionState.boxException(error, runtime),
          twoArgs ? $StackTrace.wrap(stackTrace) : null,
          twoArgs ? 2 : 1,
        ),
      );
    }

    bool testCb(Object error) =>
        test!
                .call(
                  runtime,
                  target,
                  TypedExceptionState.boxException(error, runtime),
                  null,
                  1,
                )
                ?.$value
            as bool? ??
        false;
    return $Future.wrap(
      $t.$value
          .then<Object?>((value) => value)
          .catchError(onErrorCb, test: test == null ? null : testCb),
      runtime: runtime,
      runtimeTypeId: $t.$getRuntimeType(runtime),
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
  final resultType = runtime.bridgeConstructorTypeId ??
      (computation == null ? null : runtime.typedFutureTypeForCallback(computation));
  return $Future.wrap(
    Future.delayed(
      (r as $Value).$value,
      computation == null
          ? null
          : () => _futureCompletionArg(
              runtime,
              computation.call(runtime, null, null, null, 0),
              resultType,
            ),
    ),
    runtime: runtime,
    runtimeTypeId: resultType,
  );
}

/// Keep guest instance identity and export collections through their lazy
/// boundary views rather than exposing maps with boxed keys to host Dart.
Object? _futureArg(Runtime runtime, Object? arg) => arg is TypedInstance
    ? arg
    : TypedInterop.exportExternal(arg, runtime: runtime);

Object? _futureCompletionArg(Runtime runtime, Object? arg, int? resultType) {
  // A nested Future payload must survive the erased host Future boundary.
  if (arg is $Future && resultType != null &&
      !runtime.isTypedValueType(arg, resultType)) {
    return GuestFuturePayload(arg);
  }
  return _futureArg(runtime, arg);
}

$Value? _futureValue(Runtime runtime, Object? r, Object? s, Object? c) {
  final argType = r is $Value
      ? r.$getRuntimeType(runtime)
      : runtime.lookupType(CoreTypes.nullType);
  final argument = runtime.descriptorFor(argType);
  final resultType =
      runtime.bridgeConstructorTypeId ??
      runtime.internParameterizedType(CoreTypes.future, [
        r is $Future && argument.length > 2 ? argument[2] : argType,
      ]);
  return $Future.wrap(
    Future.value(_futureCompletionArg(runtime, r, resultType)),
    runtime: runtime,
    runtimeTypeId: resultType,
  );
}

$Value? _futureError(Runtime runtime, Object? r, Object? s, Object? c) {
  // Keep guest error values boxed — a reified `$Exception` loses its
  // wrapper in the host future and can never be wrapped again on surfacing.
  final error = r is $Value ? r : _futureArg(runtime, r);
  final stackTrace = _futureArg(runtime, s);
  return $Future.wrap(
    Future.error(
      error ?? Object(),
      stackTrace is StackTrace
          ? stackTrace
          : stackTrace is TypedInstance
          ? _GuestStackTrace(stackTrace, runtime)
          : null,
    ),
    runtime: runtime,
    // An error future never completes with a value — `Future<Never>` passes
    // every `Future<T>` await gate (Never <: T) so `await` still throws it.
    runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
      runtime.lookupType(CoreTypes.never),
    ]),
  );
}

/// A guest `implements StackTrace` cannot cross the host `Future.error`
/// boundary — carry it inside a host adapter that reports the guest's own
/// `toString` when the trace is printed.
final class _GuestStackTrace implements StackTrace {
  const _GuestStackTrace(this.guest, this.runtime);

  final TypedInstance guest;
  final Runtime runtime;

  @override
  String toString() => runtime.valueToString(guest);
}

// `Future(computation)` queues on the event loop (after microtasks), so it
// must not reuse the microtask/sync paths.
$Value? _futureNew(Runtime runtime, Object? r, Object? s, Object? c) {
  final computation = r as EvalFunction;
  final resultType = runtime.bridgeConstructorTypeId ??
      runtime.typedFutureTypeForCallback(computation);
  return $Future.wrap(
    Future(
      () => _futureCompletionArg(runtime, computation.call(runtime, null, null, null, 0), resultType),
    ),
    runtime: runtime,
    runtimeTypeId: resultType,
  );
}

$Value? _futureSync(Runtime runtime, Object? r, Object? s, Object? c) {
  final computation = r as EvalFunction;
  final resultType = runtime.bridgeConstructorTypeId ??
      runtime.typedFutureTypeForCallback(computation);
  return $Future.wrap(
    Future.sync(
      () => _futureCompletionArg(runtime, computation.call(runtime, null, null, null, 0), resultType),
    ),
    runtime: runtime,
    runtimeTypeId: resultType,
  );
}

$Value? _futureMicrotask(Runtime runtime, Object? r, Object? s, Object? c) {
  final computation = r as EvalFunction;
  final resultType = runtime.bridgeConstructorTypeId ??
      runtime.typedFutureTypeForCallback(computation);
  return $Future.wrap(
    Future.microtask(
      () => _futureCompletionArg(runtime, computation.call(runtime, null, null, null, 0), resultType),
    ),
    runtime: runtime,
    runtimeTypeId: resultType,
  );
}
