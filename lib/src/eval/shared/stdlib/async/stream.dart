// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [StreamSubscription]
class $StreamSubscription implements $Instance {
  $StreamSubscription.wrap(this.$value);

  static const _$spec = BridgeTypeSpec('dart:async', 'StreamSubscription');

  /// Compile-time bridged type reference for [$StreamSubscription]
  static const $type = BridgeTypeRef(_$spec);

  /// Compile-time bridged class declaration for [$StreamSubscription]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type,
          isAbstract: true, generics: {'T': BridgeGenericParam()}),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type))),
      },
      methods: {
        'cancel': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])))),
        'asFuture': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'futureValue',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T'), nullable: true),
                  true)
            ])),
        'pause': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [
              BridgeParameter('resumeSignal',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)), true)
            ])),
        'resume': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)))),
        'onDone': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [
              BridgeParameter(
                  'handleDone',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function),
                      nullable: true),
                  false)
            ])),
        'onError': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [
              BridgeParameter(
                  'handleError',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function),
                      nullable: true),
                  false)
            ])),
      },
      getters: {
        'isPaused': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)))),
      },
      setters: {},
      fields: {},
      wrap: true);

  @override
  final StreamSubscription $value;

  late final $Instance _superclass = $Object($value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'cancel':
        return __cancel;
      case 'asFuture':
        return __asFuture;
      case 'pause':
        return __pause;
      case 'resume':
        return __resume;
      case 'onDone':
        return __onDone;
      case 'onError':
        return __onError;
      case 'isPaused':
        return $bool($value.isPaused);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __cancel = $Function(_cancel);
  static $Value? _cancel(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $StreamSubscription;
    return $Future.wrap(self.$value.cancel());
  }

  static const $Function __asFuture = $Function(_asFuture);
  static $Value? _asFuture(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $StreamSubscription;
    return $Future.wrap(self.$value.asFuture(args[0]));
  }

  static const $Function __pause = $Function(_pause);
  static $Value? _pause(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $StreamSubscription;
    self.$value.pause(args.isNotEmpty ? args[0]!.$value as Future? : null);
    return null;
  }

  static const $Function __resume = $Function(_resume);
  static $Value? _resume(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $StreamSubscription;
    self.$value.resume();
    return null;
  }

  static const $Function __onDone = $Function(_onDone);
  static $Value? _onDone(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $StreamSubscription;
    final listener = args[0] != null ? args[0] as EvalCallable : null;
    self.$value.onDone(
        listener != null ? () => listener.call(runtime, null, []) : null);
    return null;
  }

  static const $Function __onError = $Function(_onError);
  static $Value? _onError(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $StreamSubscription;
    final listener = args[0] != null ? args[0] as EvalCallable : null;
    self.$value.onError(
        listener != null ? (e) => listener.call(runtime, null, [e]) : null);
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);
}

/// dart_eval wrapper for [StreamTransformer]
class $StreamTransformer implements $Instance {
  /// Wrap a [StreamTransformer] in a [$StreamTransformer]
  $StreamTransformer.wrap(this.$value);

  /// Compile-time bridged type reference for [$Stream]
  static const $type = BridgeTypeRef(AsyncTypes.streamTransformer);

  static const $declaration = BridgeClassDef(
      BridgeClassType($type,
          isAbstract: true,
          generics: {'S': BridgeGenericParam(), 'T': BridgeGenericParam()}),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type))),
      },
      methods: {
        'bind': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'stream',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                      [BridgeTypeAnnotation(BridgeTypeRef.ref('S'))])),
                  false)
            ])),
      },
      getters: {},
      setters: {},
      fields: {},
      wrap: true);

  @override
  final StreamTransformer $value;

  @override
  StreamTransformer get $reified => $value;

  late final $Instance _superclass = $Object($value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'bind':
        return __bind;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __bind = $Function(_bind);

  static $Value? _bind(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $StreamTransformer;
    return $Stream.wrap(self.$value.bind(args[0]!.$value as Stream));
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);
}

/// dart_eval wrapper for [Stream]
class $Stream implements $Instance {
  /// Wrap a [Stream] in a [$Stream]
  $Stream.wrap(this.$value);

  /// Compile-time bridged type reference for [$Stream]
  static const $type = BridgeTypeRef(CoreTypes.stream);

  /// Compile-time bridged class declaration for [$Stream]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type,
          isAbstract: true, generics: {'T': BridgeGenericParam()}),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type))),
        'empty': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])))),
        'value': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'value', BridgeTypeAnnotation(BridgeTypeRef.ref('T')), false)
            ])),
        'error': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter('error',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)), false)
            ])),
        'fromFuture': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter('future',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)), false)
            ])),
        'fromFutures': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'futures',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable, [
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future, [
                      BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                    ]))
                  ])),
                  false),
            ])),
        'fromIterable': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'iterable',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable, [
                    BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                  ])),
                  false)
            ])),
        'periodic': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'duration',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration)),
                  false),
              BridgeParameter(
                  'computation',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  true),
            ])),
      },
      methods: {
        'asBroadcastStream': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'onListen',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  true),
              BridgeParameter(
                  'onCancel',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  true),
            ])),
        'asyncExpand': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'convert',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
            ])),
        'asyncMap': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'convert',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
            ])),
        'contains': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool))])),
            params: [
              BridgeParameter(
                  'needle',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T'), nullable: true),
                  false),
            ])),
        'distinct': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'equals',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function),
                      nullable: true),
                  true),
            ])),
        'elementAt': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter('index',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            ])),
        'every': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool))])),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
            ])),
        'expand': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'convert',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
            ])),
        'first': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  true),
            ])),
        'firstWhere': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
              BridgeParameter(
                  'orElse',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  true),
            ])),
        'fold': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter('initialValue',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')), false),
              BridgeParameter(
                  'combine',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
            ])),
        'forEach': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType))])),
            params: [
              BridgeParameter(
                  'action',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
            ])),
        'handleError': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'onError',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  true),
            ])),
        'join': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string))])),
            params: [
              BridgeParameter('separator',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), true),
            ])),
        'lastWhere': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
              BridgeParameter(
                  'orElse',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  true),
            ])),
        'listen': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType))])),
            params: [
              BridgeParameter(
                  'onData',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
            ],
            namedParams: [
              BridgeParameter(
                  'onError',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  true),
              BridgeParameter(
                  'onDone',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  true),
              BridgeParameter('cancelOnError',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
            ])),
        'map': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'convert',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
            ])),
        'pipe': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType))])),
            params: [
              BridgeParameter('sink',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)), false),
            ])),
        'reduce': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'combine',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
            ])),
        'singleWhere': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
              BridgeParameter(
                  'orElse',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  true),
            ])),
        'skip': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter('count',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            ])),
        'skipWhile': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
            ])),
        'take': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter('count',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            ])),
        'takeWhile': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
            ])),
        'timeout': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'timeLimit',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration)),
                  false),
              BridgeParameter(
                  'onTimeout',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  true),
            ])),
        'toList': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                  [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            ])),
            params: [
              BridgeParameter('growable',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
            ])),
        'transform': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter('streamTransformer',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)), false),
            ])),
        'where': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false),
            ])),
      },
      getters: {
        'first': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])))),
        'last': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])))),
        'length': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))])))),
        'single': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef.ref('T'))])))),
        'isBroadcast': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)))),
        'isClosed': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)))),
      },
      setters: {},
      fields: {},
      wrap: true);

  @override
  final Stream $value;

  late final $Instance _superclass = $Object($value);

  /// Creates a new empty [$Stream]
  static $Value? $empty(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Stream.wrap(Stream.empty());
  }

  /// Creates a new [$Stream] from an [Iterable]
  static $Value? $fromIterable(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $Stream.wrap(Stream.fromIterable(args[0]!.$value as Iterable));
  }

  /// Creates a new [$Stream] that runs periodically
  static $Value? $periodic(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final computation = args[1]?.$value as EvalCallable?;
    return $Stream.wrap(Stream.periodic(
        args[0]!.$value as Duration,
        computation == null
            ? null
            : (i) => runtime.wrap(computation.call(runtime, null, [$int(i)]))));
  }

  /// Creates a new [$Stream] that emits a single value
  static $Value? $_value(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Stream.wrap(Stream.value(args[0]!.$value));
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
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final onListen = args[0] != null ? args[0] as EvalCallable : null;
    final onCancel = args[1] != null ? args[1] as EvalCallable : null;
    return $Stream.wrap($target.$value.asBroadcastStream(
      onListen: onListen != null
          ? (subscription) => onListen
              .call(runtime, null, [$StreamSubscription.wrap(subscription)])
          : null,
      onCancel: onCancel != null
          ? (subscription) => onCancel
              .call(runtime, null, [$StreamSubscription.wrap(subscription)])
          : null,
    ));
  }

  static const $Function __asyncExpand = $Function(_asyncExpand);

  static $Value _asyncExpand(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final convert = args[0] as EvalCallable;
    return $Stream.wrap($target.$value.asyncExpand(
        (event) => convert.call(runtime, null, [event]) as Stream));
  }

  static const $Function __asyncMap = $Function(_asyncMap);

  static $Value _asyncMap(Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final convert = args[0] as EvalCallable;
    return $Stream.wrap($target.$value
        .asyncMap((event) => convert.call(runtime, null, [event])));
  }

  static const $Function __cast = $Function(_cast);

  static $Value _cast(Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    return $Stream.wrap($target.$value.cast());
  }

  static const $Function __contains = $Function(_contains);

  static $Value _contains(Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final needle = args[0];
    return $Future
        .wrap((() async => $bool(await $target.$value.contains(needle)))());
  }

  static const $Function __distinct = $Function(_distinct);

  static $Value _distinct(Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    return $Stream.wrap($target.$value.distinct());
  }

  static const $Function __drain = $Function(_drain);

  static $Value _drain(Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    return $Future.wrap((() async => runtime.wrap($target.$value.drain()))());
  }

  static const $Function __elementAt = $Function(_elementAt);

  static $Value _elementAt(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final index = args[0] as $int;
    return $Future.wrap((() async =>
        runtime.wrap(await $target.$value.elementAt(index.$value)))());
  }

  static const $Function __every = $Function(_every);

  static $Value _every(Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final test = args[0] as EvalCallable;
    return $Future.wrap((() async => $bool(await $target.$value.every((event) =>
        test.call(runtime, null, [runtime.wrap(event)]) as bool)))());
  }

  static const $Function __expand = $Function(_expand);

  static $Value _expand(Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final convert = args[0] as EvalCallable;
    return $Stream.wrap($target.$value.expand((event) =>
        convert.call(runtime, null, [runtime.wrap(event)]) as Iterable));
  }

  static const $Function __firstWhere = $Function(_firstWhere);

  static $Value _firstWhere(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final test = args[0] as EvalCallable;
    return $Future.wrap(
      (() async => $target.$value
          .firstWhere((event) => test.call(runtime, null, [event]) as bool))(),
    );
  }

  static const $Function __fold = $Function(_fold);

  static $Value _fold(Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final initialValue = args[0];
    final combine = args[1] as EvalCallable;
    return $Future.wrap(
      (() async => $target.$value.fold(
          initialValue,
          (previous, element) =>
              combine.call(runtime, null, [previous as dynamic, element])))(),
    );
  }

  static const $Function __forEach = $Function(_forEach);

  static $Value _forEach(Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final action = args[0] as EvalCallable;
    return $Future.wrap(
      (() async => $target.$value.forEach(
          (event) => action.call(runtime, null, [runtime.wrap(event)])))(),
    );
  }

  static const $Function __handleError = $Function(_handleError);

  static $Value _handleError(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final onError = args[0] as EvalCallable;
    return $Stream.wrap($target.$value.handleError((error /*, stackTrace*/) {
      onError.call(runtime, null, [error /*, stackTrace*/]);
    }));
  }

  static const $Function __join = $Function(_join);

  static $Value _join(Runtime runtime, $Value? target, List<$Value?> args) {
    final $target = target!.$value as Stream;
    final separator = args[0]?.$value ?? "";
    return $Future.wrap((() async => $String(await $target.join(separator)))());
  }

  static const $Function __lastWhere = $Function(_lastWhere);

  static $Value _lastWhere(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final test = args[0] as EvalCallable;
    return $Future.wrap(
      (() async => $target.$value
          .lastWhere((event) => test.call(runtime, null, [event]) as bool))(),
    );
  }

  static const $Function __listen = $Function(_listen);

  static $Value _listen(Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final onData = args[0] as EvalCallable;
    final onDone = args[1] as EvalCallable?;
    final onError = args[2] as EvalCallable?;
    final cancelOnError = args[3] as $bool?;
    return $StreamSubscription.wrap($target.$value.listen((event) {
      onData.call(runtime, null, [runtime.wrap(event)]);
    }, onDone: () {
      onDone?.call(runtime, null, []);
    }, onError: (error /*, stackTrace*/) {
      onError?.call(runtime, null, [error /*, stackTrace*/]);
    }, cancelOnError: cancelOnError?.$value));
  }

  static const $Function __map = $Function(_map);

  static $Value _map(Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final convert = args[0] as EvalCallable;
    return $Stream.wrap($target.$value.map((event) =>
        convert.call(runtime, null, [runtime.wrap(event)]) as $Value));
  }

  /*static const $Function __pipe = $Function(_pipe);

  static $Value _pipe(Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final $StreamConsumer $consumer = args[0] as $StreamConsumer;
    return $Future.wrap((() async => $target.$value.pipe($consumer.$value))(), (value) => value as $Value);
  }*/

  static const $Function __reduce = $Function(_reduce);

  static $Value _reduce(Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final combine = args[0] as EvalCallable;
    return $Future.wrap(
      (() async => $target.$value.reduce((previous, element) =>
          combine.call(runtime, null, [previous, element])))(),
    );
  }

  static const $Function __singleWhere = $Function(_singleWhere);

  static $Value _singleWhere(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final test = args[0] as EvalCallable;
    return $Future.wrap(
      (() async => $target.$value
          .singleWhere((event) => test.call(runtime, null, [event]) as bool))(),
    );
  }

  static const $Function __skip = $Function(_skip);

  static $Value _skip(Runtime runtime, $Value? target, List<$Value?> args) {
    final $Stream $target = target as $Stream;
    final count = args[0] as $int;
    return $Stream.wrap($target.$value.skip(count.$value));
  }

  static const $Function __transform = $Function(_transform);

  static $Value _transform(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $target = target!.$value as Stream;
    final $transformer = args[0]!.$value as StreamTransformer;
    return $Stream.wrap($target.transform($transformer));
  }

  @override
  get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {}
}

/// dart_eval wrapper for [StreamSink]
class $StreamSink implements $Instance {
  /// Wrap a [StreamSink] in a [$StreamSink]
  $StreamSink.wrap(this.$value);

  /// Compile-time bridged type reference for [$StreamSink]
  static const $type =
      BridgeTypeRef(BridgeTypeSpec('dart:async', 'StreamSink'));

  /// Compile-time bridged class declaration for [$StreamSink]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type,
          isAbstract: true, generics: {'S': BridgeGenericParam()}),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type)))
      },
      methods: {
        'close': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)))),
      },
      getters: {
        'done': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)))),
      },
      setters: {},
      fields: {},
      wrap: true);

  late final $Instance _superclass = $Object($value);

  @override
  final StreamSink $value;

  @override
  get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'close':
        return __close;
      case 'done':
        return $Future.wrap($value.done);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __close = $Function(_close);

  static $Value? _close(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Future.wrap(target!.$value.close());
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper for [StreamView]
class $StreamView implements $Instance {
  /// Wrap a [StreamView] in a [$StreamView]
  $StreamView.wrap(this.$value);

  static const $type = BridgeTypeRef(AsyncTypes.streamView);

  /// Compile-time bridged class declaration for [$StreamSink]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type,
          $extends: BridgeTypeRef(CoreTypes.stream),
          isAbstract: true,
          generics: {'S': BridgeGenericParam()}),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(params: [
          BridgeParameter('stream',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream)), false)
        ], returns: BridgeTypeAnnotation($type)))
      },
      methods: {},
      getters: {},
      wrap: true);

  late final $Instance _superclass = $Stream.wrap($value);

  /// Creates a new [$StreamView] wrapping [StreamView.new]
  static $StreamView $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $StreamView.wrap(StreamView(args[0]!.$value));
  }

  @override
  final StreamView $value;

  @override
  StreamView get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
