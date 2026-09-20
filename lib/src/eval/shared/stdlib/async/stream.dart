// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

import 'stream_subscription.dart';

/// dart_eval wrapper for [Stream]
class $Stream implements $Instance {
  /// Wrap a [Stream] in a [$Stream]
  $Stream.wrap(this.$value);

  /// Compile-time bridged type reference for [$Stream]
  static const $type = BridgeTypeRef(CoreTypes.stream);

  /// Compile-time bridged class declaration for [$Stream]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,
      generics: {'T': BridgeGenericParam()},
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(returns: BridgeTypeAnnotation($type)),
      ),
      'empty': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
        ),
      ),
      'value': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
      'error': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
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
      'fromFuture': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'future',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
              false,
            ),
          ],
        ),
      ),
      'fromFutures': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
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
        ),
      ),
      'fromIterable': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'iterable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),
      'periodic': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'duration',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration)),
              false,
            ),
            BridgeParameter(
              'computation',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              true,
            ),
          ],
        ),
      ),
    },
    methods: {
      'asBroadcastStream': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'onListen',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              true,
            ),
            BridgeParameter(
              'onCancel',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              true,
            ),
          ],
        ),
      ),
      'asyncExpand': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'convert',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
        ),
      ),
      'asyncMap': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'convert',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
        ),
      ),
      'contains': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
            ]),
          ),
          params: [
            BridgeParameter(
              'needle',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T'), nullable: true),
              false,
            ),
          ],
        ),
      ),
      'distinct': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'equals',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.function),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),
      'elementAt': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
        ),
      ),
      'every': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
            ]),
          ),
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
        ),
      ),
      'expand': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'convert',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
        ),
      ),
      'first': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              true,
            ),
          ],
        ),
      ),
      'firstWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              true,
            ),
          ],
        ),
      ),
      'fold': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'initialValue',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),
            BridgeParameter(
              'combine',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
        ),
      ),
      'forEach': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            ]),
          ),
          params: [
            BridgeParameter(
              'action',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
        ),
      ),
      'handleError': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'onError',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              true,
            ),
          ],
        ),
      ),
      'join': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            ]),
          ),
          params: [
            BridgeParameter(
              'separator',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              true,
            ),
          ],
        ),
      ),
      'lastWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              true,
            ),
          ],
        ),
      ),
      'listen': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            ]),
          ),
          params: [
            BridgeParameter(
              'onData',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
          namedParams: [
            BridgeParameter(
              'onError',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              true,
            ),
            BridgeParameter(
              'onDone',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              true,
            ),
            BridgeParameter(
              'cancelOnError',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              true,
            ),
          ],
        ),
      ),
      'map': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'convert',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
        ),
      ),
      'pipe': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            ]),
          ),
          params: [
            BridgeParameter(
              'sink',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)),
              false,
            ),
          ],
        ),
      ),
      'reduce': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'combine',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
        ),
      ),
      'singleWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              true,
            ),
          ],
        ),
      ),
      'skip': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'count',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
        ),
      ),
      'skipWhile': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
        ),
      ),
      'take': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'count',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
        ),
      ),
      'takeWhile': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
        ),
      ),
      'timeout': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'timeLimit',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration)),
              false,
            ),
            BridgeParameter(
              'onTimeout',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              true,
            ),
          ],
        ),
      ),
      'toList': BridgeMethodDef(
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
              'growable',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              true,
            ),
          ],
        ),
      ),
      'transform': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'streamTransformer',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)),
              false,
            ),
          ],
        ),
      ),
      'where': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
        ),
      ),
    },
    getters: {
      'first': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
        ),
      ),
      'last': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
        ),
      ),
      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
            ]),
          ),
        ),
      ),
      'single': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
        ),
      ),
      'isBroadcast': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
        ),
      ),
      'isClosed': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
  );

  @override
  final Stream $value;

  late final $Instance _superclass = $Object($value);

  /// Creates a new empty [$Stream]
  static $Value? $empty(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Stream.wrap(Stream.empty());
  }

  /// Creates a new [$Stream] from an [Iterable]
  static $Value? $fromIterable(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $Stream.wrap(Stream.fromIterable((r as $Value).$value as Iterable));
  }

  /// Creates a new [$Stream] that runs periodically
  static $Value? $periodic(Runtime runtime, Object? r, Object? s, Object? c) {
    final computation = (s as $Value?)?.$value as EvalCallable?;
    return $Stream.wrap(
      Stream.periodic(
        (r as $Value).$value as Duration,
        computation == null
            ? null
            : (i) => runtime.wrap(
                computation.call(runtime, null, $int(i), null, 1),
              ),
      ),
    );
  }

  /// Creates a new [$Stream] that emits a single value
  static $Value? $_value(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Stream.wrap(Stream.value((r as $Value).$value));
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'first':
        return $value.first as $Value;
      case 'last':
        return $value.last as $Value;
      case 'length':
        return $Future.wrap((() async => $int(await $value.length))());
      case 'single':
        return $value.single as $Value;
      case 'isBroadcast':
        return $bool($value.isBroadcast);
      case 'asBroadcastStream':
        return __asBroadcastStream;
      case 'asyncExpand':
        return __asyncExpand;
      case 'asyncMap':
        return __asyncMap;
      case 'cast':
        return __cast;
      case 'contains':
        return __contains;
      case 'distinct':
        return __distinct;
      case 'drain':
        return __drain;
      case 'elementAt':
        return __elementAt;
      case 'every':
        return __every;
      case 'expand':
        return __expand;
      case 'firstWhere':
        return __firstWhere;
      case 'fold':
        return __fold;
      case 'forEach':
        return __forEach;
      case 'handleError':
        return __handleError;
      case 'join':
        return __join;
      case 'lastWhere':
        return __lastWhere;
      case 'listen':
        return __listen;
      case 'map':
        return __map;
      /*case 'pipe':
        return __pipe;*/
      case 'reduce':
        return __reduce;
      case 'singleWhere':
        return __singleWhere;
      case 'skip':
        return __skip;
      case 'transform':
        return __transform;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  static const $Function __asBroadcastStream = $Function(_asBroadcastStream);

  static $Value _asBroadcastStream(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final onListen = r != null ? r as EvalCallable : null;
    final onCancel = s != null ? s as EvalCallable : null;
    return $Stream.wrap(
      $target.$value.asBroadcastStream(
        onListen: onListen != null
            ? (subscription) => onListen.call(
                runtime,
                null,
                $StreamSubscription.wrap(subscription),
                null,
                1,
              )
            : null,
        onCancel: onCancel != null
            ? (subscription) => onCancel.call(
                runtime,
                null,
                $StreamSubscription.wrap(subscription),
                null,
                1,
              )
            : null,
      ),
    );
  }

  static const $Function __asyncExpand = $Function(_asyncExpand);

  static $Value _asyncExpand(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final convert = (r as $Value?) as EvalCallable;
    return $Stream.wrap(
      $target.$value.asyncExpand(
        (event) => convert.call(runtime, null, event, null, 1) as Stream,
      ),
    );
  }

  static const $Function __asyncMap = $Function(_asyncMap);

  static $Value _asyncMap(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final convert = (r as $Value?) as EvalCallable;
    return $Stream.wrap(
      $target.$value.asyncMap(
        (event) => convert.call(runtime, null, event, null, 1),
      ),
    );
  }

  static const $Function __cast = $Function(_cast);

  static $Value _cast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    return $Stream.wrap($target.$value.cast());
  }

  static const $Function __contains = $Function(_contains);

  static $Value _contains(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final needle = (r as $Value?);
    return $Future.wrap(
      (() async => $bool(await $target.$value.contains(needle)))(),
    );
  }

  static const $Function __distinct = $Function(_distinct);

  static $Value _distinct(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    return $Stream.wrap($target.$value.distinct());
  }

  static const $Function __drain = $Function(_drain);

  static $Value _drain(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    return $Future.wrap((() async => runtime.wrap($target.$value.drain()))());
  }

  static const $Function __elementAt = $Function(_elementAt);

  static $Value _elementAt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final index = (r as $Value?) as $int;
    return $Future.wrap(
      (() async =>
          runtime.wrap(await $target.$value.elementAt(index.$value)))(),
    );
  }

  static const $Function __every = $Function(_every);

  static $Value _every(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final test = (r as $Value?) as EvalCallable;
    return $Future.wrap(
      (() async => $bool(
        await $target.$value.every(
          (event) =>
              test.call(runtime, null, runtime.wrap(event), null, 1) as bool,
        ),
      ))(),
    );
  }

  static const $Function __expand = $Function(_expand);

  static $Value _expand(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final convert = (r as $Value?) as EvalCallable;
    return $Stream.wrap(
      $target.$value.expand(
        (event) =>
            convert.call(runtime, null, runtime.wrap(event), null, 1)
                as Iterable,
      ),
    );
  }

  static const $Function __firstWhere = $Function(_firstWhere);

  static $Value _firstWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final test = (r as $Value?) as EvalCallable;
    return $Future.wrap(
      (() async => $target.$value.firstWhere(
        (event) => test.call(runtime, null, event, null, 1) as bool,
      ))(),
    );
  }

  static const $Function __fold = $Function(_fold);

  static $Value _fold(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final initialValue = (r as $Value?);
    final combine = (s as $Value?) as EvalCallable;
    return $Future.wrap(
      (() async => $target.$value.fold(
        initialValue,
        (previous, element) =>
            combine.call(runtime, null, previous as dynamic, element, 2),
      ))(),
    );
  }

  static const $Function __forEach = $Function(_forEach);

  static $Value _forEach(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final action = (r as $Value?) as EvalCallable;
    return $Future.wrap(
      (() async => $target.$value.forEach(
        (event) => action.call(runtime, null, runtime.wrap(event), null, 1),
      ))(),
    );
  }

  static const $Function __handleError = $Function(_handleError);

  static $Value _handleError(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final onError = (r as $Value?) as EvalCallable;
    return $Stream.wrap(
      $target.$value.handleError((error /*, stackTrace*/) {
        onError.call(runtime, null, error /*, stackTrace*/, null, 1);
      }),
    );
  }

  static const $Function __join = $Function(_join);

  static $Value _join(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $target = target!.$value as Stream;
    final separator = (r as $Value?)?.$value ?? "";
    return $Future.wrap((() async => $String(await $target.join(separator)))());
  }

  static const $Function __lastWhere = $Function(_lastWhere);

  static $Value _lastWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final test = (r as $Value?) as EvalCallable;
    return $Future.wrap(
      (() async => $target.$value.lastWhere(
        (event) => test.call(runtime, null, event, null, 1) as bool,
      ))(),
    );
  }

  static const $Function __listen = $Function(_listen);

  static $Value _listen(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final onData = (r as $Value?) as EvalCallable;
    final onDone = (s as $Value?) as EvalCallable?;
    final onError = ((c as List<Object?>)[0] as $Value?) as EvalCallable?;
    final cancelOnError = (c[1] as $Value?) as $bool?;
    return $StreamSubscription.wrap(
      $target.$value.listen(
        (event) {
          onData.call(runtime, null, runtime.wrap(event), null, 1);
        },
        onDone: () {
          onDone?.call(runtime, null, null, null, 0);
        },
        onError: (error /*, stackTrace*/) {
          onError?.call(runtime, null, error /*, stackTrace*/, null, 1);
        },
        cancelOnError: cancelOnError?.$value,
      ),
    );
  }

  static const $Function __map = $Function(_map);

  static $Value _map(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final convert = (r as $Value?) as EvalCallable;
    return $Stream.wrap(
      $target.$value.map(
        (event) =>
            convert.call(runtime, null, runtime.wrap(event), null, 1) as $Value,
      ),
    );
  }

  /*static const $Function __pipe = $Function(_pipe);

  static $Value _pipe(Runtime runtime, $Value? target, Object? r, Object? s, Object? c) {
    final $Stream $target = target as $Stream;
    final $StreamConsumer $consumer = (r as $Value?) as $StreamConsumer;
    return $Future.wrap((() async => $target.$value.pipe($consumer.$value))(), (value) => value as $Value);
  }*/

  static const $Function __reduce = $Function(_reduce);

  static $Value _reduce(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final combine = (r as $Value?) as EvalCallable;
    return $Future.wrap(
      (() async => $target.$value.reduce(
        (previous, element) =>
            combine.call(runtime, null, previous, element, 2),
      ))(),
    );
  }

  static const $Function __singleWhere = $Function(_singleWhere);

  static $Value _singleWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final test = (r as $Value?) as EvalCallable;
    return $Future.wrap(
      (() async => $target.$value.singleWhere(
        (event) => test.call(runtime, null, event, null, 1) as bool,
      ))(),
    );
  }

  static const $Function __skip = $Function(_skip);

  static $Value _skip(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $Stream $target = target as $Stream;
    final count = (r as $Value?) as $int;
    return $Stream.wrap($target.$value.skip(count.$value));
  }

  static const $Function __transform = $Function(_transform);

  static $Value _transform(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $target = target!.$value as Stream;
    final $transformer = (r as $Value?)!.$value as StreamTransformer;
    return $Stream.wrap($target.transform($transformer));
  }

  @override
  get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {}
}
