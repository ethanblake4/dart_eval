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

/// dart_eval wrapper binding for [Symbol]
class $Symbol implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:core', 'Symbol.', $Symbol.$new);

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Symbol.unaryMinus*g',
      $Symbol.$unaryMinus,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Symbol.empty*g',
      $Symbol.$empty,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Symbol]
  static const $spec = BridgeTypeSpec('dart:core', 'Symbol');

  /// Compile-time type declaration of [$Symbol]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Symbol]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {},
    getters: {},
    setters: {},
    fields: {
      'unaryMinus': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
        isStatic: true,
      ),

      'empty': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
        isStatic: true,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Symbol.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Symbol.wrap(Symbol((r as $String).$value));
  }

  /// Wrapper for the [Symbol.unaryMinus] getter
  static $Value? $unaryMinus(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Symbol.unaryMinus;
    return $Symbol.wrap(value);
  }

  /// Wrapper for the [Symbol.empty] getter
  static $Value? $empty(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Symbol.empty;
    return $Symbol.wrap(value);
  }

  final $Instance _superclass;

  @override
  final Symbol $value;

  @override
  Symbol get $reified => $value;

  /// Wrap a [Symbol] in a [$Symbol]
  $Symbol.wrap(this.$value) : _superclass = $Object($value);

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
