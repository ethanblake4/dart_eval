// ignore_for_file: camel_case_types

import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/stdlib/core.dart';

/// Wrapper for [Future]
class $Future<T> implements Future<T>, $Instance {
  /// Configure [$Future] for runtime in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Future.microtask', __$Future$microtask.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Future.sync', __$Future$sync.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Future.value', __$Future$value.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Future.error', __$Future$error.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Future.delayed', __$Future$delayed.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Future.wait', __$static$method$wait.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Future.any', __$static$method$any.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Future.forEach', __$static$method$forEach.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Future.doWhile', __$static$method$doWhile.call,
        isBridge: false);
  }

  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.future), isAbstract: true),
      constructors: {
        'microtask': BridgeConstructorDef(
          BridgeFunctionDef(
            generics: {
              'T': BridgeGenericParam(),
            },
            returns: BridgeTypeAnnotation($type),
            params: [
              BridgeParameter(
                  'computation',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isFactory: true,
        ),
        'sync': BridgeConstructorDef(
          BridgeFunctionDef(
            generics: {
              'T': BridgeGenericParam(),
            },
            returns: BridgeTypeAnnotation($type),
            params: [
              BridgeParameter(
                  'computation',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isFactory: true,
        ),
        'value': BridgeConstructorDef(
          BridgeFunctionDef(
            generics: {
              'T': BridgeGenericParam(),
            },
            returns: BridgeTypeAnnotation($type),
            params: [
              BridgeParameter(
                  'value',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic, []),
                      nullable: true),
                  true)
            ],
            namedParams: [],
          ),
          isFactory: true,
        ),
        'error': BridgeConstructorDef(
          BridgeFunctionDef(
            generics: {
              'T': BridgeGenericParam(),
            },
            returns: BridgeTypeAnnotation($type),
            params: [
              BridgeParameter(
                  'error',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'stackTrace',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stackTrace, []),
                      nullable: true),
                  true)
            ],
            namedParams: [],
          ),
          isFactory: true,
        ),
        'delayed': BridgeConstructorDef(
          BridgeFunctionDef(
            generics: {
              'T': BridgeGenericParam(),
            },
            returns: BridgeTypeAnnotation($type),
            params: [
              BridgeParameter(
                  'duration',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'computation',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  true)
            ],
            namedParams: [],
          ),
          isFactory: true,
        )
      },
      methods: {
        'wait': BridgeMethodDef(
            BridgeFunctionDef(
              generics: {
                'T': BridgeGenericParam(),
              },
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.future, [
                    BridgeTypeRef(CoreTypes.list, [BridgeTypeRef.ref('T', [])]),
                  ]),
                  nullable: false),
              params: [
                BridgeParameter(
                    'futures',
                    BridgeTypeAnnotation(
                        BridgeTypeRef(CoreTypes.iterable, [
                          BridgeTypeRef(
                              CoreTypes.future, [BridgeTypeRef.ref('T', [])]),
                        ]),
                        nullable: false),
                    false)
              ],
              namedParams: [
                BridgeParameter(
                    'eagerError',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                        nullable: false),
                    true),
                BridgeParameter(
                    'cleanUp',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                        nullable: false),
                    true)
              ],
            ),
            isStatic: true),
        'any': BridgeMethodDef(
            BridgeFunctionDef(
              generics: {
                'T': BridgeGenericParam(),
              },
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.future, [BridgeTypeRef.ref('T', [])]),
                  nullable: false),
              params: [
                BridgeParameter(
                    'futures',
                    BridgeTypeAnnotation(
                        BridgeTypeRef(CoreTypes.iterable, [
                          BridgeTypeRef(
                              CoreTypes.future, [BridgeTypeRef.ref('T', [])]),
                        ]),
                        nullable: false),
                    false)
              ],
              namedParams: [],
            ),
            isStatic: true),
        'forEach': BridgeMethodDef(
            BridgeFunctionDef(
              generics: {
                'T': BridgeGenericParam(),
              },
              returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future),
                  nullable: false),
              params: [
                BridgeParameter(
                    'elements',
                    BridgeTypeAnnotation(
                        BridgeTypeRef(
                            CoreTypes.iterable, [BridgeTypeRef.ref('T', [])]),
                        nullable: false),
                    false),
                BridgeParameter(
                    'action',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                        nullable: false),
                    false)
              ],
              namedParams: [],
            ),
            isStatic: true),
        'doWhile': BridgeMethodDef(
            BridgeFunctionDef(
              generics: {
                'T': BridgeGenericParam(),
              },
              returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future),
                  nullable: false),
              params: [
                BridgeParameter(
                    'action',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function),
                        nullable: false),
                    false)
              ],
              namedParams: [],
            ),
            isStatic: true),
        'then': BridgeMethodDef(
            BridgeFunctionDef(
              generics: {
                'R': BridgeGenericParam(),
              },
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.future, [BridgeTypeRef.ref('R', [])]),
                  nullable: false),
              params: [
                BridgeParameter(
                    'onValue',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function),
                        nullable: false),
                    false)
              ],
              namedParams: [
                BridgeParameter(
                    'onError',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                        nullable: true),
                    true)
              ],
            ),
            isStatic: false),
        'catchError': BridgeMethodDef(
            BridgeFunctionDef(
              generics: {
                'T': BridgeGenericParam(),
              },
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.future, [BridgeTypeRef.ref('T', [])]),
                  nullable: false),
              params: [
                BridgeParameter(
                    'onError',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                        nullable: false),
                    false)
              ],
              namedParams: [
                BridgeParameter(
                    'test',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                        nullable: false),
                    true)
              ],
            ),
            isStatic: false),
        'whenComplete': BridgeMethodDef(
            BridgeFunctionDef(
              generics: {
                'T': BridgeGenericParam(),
              },
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.future, [BridgeTypeRef.ref('T', [])]),
                  nullable: false),
              params: [
                BridgeParameter(
                    'action',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function),
                        nullable: false),
                    false)
              ],
              namedParams: [],
            ),
            isStatic: false),
        'asStream': BridgeMethodDef(
            BridgeFunctionDef(
              generics: {
                'T': BridgeGenericParam(),
              },
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.stream, [BridgeTypeRef.ref('T', [])]),
                  nullable: false),
              params: [],
              namedParams: [],
            ),
            isStatic: false),
        'timeout': BridgeMethodDef(
            BridgeFunctionDef(
              generics: {
                'T': BridgeGenericParam(),
              },
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.future, [BridgeTypeRef.ref('T', [])]),
                  nullable: false),
              params: [
                BridgeParameter(
                    'timeLimit',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, []),
                        nullable: false),
                    false)
              ],
              namedParams: [
                BridgeParameter(
                    'onTimeout',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function),
                        nullable: false),
                    true)
              ],
            ),
            isStatic: false),
      },
      getters: {},
      setters: {},
      fields: {},
      wrap: true);

  $Future.wrap(this.$value) : _superclass = $Object($value);

  @override
  final Future<T> $value;

  @override
  Future get $reified =>
      $value.then((value) => value is $Value ? value.$value : value);

  final $Instance _superclass;

  static const $type = BridgeTypeRef(CoreTypes.future);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'asStream':
        return __$asStream;
      case 'catchError':
        return __$catchError;
      case 'then':
        return __$then;
      case 'timeout':
        return __$timeout;
      case 'whenComplete':
        return __$whenComplete;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.future);

  @override
  Stream<T> asStream() => $value.asStream();

  static const __$asStream = $Function(_$asStream);
  static $Value? _$asStream(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Future;
    final $result = $this.asStream();
    return $Stream.wrap($result);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      $value.catchError(onError, test: test);

  static const __$catchError = $Function(_$catchError);
  static $Value? _$catchError(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Future;
    final onError = args[0]?.$reified as Function;
    final test = args[1] as EvalCallable?;
    final $result = $this.catchError(onError,
        test: test == null
            ? null
            : (error) => test
                .call(runtime, target, [runtime.wrap(error)])?.$value as bool);

    return $Future.wrap($result);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
          {Function? onError}) =>
      $value.then(onValue, onError: onError);

  static const __$then = $Function(_$then);
  static $Value? _$then(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Future;
    final onValue = args[0] as EvalCallable;
    final onError = args[1] as EvalCallable?;
    final $result = $this.then(
      (value) => onValue.call(runtime, target, [runtime.wrap(value)]),
      onError: onError == null
          ? null
          : (err, stack) {
              onError.call(runtime, target,
                  [runtime.wrap(err), $StackTrace.wrap(stack)]);
            },
    );
    return $Future.wrap($result);
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      $value.timeout(timeLimit, onTimeout: onTimeout);

  static const __$timeout = $Function(_$timeout);
  static $Value? _$timeout(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Future;
    final timeLimit = args[0]!.$value as Duration;
    final onTimeout = args[1] as EvalCallable?;
    final $result = $this.timeout(timeLimit,
        onTimeout: onTimeout == null
            ? null
            : () => onTimeout.call(runtime, target, []));
    return $Future.wrap($result);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      $value.whenComplete(action);

  static const __$whenComplete = $Function(_$whenComplete);
  static $Value? _$whenComplete(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Future;
    final action = args[0] as EvalCallable;
    final $result = $this.whenComplete(() => action.call(runtime, target, []));
    return $Future.wrap($result);
  }

  static const __$static$method$wait = $Function(_$static$method$wait);
  static $Value? _$static$method$wait(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final futures = (args[0]!.$value as Iterable).cast<Future>();
    final eagerError = (args[1]?.$value as bool?) ?? false;
    final cleanUp = args[2] as EvalCallable?;
    final $result = Future.wait(
      futures,
      eagerError: eagerError,
      cleanUp: cleanUp == null
          ? null
          : (value) => cleanUp.call(runtime, target, [runtime.wrap(value)]),
    );
    return $Future.wrap($result) as $Value?;
  }

  static const __$static$method$any = $Function(_$static$method$any);
  static $Value? _$static$method$any(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final futures = (args[0]!.$value as Iterable).cast<Future>();
    final $result = Future.any(futures);
    return $Future.wrap($result);
  }

  static const __$static$method$forEach = $Function(_$static$method$forEach);
  static $Value? _$static$method$forEach(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final elements = args[0]!.$value as Iterable;
    final action = args[1] as EvalCallable;
    final $result = Future.forEach(
      elements,
      (element) => action.call(runtime, target, [element]),
    );
    return $Future.wrap($result);
  }

  static const __$static$method$doWhile = $Function(_$static$method$doWhile);
  static $Value? _$static$method$doWhile(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final action = args[0] as EvalCallable;
    final $result =
        Future.doWhile(() => action.call(runtime, target, [])!.$value);
    return $Future.wrap($result);
  }

  static const __$Future$microtask = $Function(_$Future$microtask);
  static $Value? _$Future$microtask(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final computation = args[0] as EvalCallable;
    return $Future
        .wrap(Future.microtask(() => computation.call(runtime, target, [])));
  }

  static const __$Future$sync = $Function(_$Future$sync);
  static $Value? _$Future$sync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final computation = args[0] as EvalCallable;
    return $Future
        .wrap(Future.sync(() => computation.call(runtime, target, [])));
  }

  static const __$Future$value = $Function(_$Future$value);
  static $Value? _$Future$value(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final value = args[0];
    return $Future.wrap(Future.value(value));
  }

  static const __$Future$error = $Function(_$Future$error);
  static $Value? _$Future$error(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final error = args[0]!.$value as Object;
    final stackTrace = args[1]?.$value as StackTrace?;
    return $Future.wrap(Future.error(error, stackTrace));
  }

  static const __$Future$delayed = $Function(_$Future$delayed);
  static $Value? _$Future$delayed(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final duration = args[0]!.$value as Duration;
    final computation = args[1] as EvalCallable?;
    return $Future.wrap(Future.delayed(
      duration,
      computation == null ? null : () => computation.call(runtime, target, []),
    ));
  }
}
