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
    runtime.registerBridgeFuncRegisters('dart:core', 'Future.any', _futureAny);
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Future.wait',
      _futureWait,
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
                BridgeTypeRef(AsyncTypes.futureOr, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                ]),
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
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'computation',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(AsyncTypes.futureOr, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                      ]),
                    ),
                  ),
                ),
              ),
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
      'any': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'futures',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.future, [
                      BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                    ]),
                  ),
                ]),
              ),
              false,
            ),
          ],
          namedParams: [],
          generics: {'T': BridgeGenericParam()},
        ),
        isStatic: true,
      ),
      'wait': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                ]),
              ),
            ]),
          ),
          params: [
            BridgeParameter(
              'futures',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.future, [
                      BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                    ]),
                  ),
                ]),
              ),
              false,
            ),
          ],
          namedParams: [
            BridgeParameter(
              'eagerError',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              true,
            ),
            BridgeParameter(
              'cleanUp',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'successValue',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
          generics: {'T': BridgeGenericParam()},
        ),
        isStatic: true,
      ),
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
      'onError': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'handleError',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(AsyncTypes.futureOr, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                      ]),
                    ),
                    params: [
                      BridgeParameter(
                        'error',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                        false,
                      ),
                      BridgeParameter(
                        'stackTrace',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.stackTrace),
                        ),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
          generics: {
            'E': BridgeGenericParam($extends: BridgeTypeRef(CoreTypes.object)),
          },
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
      'ignore': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [],
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
        return $Closure(__then.func, this);
      case 'onError':
        return $Closure(__onError.func, this);
      case 'asStream':
        return $Closure(__asStream.func, this);
      case 'timeout':
        return $Closure(__timeout.func, this);
      case 'whenComplete':
        return $Closure(__whenComplete.func, this);
      case 'catchError':
        return $Closure(__catchError.func, this);
      case 'ignore':
        return $Closure(__ignore.func, this);
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
          TypedInterop.boxExternal(unwrapped, runtime: runtime),
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

  static const $Function __onError = $Function(_onError);

  static $Value? _onError(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $future = target as $Future;
    final handleError = r as EvalFunction;
    final test = s as EvalFunction?;
    final typeArguments = runtime.bridgeCallTypeArguments;
    final errorType = typeArguments.isEmpty ? null : typeArguments.first;
    final errorCheckType = errorType == null
        ? null
        : runtime.internParameterizedType(CoreTypes.list, [errorType]);

    bool matchesErrorType(Object error) {
      if (errorCheckType == null) return true;
      try {
        runtime.assertTypedTypeArgument(
          TypedExceptionState.boxException(error, runtime),
          errorCheckType,
          0,
        );
        return true;
      } on TypeError {
        return false;
      }
    }

    Object? rethrowOriginal(Object error, StackTrace trace) {
      final original = error is WrappedException ? error.exception : error;
      Error.throwWithStackTrace(original, trace);
    }

    FutureOr<Object?> onErrorCallback(Object error, StackTrace trace) {
      if (!matchesErrorType(error)) rethrowOriginal(error, trace);
      final boxedError = TypedExceptionState.boxException(error, runtime);
      try {
        if (test != null &&
            (test.call(runtime, target, boxedError, null, 1)?.$value as bool? ??
                    false) ==
                false) {
          rethrowOriginal(error, trace);
        }
        return _futureArg(
          runtime,
          handleError.call(
            runtime,
            target,
            boxedError,
            $StackTrace.wrap(trace),
            2,
          ),
        );
      } on WrappedException catch (wrapped, callbackTrace) {
        Error.throwWithStackTrace(wrapped.exception, callbackTrace);
      }
    }

    final resultType =
        runtime.bridgeCallReturnTypeId ?? $future.$getRuntimeType(runtime);
    final future = $future.$value.then<Object?>(
      (value) => value,
      onError: onErrorCallback,
    );
    return $Future.wrap(future, runtime: runtime, runtimeTypeId: resultType);
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

  static const $Function __ignore = $Function(_ignore);

  static $Value? _ignore(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    (target as $Future).$value.ignore();
    return null;
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

  @override
  void ignore() => $value.ignore();
}

$Value? _futureDelayed(Runtime runtime, Object? r, Object? s, Object? c) {
  final computation = s as EvalFunction?;
  final resultType =
      runtime.bridgeConstructorTypeId ??
      (computation == null
          ? null
          : runtime.typedFutureTypeForCallback(computation));
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
  if (arg is $Future &&
      resultType != null &&
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
  final resultType =
      runtime.bridgeConstructorTypeId ??
      runtime.typedFutureTypeForCallback(computation);
  return $Future.wrap(
    Future(
      () => _futureCompletionArg(
        runtime,
        computation.call(runtime, null, null, null, 0),
        resultType,
      ),
    ),
    runtime: runtime,
    runtimeTypeId: resultType,
  );
}

$Value? _futureSync(Runtime runtime, Object? r, Object? s, Object? c) {
  final computation = r as EvalFunction;
  final resultType =
      runtime.bridgeConstructorTypeId ??
      runtime.typedFutureTypeForCallback(computation);
  return $Future.wrap(
    Future.sync(
      () => _futureCompletionArg(
        runtime,
        computation.call(runtime, null, null, null, 0),
        resultType,
      ),
    ),
    runtime: runtime,
    runtimeTypeId: resultType,
  );
}

$Value? _futureMicrotask(Runtime runtime, Object? r, Object? s, Object? c) {
  final computation = r as EvalFunction;
  final resultType =
      runtime.bridgeConstructorTypeId ??
      runtime.typedFutureTypeForCallback(computation);
  return $Future.wrap(
    Future.microtask(
      () => _futureCompletionArg(
        runtime,
        computation.call(runtime, null, null, null, 0),
        resultType,
      ),
    ),
    runtime: runtime,
    runtimeTypeId: resultType,
  );
}

$Value? _futureWait(Runtime runtime, Object? r, Object? s, Object? c) {
  final futures = TypedInterop.exportExternal(r, runtime: runtime) as Iterable;
  final cleanUp = c is $null ? null : c as EvalFunction?;
  final iterableType = r is $Value ? r.$getRuntimeType(runtime) : null;
  final futureType = iterableType == null
      ? null
      : runtime.runtimeTypeArgumentAt(iterableType, 0);
  final elementType = futureType == null
      ? runtime.lookupType(CoreTypes.dynamic)
      : runtime.runtimeTypeArgumentAt(futureType, 0) ??
            runtime.lookupType(CoreTypes.dynamic);
  // The declared T can be wider than the input futures' actual type argument.
  // Capture the call's resolved result before the asynchronous completion.
  final resultType = runtime.bridgeCallReturnTypeId;
  final listType =
      (resultType == null
          ? null
          : runtime.runtimeTypeArgumentAt(resultType, 0)) ??
      runtime.internParameterizedType(CoreTypes.list, [elementType]);
  void cleanUpValue(Object? value) {
    final unwrapped = unwrapGuestFuturePayload(value);
    cleanUp!.call(
      runtime,
      null,
      unwrapped is $Value ? unwrapped : runtime.wrap(unwrapped),
      null,
      1,
    );
  }

  return $Future.wrap(
    Future.wait<Object?>(
      futures.map((future) => future as Future<Object?>),
      eagerError: (s is $Value ? s.$value : s) as bool? ?? false,
      cleanUp: cleanUp == null ? null : cleanUpValue,
    ).then(
      (values) => $List.wrap(
        values.map((value) {
          final unwrapped = unwrapGuestFuturePayload(value);
          return unwrapped is $Value ? unwrapped : runtime.wrap(unwrapped);
        }).toList(),
        runtime: runtime,
        runtimeTypeId: listType,
      ),
    ),
    runtime: runtime,
    runtimeTypeId:
        resultType ??
        runtime.internParameterizedType(CoreTypes.future, [listType]),
  );
}

$Value? _futureAny(Runtime runtime, Object? r, Object? s, Object? c) {
  final futures = TypedInterop.exportExternal(r, runtime: runtime) as Iterable;
  final iterableType = r is $Value ? r.$getRuntimeType(runtime) : null;
  final futureType = iterableType == null
      ? null
      : runtime.runtimeTypeArgumentAt(iterableType, 0);
  final elementType = futureType == null
      ? runtime.lookupType(CoreTypes.dynamic)
      : runtime.runtimeTypeArgumentAt(futureType, 0) ??
            runtime.lookupType(CoreTypes.dynamic);
  final resultType =
      runtime.bridgeCallReturnTypeId ??
      runtime.internParameterizedType(CoreTypes.future, [elementType]);

  return $Future.wrap(
    Future.any<Object?>(futures.map((future) => future as Future<Object?>)),
    runtime: runtime,
    runtimeTypeId: resultType,
  );
}
