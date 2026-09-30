// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_closure.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_host_collections.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

import 'stream_subscription.dart';

/// dart_eval wrapper for [Stream]
class $Stream implements $Instance {
  /// Wrap a [Stream] in a [$Stream]. [runtimeTypeId] (in [runtime]'s table)
  /// stamps the wrapper's instantiated type — `Stream<int>` from a
  /// `StreamController<int>.stream` getter, for example.
  $Stream.wrap(this.$value, {this.runtimeTypeId, this.runtime});

  /// Compile-time bridged type reference for [$Stream]
  static const $type = BridgeTypeRef(CoreTypes.stream);

  /// `bool Function(T)` — the predicate annotation shared by `where`,
  /// `every`, `skipWhile`, `takeWhile`, and the `*Where` members.
  static const _predicate = BridgeTypeAnnotation(
    BridgeTypeRef.genericFunction(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
        params: [
          BridgeParameter(
            'element',
            BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            false,
          ),
        ],
      ),
    ),
  );

  /// `FutureOr<T> Function()` — the `orElse` annotation shared by the
  /// `*Where` members.
  static const _orElse = BridgeTypeAnnotation(
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
  );

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
      'any': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
            ]),
          ),
          params: [BridgeParameter('test', _predicate, false)],
        ),
      ),
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
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
            ]),
          ),
          params: [
            BridgeParameter(
              'convert',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.stream, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                      ]),
                      nullable: true,
                    ),
                    params: [
                      BridgeParameter(
                        'event',
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
          generics: {'S': BridgeGenericParam()},
        ),
      ),
      'asyncMap': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
            ]),
          ),
          params: [
            BridgeParameter(
              'convert',
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
                        'event',
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
          generics: {'S': BridgeGenericParam()},
        ),
      ),
      'cast': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
            ]),
          ),
          params: [],
          generics: {'R': BridgeGenericParam()},
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
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool),
                    ),
                    params: [
                      BridgeParameter(
                        'a',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                        false,
                      ),
                      BridgeParameter(
                        'b',
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
        ),
      ),
      'drain': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
            ]),
          ),
          params: [
            BridgeParameter(
              'futureValue',
              BridgeTypeAnnotation(
                BridgeTypeRef.ref('S'),
                nullable: true,
              ),
              true,
            ),
          ],
          generics: {'S': BridgeGenericParam()},
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
            BridgeParameter('test', _predicate, false),
          ],
        ),
      ),
      'expand': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
            ]),
          ),
          params: [
            BridgeParameter(
              'convert',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.iterable, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                      ]),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
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
          generics: {'S': BridgeGenericParam()},
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
            BridgeParameter('test', _predicate, false),
            BridgeParameter('orElse', _orElse, true),
          ],
        ),
      ),
      'fold': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
            ]),
          ),
          params: [
            BridgeParameter(
              'initialValue',
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
              false,
            ),
            BridgeParameter(
              'combine',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                    params: [
                      BridgeParameter(
                        'previous',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                        false,
                      ),
                      BridgeParameter(
                        'element',
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
          generics: {'S': BridgeGenericParam()},
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
            BridgeParameter('test', _predicate, false),
            BridgeParameter('orElse', _orElse, true),
          ],
        ),
      ),
      'listen': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(AsyncTypes.streamSubscription, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          params: [
            BridgeParameter(
              'onData',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.function),
                nullable: true,
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
            BridgeParameter(
              'onDone',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.function),
                nullable: true,
              ),
              true,
            ),
            BridgeParameter(
              'cancelOnError',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.bool),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),
      'map': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
            ]),
          ),
          params: [
            BridgeParameter(
              'convert',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                    params: [
                      BridgeParameter(
                        'event',
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
          generics: {'S': BridgeGenericParam()},
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
            BridgeParameter('test', _predicate, false),
            BridgeParameter('orElse', _orElse, true),
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
            BridgeParameter('test', _predicate, false),
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
            BridgeParameter('test', _predicate, false),
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
      'toSet': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.set, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                ]),
              ),
            ]),
          ),
          params: [],
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
            BridgeParameter('test', _predicate, false),
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

  static $Value? $error(Runtime runtime, Object? r, Object? s, Object? c) =>
      $Stream.wrap(Stream<Object?>.error(r!));

  static $Value? $fromFuture(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) => $Stream.wrap(Stream.fromFuture((r as $Value).$value as Future));

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
        return $Future.wrap(
          $value.first,
          runtime: runtime,
          runtimeTypeId: _typedFutureId(runtime),
        );
      case 'last':
        return $Future.wrap(
          $value.last,
          runtime: runtime,
          runtimeTypeId: _typedFutureId(runtime),
        );
      case 'length':
        return $Future.wrap(
          (() async => $int(await $value.length))(),
          runtime: runtime,
          runtimeTypeId: _fixedFutureId(runtime, CoreTypes.int),
        );
      case 'single':
        return $Future.wrap(
          $value.single,
          runtime: runtime,
          runtimeTypeId: _typedFutureId(runtime),
        );
      case 'isBroadcast':
        return $bool($value.isBroadcast);
      case 'any':
        return $Closure(__any.func, this);
      case 'asBroadcastStream':
        return $Closure(__asBroadcastStream.func, this);
      case 'asyncExpand':
        return $Closure(__asyncExpand.func, this);
      case 'asyncMap':
        return $Closure(__asyncMap.func, this);
      case 'cast':
        return $Closure(__cast.func, this);
      case 'contains':
        return $Closure(__contains.func, this);
      case 'distinct':
        return $Closure(__distinct.func, this);
      case 'drain':
        return $Closure(__drain.func, this);
      case 'elementAt':
        return $Closure(__elementAt.func, this);
      case 'every':
        return $Closure(__every.func, this);
      case 'expand':
        return $Closure(__expand.func, this);
      case 'firstWhere':
        return $Closure(__firstWhere.func, this);
      case 'fold':
        return $Closure(__fold.func, this);
      case 'forEach':
        return $Closure(__forEach.func, this);
      case 'handleError':
        return $Closure(__handleError.func, this);
      case 'join':
        return $Closure(__join.func, this);
      case 'lastWhere':
        return $Closure(__lastWhere.func, this);
      case 'listen':
        return $Closure.withNamed(
          __listen.func,
          this,
          positionalParameterCount: 1,
          namedParameters: const ['onError', 'onDone', 'cancelOnError'],
        );
      case 'map':
        return $Closure(__map.func, this);
      case 'toList':
        return $Closure(__toList.func, this);
      case 'toSet':
        return $Closure(__toSet.func, this);
      case 'take':
        return $Closure(__take.func, this);
      /*case 'pipe':
        return $Closure(__pipe.func, this);*/
      case 'reduce':
        return $Closure(__reduce.func, this);
      case 'singleWhere':
        return $Closure(__singleWhere.func, this);
      case 'skip':
        return $Closure(__skip.func, this);
      case 'skipWhile':
        return $Closure(__skipWhile.func, this);
      case 'takeWhile':
        return $Closure(__takeWhile.func, this);
      case 'timeout':
        return $Closure(__timeout.func, this);
      case 'transform':
        return $Closure(__transform.func, this);
      case 'where':
        return $Closure(__where.func, this);

      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  static const $Function __any = $Function(_any);

  static $Value _any(
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
        await $target.$value.any(
          (event) =>
              test.call(runtime, null, runtime.wrap(event), null, 1)!.$value
                  as bool,
        ),
      ))(),
      runtime: runtime,
      runtimeTypeId: $target._fixedFutureId(runtime, CoreTypes.bool),
    );
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
      runtime: runtime,
      runtimeTypeId: $target._typedStreamId(runtime),
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
      $target.$value.asyncExpand((event) {
        final stream = convert.call(
          runtime,
          null,
          runtime.wrapAlways(event, recursive: true),
          null,
          1,
        );
        return stream == null || stream is $null
            ? null
            : TypedInterop.stream(stream, runtime);
      }),
      runtime: runtime,
      runtimeTypeId: $target._typedStreamId(
        runtime,
        runtime.typedCallbackReturnType(convert, unwrap: CoreTypes.stream),
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
      runtime: runtime,
      runtimeTypeId: $target._typedStreamId(
        runtime,
        runtime.typedCallbackReturnType(convert, unwrap: CoreTypes.future),
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
    return $Stream.wrap($target.$value.cast(), runtime: runtime);
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
      runtime: runtime,
      runtimeTypeId: $target._fixedFutureId(runtime, CoreTypes.bool),
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
    return $Stream.wrap(
      $target.$value.distinct(),
      runtime: runtime,
      runtimeTypeId: $target._typedStreamId(runtime),
    );
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
      runtime: runtime,
      runtimeTypeId: $target._typedFutureId(runtime),
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
              test.call(runtime, null, runtime.wrap(event), null, 1)!.$value as bool,
        ),
      ))(),
      runtime: runtime,
      runtimeTypeId: $target._fixedFutureId(runtime, CoreTypes.bool),
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
      runtime: runtime,
      runtimeTypeId: $target._typedStreamId(
        runtime,
        runtime.typedCallbackReturnType(convert, unwrap: CoreTypes.iterable),
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
        (event) => test.call(runtime, null, event, null, 1)!.$value as bool,
      ))(),
      runtime: runtime,
      runtimeTypeId: $target._typedFutureId(runtime),
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
      runtime: runtime,
      runtimeTypeId: $target._typedFutureId(runtime),
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
      $target.$value.handleError((Object error, StackTrace trace) {
        $callError(runtime, onError, error, trace);
      }),
      runtime: runtime,
      runtimeTypeId: $target._typedStreamId(runtime),
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
    final $target = target! as $Stream;
    final separator = (r as $Value?)?.$value ?? "";
    return $Future.wrap(
      (() async => $String(await $target.$value.join(separator)))(),
      runtime: runtime,
      runtimeTypeId: $target._fixedFutureId(runtime, CoreTypes.string),
    );
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
        (event) => test.call(runtime, null, event, null, 1)!.$value as bool,
      ))(),
      runtime: runtime,
      runtimeTypeId: $target._typedFutureId(runtime),
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
    final onData = r == null || r is $null ? null : r as EvalCallable;
    final onError = s == null || s is $null ? null : s as EvalCallable;
    final done = c is List && c.isNotEmpty ? c[0] : null;
    final onDone = done == null || done is $null ? null : done as EvalCallable;
    final cancel = c is List && c.length > 1 ? c[1] : null;
    final cancelOnError = cancel == null || cancel is $null
        ? null
        : cancel as $bool;
    return $StreamSubscription.wrap(
      $target.$value.listen(
        onData == null
            ? null
            : (event) {
                onData.call(runtime, null, runtime.wrap(event), null, 1);
              },
        onDone: () {
          onDone?.call(runtime, null, null, null, 0);
        },
        onError: onError == null
            ? null
            : (Object error, StackTrace trace) {
                $callError(runtime, onError, error, trace);
              },
        cancelOnError: cancelOnError?.$value,
      ),
    );
  }

  /// Invokes a guest error handler with its supported arity.
  static void $callError(
    Runtime runtime,
    EvalCallable handler,
    Object error,
    StackTrace trace,
  ) {
    final callable = handler is TypedCheckedFunction
        ? handler.function
        : handler;
    final twoArgs =
        callable is TypedClosure && callable.descriptor.accepts(2, const []) ||
        callable is $Closure && callable.positionalParameterCount == 2;
    handler.call(
      runtime,
      null,
      runtime.wrapAlways(error),
      twoArgs ? $StackTrace.wrap(trace) : null,
      twoArgs ? 2 : 1,
    );
  }

  static const $Function __map = $Function(_map);

  static const $Function __toList = $Function(_toList);

  static $Value _toList(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $target = target as $Stream;
    final elementT = $target._elementType(runtime);
    final listId = elementT == null
        ? null
        : runtime.internParameterizedType(CoreTypes.list, [elementT]);
    return $Future.wrap(
      $target.$value.toList().then(
        // The host list is List<Object?> — stamp it `List<T>` so a typed
        // `Future<List<T>>` receiver sees the declared element type.
        (values) => listId == null
            ? runtime.wrap(values, recursive: true)
            : TypedHostCollections.box(
                values,
                runtime,
                runtimeTypeId: listId,
              ),
      ),
      runtime: runtime,
      runtimeTypeId: $target._typedFutureId(runtime, [CoreTypes.list]),
    );
  }

  static const $Function __toSet = $Function(_toSet);

  static $Value _toSet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $target = target as $Stream;
    final elementT = $target._elementType(runtime);
    final setId = elementT == null
        ? null
        : runtime.internParameterizedType(CoreTypes.set, [elementT]);
    return $Future.wrap(
      $target.$value.toSet().then(
        (values) => setId == null
            ? runtime.wrap(values, recursive: true)
            : TypedHostCollections.box(
                values,
                runtime,
                runtimeTypeId: setId,
              ),
      ),
      runtime: runtime,
      runtimeTypeId: $target._typedFutureId(runtime, [CoreTypes.set]),
    );
  }

  static const $Function __take = $Function(_take);

  static $Value _take(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $target = target as $Stream;
    return $Stream.wrap(
      $target.$value.take((r as $int).$value),
      runtime: runtime,
      runtimeTypeId: $target._typedStreamId(runtime),
    );
  }

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
      runtime: runtime,
      runtimeTypeId: $target._typedStreamId(
        runtime,
        runtime.typedCallbackReturnType(convert),
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
      runtime: runtime,
      runtimeTypeId: $target._typedFutureId(runtime),
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
        (event) => test.call(runtime, null, event, null, 1)!.$value as bool,
      ))(),
      runtime: runtime,
      runtimeTypeId: $target._typedFutureId(runtime),
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
    return $Stream.wrap(
      $target.$value.skip(count.$value),
      runtime: runtime,
      runtimeTypeId: $target._typedStreamId(runtime),
    );
  }

  static const $Function __skipWhile = $Function(_skipWhile);

  static $Value _skipWhile(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $target = target as $Stream;
    final test = (r as $Value?) as EvalCallable;
    return $Stream.wrap(
      $target.$value.skipWhile(
        (event) => test.call(runtime, null, event, null, 1)!.$value as bool,
      ),
      runtime: runtime,
      runtimeTypeId: $target._typedStreamId(runtime),
    );
  }

  static const $Function __takeWhile = $Function(_takeWhile);

  static $Value _takeWhile(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $target = target as $Stream;
    final test = (r as $Value?) as EvalCallable;
    return $Stream.wrap(
      $target.$value.takeWhile(
        (event) => test.call(runtime, null, event, null, 1)!.$value as bool,
      ),
      runtime: runtime,
      runtimeTypeId: $target._typedStreamId(runtime),
    );
  }

  static const $Function __timeout = $Function(_timeout);

  static $Value _timeout(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $target = target as $Stream;
    final timeLimit = (r as $Value).$value as Duration;
    return $Stream.wrap(
      $target.$value.timeout(timeLimit),
      runtime: runtime,
      runtimeTypeId: $target._typedStreamId(runtime),
    );
  }

  static const $Function __where = $Function(_where);

  static $Value _where(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $target = target as $Stream;
    final test = (r as $Value?) as EvalCallable;
    return $Stream.wrap(
      $target.$value.where(
        (event) => test.call(runtime, null, event, null, 1)!.$value as bool,
      ),
      runtime: runtime,
      runtimeTypeId: $target._typedStreamId(runtime),
    );
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

  /// The instantiated type id (in [runtime]'s descriptor table), when the
  /// producing site knew the stream's element type.
  final int? runtimeTypeId;
  final Runtime? runtime;

  @override
  get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) {
    final data = Runtime.bridgeData[this];
    if (data != null) {
      return runtime.importRuntimeType(data.runtime, data.$runtimeType);
    }
    return runtimeTypeId == null
        ? runtime.lookupType($type.spec!)
        : runtime.importRuntimeType(
            this.runtime ?? runtime,
            runtimeTypeId!,
          );
  }

  /// This stream's `T` viewed through [runtime]'s descriptor table, or null
  /// when the instantiation is unknown.
  int? _elementType(Runtime runtime) =>
      runtime.runtimeTypeArgumentAt($getRuntimeType(runtime), 0);

  /// The `Future<...>` descriptor for member results built from `T`: an
  /// empty [wrap] gives `Future<T>`; `[CoreTypes.list]` gives
  /// `Future<List<T>>`. Null when `T` is unknown — the wrapper then reports
  /// the erased `Future<dynamic>` type as before.
  int? _typedFutureId(Runtime runtime, [List<BridgeTypeSpec> wrap = const []]) {
    var inner = _elementType(runtime);
    if (inner == null) return null;
    var resolved = inner;
    for (final spec in wrap) {
      resolved = runtime.internParameterizedType(spec, [resolved]);
    }
    return runtime.internParameterizedType(CoreTypes.future, [resolved]);
  }

  /// The `Future<[arg]>` descriptor for fixed-type member results.
  int _fixedFutureId(Runtime runtime, BridgeTypeSpec arg) => runtime
      .internParameterizedType(CoreTypes.future, [runtime.lookupType(arg)]);

  /// The `Stream<...>` descriptor for member results: preserves this
  /// stream's `T`, or uses [elementTypeId] for transforming members.
  int? _typedStreamId(Runtime runtime, [int? elementTypeId]) {
    final t = elementTypeId ?? _elementType(runtime);
    return t == null
        ? null
        : runtime.internParameterizedType(CoreTypes.stream, [t]);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {}
}
