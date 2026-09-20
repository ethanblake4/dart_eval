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

/// dart_eval wrapper binding for [Completer]
class $Completer<T> implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'Completer.',
      $Completer.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'Completer.sync',
      $Completer.$sync,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Completer]
  static const $spec = BridgeTypeSpec('dart:async', 'Completer');

  /// Compile-time type declaration of [$Completer]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Completer]
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
        isFactory: true,
      ),

      'sync': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'complete': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                ]),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'completeError': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'error',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              false,
            ),

            BridgeParameter(
              'stackTrace',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.stackTrace, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),
    },
    getters: {
      'future': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'isCompleted': BridgeMethodDef(
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

  /// Wrapper for the [Completer.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Completer.wrap(Completer());
  }

  /// Wrapper for the [Completer.sync] constructor
  static $Value? $sync(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Completer.wrap(Completer.sync());
  }

  final $Instance _superclass;

  @override
  final Completer<T> $value;

  @override
  Completer get $reified => $value;

  /// Wrap a [Completer] in a [$Completer]
  $Completer.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'future':
        final _future = $value.future;
        return $Future.wrap(
          _future.then((e) => runtime.wrapAlways(e, recursive: true)),
        );
      case 'isCompleted':
        final _isCompleted = $value.isCompleted;
        return $bool(_isCompleted);
      case 'complete':
        return __complete;

      case 'completeError':
        return __completeError;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __complete = $Function(_complete);
  static $Value? _complete(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Completer;
    self.$value.complete((r is $Value ? r : null)?.$value);
    return null;
  }

  static const $Function __completeError = $Function(_completeError);
  static $Value? _completeError(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Completer;
    self.$value.completeError(
      (r as $Value?)!.$reified,
      (s is $Value ? s : null)?.$value,
    );
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
