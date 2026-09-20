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

import 'package:dart_eval/stdlib/core.dart'
    hide
        $Duration,
        $DateTime,
        $Iterator,
        $Comparable,
        $Sink,
        $StackTrace,
        $StringBuffer,
        $Symbol,
        $MapEntry,
        $Stopwatch,
        $Error,
        $TypeError,
        $NoSuchMethodError,
        $RangeError,
        $AssertionError,
        $ArgumentError,
        $StateError,
        $UnsupportedError,
        $UnimplementedError,
        $Invocation,
        $Exception,
        $FormatException,
        $Uri,
        $Pattern,
        $Match,
        $RegExp,
        $RegExpMatch,
        $StringSink;

/// dart_eval wrapper binding for [Exception]
class $Exception implements Exception, $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Exception.',
      $Exception.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Exception]
  static const $spec = BridgeTypeSpec('dart:core', 'Exception');

  /// Compile-time type declaration of [$Exception]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Exception]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'message',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {},
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Exception.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Exception.wrap(Exception((r is $Value ? r : null)?.$reified));
  }

  final $Instance _superclass;

  @override
  final Exception $value;

  @override
  Exception get $reified => $value;

  /// Wrap a [Exception] in a [$Exception]
  $Exception.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [FormatException]
class $FormatException implements FormatException, $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'FormatException.',
      $FormatException.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$FormatException]
  static const $spec = BridgeTypeSpec('dart:core', 'FormatException');

  /// Compile-time type declaration of [$FormatException]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$FormatException]
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
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
            ),

            BridgeParameter(
              'source',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              true,
            ),

            BridgeParameter(
              'offset',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
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
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: false,
      ),

      'source': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
        isStatic: false,
      ),

      'offset': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []), nullable: true),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [FormatException.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $FormatException.wrap(
      FormatException(
        (r is $Value ? r : null) == null ? "" : (r as $String).$value,
        (s is $Value ? s : null)?.$reified,
        (c is $Value ? c : null)?.$value,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final FormatException $value;

  @override
  FormatException get $reified => $value;

  /// Wrap a [FormatException] in a [$FormatException]
  $FormatException.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'message':
        final _message = $value.message;
        return $String(_message);
      case 'source':
        final _source = $value.source;
        return runtime.wrapAlways(_source, recursive: true);
      case 'offset':
        final _offset = $value.offset;
        return _offset == null ? const $null() : $int(_offset);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  String get message => $value.message;

  @override
  dynamic get source => $value.source;

  @override
  int? get offset => $value.offset;

  @override
  String toString() => $value.toString();
}
