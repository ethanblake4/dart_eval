// ignore_for_file: unused_import, unnecessary_import
// ignore_for_file: always_specify_types, avoid_redundant_argument_values
// ignore_for_file: sort_constructors_first
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_is_empty
// ignore_for_file: undefined_hidden_name
// ignore_for_file: dead_code, unused_local_variable
// ignore_for_file: unnecessary_type_check, unnecessary_non_null_assertion
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

/// dart_eval wrapper binding for [Timer]
class $Timer implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:async', 'Timer.', $Timer.$new);

    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'Timer.periodic',
      $Timer.$periodic,
    );

    runtime.registerBridgeFuncRegisters('dart:async', 'Timer.run', $Timer.$run);
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Timer]
  static const $spec = BridgeTypeSpec('dart:async', 'Timer');

  /// Compile-time type declaration of [$Timer]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Timer]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'duration',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
              false,
            ),

            BridgeParameter(
              'callback',
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
              ),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'periodic': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'duration',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
              false,
            ),

            BridgeParameter(
              'callback',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'timer',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(AsyncTypes.timer, []),
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
      'run': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'callback',
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
              ),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'cancel': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),
      ),
    },
    getters: {
      'tick': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isActive': BridgeMethodDef(
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

  /// Wrapper for the [Timer.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Timer.wrap(
      Timer((r as $Value?)!.$value, () {
        ((s as $Value?)! as EvalCallable)(runtime, null, []);
      }),
    );
  }

  /// Wrapper for the [Timer.periodic] constructor
  static $Value? $periodic(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Timer.wrap(
      Timer.periodic((r as $Value?)!.$value, (Timer timer) {
        ((s as $Value?)! as EvalCallable)(runtime, null, [$Timer.wrap(timer)]);
      }),
    );
  }

  /// Wrapper for the [Timer.run] method
  static $Value? $run(Runtime runtime, Object? r, Object? s, Object? c) {
    Timer.run(() {
      ((r as $Value?)! as EvalCallable)(runtime, null, []);
    });
    return null;
  }

  final $Instance _superclass;

  @override
  final Timer $value;

  @override
  Timer get $reified => $value;

  /// Wrap a [Timer] in a [$Timer]
  $Timer.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'tick':
        final _tick = $value.tick;
        return $int(_tick);
      case 'isActive':
        final _isActive = $value.isActive;
        return $bool(_isActive);
      case 'cancel':
        return __cancel;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __cancel = $Function(_cancel);
  static $Value? _cancel(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $Timer;
    self.$value.cancel();
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
