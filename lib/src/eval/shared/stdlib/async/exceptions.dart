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

import '../core/exceptions.dart';

import 'package:dart_eval/stdlib/core.dart'
    hide
        $Completer,
        $Timer,
        $TimeoutException,
        $AsyncError,
        $Zone,
        $StreamSubscription,
        $StreamSink,
        $EventSink,
        $StreamIterator,
        $StreamTransformer,
        $StreamTransformerBase,
        $StreamView,
        $StreamController;

import '../core/duration.dart';

import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

import '../core/stack_trace.dart';
import '../core/errors.dart';

/// dart_eval wrapper binding for [TimeoutException]
class $TimeoutException implements TimeoutException, $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'TimeoutException.',
      $TimeoutException.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$TimeoutException]
  static const $spec = BridgeTypeSpec('dart:async', 'TimeoutException');

  /// Compile-time type declaration of [$TimeoutException]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$TimeoutException]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [BridgeTypeRef(CoreTypes.exception, [])],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'message',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              false,
            ),

            BridgeParameter(
              'duration',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.duration, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {},
    getters: {},
    setters: {},
    fields: {
      'message': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.string, []),
          nullable: true,
        ),
        isStatic: false,
      ),

      'duration': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.duration, []),
          nullable: true,
        ),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [TimeoutException.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $TimeoutException.wrap(
      TimeoutException(
        (r as $Value?)!.$value,
        (s is $Value ? s : null)?.$value,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final TimeoutException $value;

  @override
  TimeoutException get $reified => $value;

  /// Wrap a [TimeoutException] in a [$TimeoutException]
  $TimeoutException.wrap(this.$value) : _superclass = $Exception.wrap($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'message':
        final _message = $value.message;
        return _message == null ? const $null() : $String(_message);
      case 'duration':
        final _duration = $value.duration;
        return _duration == null ? const $null() : $Duration.wrap(_duration);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  String? get message => $value.message;

  @override
  Duration? get duration => $value.duration;

  @override
  String toString() => $value.toString();
}

/// dart_eval wrapper binding for [AsyncError]
class $AsyncError implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'AsyncError.',
      $AsyncError.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'AsyncError.defaultStackTrace',
      $AsyncError.$defaultStackTrace,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$AsyncError]
  static const $spec = BridgeTypeSpec('dart:async', 'AsyncError');

  /// Compile-time type declaration of [$AsyncError]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$AsyncError]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, $implements: [BridgeTypeRef(CoreTypes.error, [])]),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
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
              false,
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {
      'defaultStackTrace': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stackTrace, []),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'error',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),
    },
    getters: {},
    setters: {},
    fields: {
      'error': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
        isStatic: false,
      ),

      'stackTrace': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stackTrace, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [AsyncError.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $AsyncError.wrap(
      AsyncError(
        TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object,
        (s as $Value?)!.$value,
      ),
    );
  }

  /// Wrapper for the [AsyncError.defaultStackTrace] method
  static $Value? $defaultStackTrace(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = AsyncError.defaultStackTrace(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object,
    );
    return $StackTrace.wrap(value);
  }

  final $Instance _superclass;

  @override
  final AsyncError $value;

  @override
  AsyncError get $reified => $value;

  /// Wrap a [AsyncError] in a [$AsyncError]
  $AsyncError.wrap(this.$value) : _superclass = $Error.wrap($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'error':
        final _error = $value.error;
        return $Object(_error);
      case 'stackTrace':
        final _stackTrace = $value.stackTrace;
        return $StackTrace.wrap(_stackTrace);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
