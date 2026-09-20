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
import 'package:dart_eval/stdlib/core.dart'
    hide
        $Completer,
        $Timer,
        $Zone,
        $StreamSubscription,
        $StreamSink,
        $StreamTransformer,
        $StreamView,
        $StreamController;
import 'package:dart_eval/stdlib/async.dart'
    hide
        $Completer,
        $Timer,
        $Zone,
        $StreamSubscription,
        $StreamSink,
        $StreamTransformer,
        $StreamView,
        $StreamController;

/// dart_eval wrapper binding for [StreamSubscription]
class $StreamSubscription<T> implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {}

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$StreamSubscription]
  static const $spec = BridgeTypeSpec('dart:async', 'StreamSubscription');

  /// Compile-time type declaration of [$StreamSubscription]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$StreamSubscription]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      generics: {'T': BridgeGenericParam()},
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),
    },

    methods: {
      'cancel': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'onData': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              false,
            ),
          ],
        ),
      ),

      'onError': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'handleError',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
            ),
          ],
        ),
      ),

      'onDone': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'handleDone',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              false,
            ),
          ],
        ),
      ),

      'pause': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'resumeSignal',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.future, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
                ]),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'resume': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),
      ),

      'asFuture': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'E': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'futureValue',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E'), nullable: true),
              true,
            ),
          ],
        ),
      ),
    },
    getters: {
      'isPaused': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  final $Instance _superclass;

  @override
  final StreamSubscription<T> $value;

  @override
  StreamSubscription get $reified => $value;

  /// Wrap a [StreamSubscription] in a [$StreamSubscription]
  $StreamSubscription.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'isPaused':
        final _isPaused = $value.isPaused;
        return $bool(_isPaused);
      case 'cancel':
        return __cancel;

      case 'onData':
        return __onData;

      case 'onError':
        return __onError;

      case 'onDone':
        return __onDone;

      case 'pause':
        return __pause;

      case 'resume':
        return __resume;

      case 'asFuture':
        return __asFuture;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __cancel = $Function(_cancel);
  static $Value? _cancel(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamSubscription;
    final result = self.$value.cancel();
    return $Future.wrap(result.then((e) => null));
  }

  static const $Function __onData = $Function(_onData);
  static $Value? _onData(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamSubscription;
    self.$value.onData(
      (r as $Value?) == null || (r as $Value?) is $null
          ? null
          : (dynamic data) {
              ((r as $Value?)! as EvalCallable)(
                runtime,
                null,
                runtime.wrapAlways(data, recursive: true),
                null,
                1,
              );
            },
    );
    return null;
  }

  static const $Function __onError = $Function(_onError);
  static $Value? _onError(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamSubscription;
    self.$value.onError(
      (r as $Value?) == null || (r as $Value?) is $null
          ? null
          : (a0, [a1, a2]) {
              final _a0 = runtime.wrapAlways(a0);
              ((r as $Value?)! as EvalCallable)(
                runtime,
                null,
                _a0,
                a1 != null ? runtime.wrapAlways(a1) : null,
                a2 != null
                    ? [runtime.wrapAlways(a2)]
                    : a1 != null
                    ? 2
                    : 1,
              );
            },
    );
    return null;
  }

  static const $Function __onDone = $Function(_onDone);
  static $Value? _onDone(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamSubscription;
    self.$value.onDone(
      (r as $Value?) == null || (r as $Value?) is $null
          ? null
          : () {
              ((r as $Value?)! as EvalCallable)(runtime, null, null, null, 0);
            },
    );
    return null;
  }

  static const $Function __pause = $Function(_pause);
  static $Value? _pause(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamSubscription;
    self.$value.pause((r is $Value ? r : null)?.$value);
    return null;
  }

  static const $Function __resume = $Function(_resume);
  static $Value? _resume(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamSubscription;
    self.$value.resume();
    return null;
  }

  static const $Function __asFuture = $Function(_asFuture);
  static $Value? _asFuture(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamSubscription;
    final result = self.$value.asFuture((r is $Value ? r : null)?.$value);
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
