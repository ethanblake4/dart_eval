// ignore_for_file: unused_import, unnecessary_import
// ignore_for_file: always_specify_types, avoid_redundant_argument_values
// ignore_for_file: sort_constructors_first
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_is_empty
// ignore_for_file: undefined_hidden_name
// ignore_for_file: dead_code, unused_local_variable
// ignore_for_file: unnecessary_type_check, unnecessary_non_null_assertion
// ignore_for_file: unnecessary_cast
// ignore_for_file: sdk_version_since
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: argument_type_not_assignable_to_error_handler
// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import 'dart:async';

import 'package:dart_eval/stdlib/async.dart'
    hide
        $Completer,
        $Timer,
        $Zone,
        $StreamSubscription,
        $StreamSink,
        $StreamIterator,
        $StreamTransformer,
        $StreamView,
        $StreamController;
import 'package:dart_eval/stdlib/core.dart'
    hide
        $Completer,
        $Timer,
        $Zone,
        $StreamSubscription,
        $StreamSink,
        $StreamIterator,
        $StreamTransformer,
        $StreamView,
        $StreamController;

/// dart_eval wrapper binding for [StreamTransformer]
class $StreamTransformer<S, T> implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'StreamTransformer.',
      $StreamTransformer.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'StreamTransformer.fromHandlers',
      $StreamTransformer.$fromHandlers,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'StreamTransformer.fromBind',
      $StreamTransformer.$fromBind,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'StreamTransformer.castFrom',
      $StreamTransformer.$castFrom,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$StreamTransformer]
  static const $spec = BridgeTypeSpec('dart:async', 'StreamTransformer');

  /// Compile-time type declaration of [$StreamTransformer]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$StreamTransformer]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      generics: {'S': BridgeGenericParam(), 'T': BridgeGenericParam()},
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'onListen',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(AsyncTypes.streamSubscription, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                      ]),
                    ),
                    params: [
                      BridgeParameter(
                        'stream',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.stream, [
                            BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                          ]),
                        ),
                        false,
                      ),

                      BridgeParameter(
                        'cancelOnError',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'fromHandlers': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'handleData',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'data',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                        false,
                      ),

                      BridgeParameter(
                        'sink',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.object, [
                            BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                          ]),
                        ),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'handleError',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'error',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.object, []),
                        ),
                        false,
                      ),

                      BridgeParameter(
                        'stackTrace',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.stackTrace, []),
                        ),
                        false,
                      ),

                      BridgeParameter(
                        'sink',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.object, [
                            BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                          ]),
                        ),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'handleDone',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'sink',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.object, [
                            BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                          ]),
                        ),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [],
        ),
        isFactory: true,
      ),

      'fromBind': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'bind',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.stream, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                      ]),
                    ),
                    params: [
                      BridgeParameter(
                        'null',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.stream, [
                            BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                          ]),
                        ),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'castFrom': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {
            'SS': BridgeGenericParam(),
            'ST': BridgeGenericParam(),
            'TS': BridgeGenericParam(),
            'TT': BridgeGenericParam(),
          },
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(AsyncTypes.streamTransformer, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('TS')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('TT')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(
                BridgeTypeRef(AsyncTypes.streamTransformer, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('SS')),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('ST')),
                ]),
              ),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'bind': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'stream',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.stream, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'cast': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'RS': BridgeGenericParam(), 'RT': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(AsyncTypes.streamTransformer, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('RS')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('RT')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [StreamTransformer.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $StreamTransformer.wrap(
      StreamTransformer((Stream<dynamic> stream, bool cancelOnError) {
        return ((r as $Value?)! as EvalCallable)(
          runtime,
          null,
          $Stream.wrap(
            stream.map((e) => runtime.wrapAlways(e, recursive: true)),
          ),
          $bool(cancelOnError),
          2,
        )?.$value;
      }),
    );
  }

  /// Wrapper for the [StreamTransformer.fromHandlers] constructor
  static $Value? $fromHandlers(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $StreamTransformer.wrap(
      StreamTransformer.fromHandlers(
        handleData:
            (r is $Value ? r : null) == null ||
                (r is $Value ? r : null) is $null
            ? null
            : (dynamic data, EventSink<dynamic> sink) {
                ((r is $Value ? r : null)! as EvalCallable?)?.call(
                  runtime,
                  null,
                  runtime.wrapAlways(data, recursive: true),
                  $Object(sink),
                  2,
                );
              },
        handleError:
            (s is $Value ? s : null) == null ||
                (s is $Value ? s : null) is $null
            ? null
            : (Object error, StackTrace stackTrace, EventSink<dynamic> sink) {
                ((s is $Value ? s : null)! as EvalCallable?)?.call(
                  runtime,
                  null,
                  $Object(error),
                  $StackTrace.wrap(stackTrace),
                  [$Object(sink)],
                );
              },
        handleDone:
            (c is $Value ? c : null) == null ||
                (c is $Value ? c : null) is $null
            ? null
            : (EventSink<dynamic> sink) {
                ((c is $Value ? c : null)! as EvalCallable?)?.call(
                  runtime,
                  null,
                  $Object(sink),
                  null,
                  1,
                );
              },
      ),
    );
  }

  /// Wrapper for the [StreamTransformer.fromBind] constructor
  static $Value? $fromBind(Runtime runtime, Object? r, Object? s, Object? c) {
    return $StreamTransformer.wrap(
      StreamTransformer.fromBind((Stream<dynamic> arg0) {
        return ((r as $Value?)! as EvalCallable)(
          runtime,
          null,
          $Stream.wrap(arg0.map((e) => runtime.wrapAlways(e, recursive: true))),
          null,
          1,
        )?.$value;
      }),
    );
  }

  /// Wrapper for the [StreamTransformer.castFrom] method
  static $Value? $castFrom(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = StreamTransformer.castFrom((r as $Value?)!.$value);
    return $StreamTransformer.wrap(value);
  }

  final $Instance _superclass;

  @override
  final StreamTransformer<S, T> $value;

  @override
  StreamTransformer get $reified => $value;

  /// Wrap a [StreamTransformer] in a [$StreamTransformer]
  $StreamTransformer.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'bind':
        return $Closure(__bind.func, this);

      case 'cast':
        return $Closure(__cast.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __bind = $Function(_bind);
  static $Value? _bind(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamTransformer;
    final result = self.$value.bind((r as $Value?)!.$value);
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __cast = $Function(_cast);
  static $Value? _cast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamTransformer;
    final result = self.$value.cast();
    return $StreamTransformer.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
