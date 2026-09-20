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

import 'dart:math';
import 'package:dart_eval/stdlib/core.dart' hide $Point, $Random;

/// dart_eval wrapper binding for [Random]
class $Random implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:math', 'Random.', $Random.$new);

    runtime.registerBridgeFuncRegisters(
      'dart:math',
      'Random.secure',
      $Random.$secure,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Random]
  static const $spec = BridgeTypeSpec('dart:math', 'Random');

  /// Compile-time type declaration of [$Random]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Random]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'seed',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),

      'secure': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'nextInt': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'max',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'nextDouble': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'nextBool': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
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

  /// Wrapper for the [Random.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Random.wrap(Random((r is $Value ? r : null)?.$value));
  }

  /// Wrapper for the [Random.secure] constructor
  static $Value? $secure(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Random.wrap(Random.secure());
  }

  final $Instance _superclass;

  @override
  final Random $value;

  @override
  Random get $reified => $value;

  /// Wrap a [Random] in a [$Random]
  $Random.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'nextInt':
        return __nextInt;

      case 'nextDouble':
        return __nextDouble;

      case 'nextBool':
        return __nextBool;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __nextInt = $Function(_nextInt);
  static $Value? _nextInt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Random;
    final result = self.$value.nextInt((r as $int).$value);
    return $int(result);
  }

  static const $Function __nextDouble = $Function(_nextDouble);
  static $Value? _nextDouble(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Random;
    final result = self.$value.nextDouble();
    return $double(result);
  }

  static const $Function __nextBool = $Function(_nextBool);
  static $Value? _nextBool(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Random;
    final result = self.$value.nextBool();
    return $bool(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
