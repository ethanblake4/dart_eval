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
import 'dart:core';

import 'package:dart_eval/stdlib/core.dart' hide $Point, $Random;

/// dart_eval wrapper binding for [Point]
class $Point<T extends num> implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:math', 'Point.', $Point.$new);
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Point]
  static const $spec = BridgeTypeSpec('dart:math', 'Point');

  /// Compile-time type declaration of [$Point]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Point]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, generics: {'T': BridgeGenericParam()}),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'x',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),

            BridgeParameter(
              'y',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {
      '+': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(MathTypes.point, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(MathTypes.point, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      '-': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(MathTypes.point, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(MathTypes.point, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      '*': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(MathTypes.point, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'factor',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
              false,
            ),
          ],
        ),
      ),

      'distanceTo': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(MathTypes.point, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'squaredDistanceTo': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(MathTypes.point, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),
    },
    getters: {
      'magnitude': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {
      'x': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
        isStatic: false,
      ),

      'y': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Point.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Point.wrap(Point((r as $Value?)!.$value, (s as $Value?)!.$value));
  }

  final $Instance _superclass;

  @override
  final Point<T> $value;

  @override
  Point get $reified => $value;

  /// Wrap a [Point] in a [$Point]
  $Point.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'x':
        final _x = $value.x;
        return runtime.wrapAlways(_x, recursive: true);
      case 'y':
        final _y = $value.y;
        return runtime.wrapAlways(_y, recursive: true);
      case 'magnitude':
        final _magnitude = $value.magnitude;
        return $double(_magnitude);
      case '+':
        return __operatorPlus;

      case '-':
        return __operatorMinus;

      case '*':
        return __operatorMul;

      case 'distanceTo':
        return __distanceTo;

      case 'squaredDistanceTo':
        return __squaredDistanceTo;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __operatorPlus = $Function(_operatorPlus);
  static $Value? _operatorPlus(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Point;
    final result = (self.$value + (r as $Value?)!.$value);
    return $Point.wrap(result);
  }

  static const $Function __operatorMinus = $Function(_operatorMinus);
  static $Value? _operatorMinus(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Point;
    final result = (self.$value - (r as $Value?)!.$value);
    return $Point.wrap(result);
  }

  static const $Function __operatorMul = $Function(_operatorMul);
  static $Value? _operatorMul(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Point;
    final result = (self.$value * (r as $num).$value);
    return $Point.wrap(result);
  }

  static const $Function __distanceTo = $Function(_distanceTo);
  static $Value? _distanceTo(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Point;
    final result = self.$value.distanceTo((r as $Value?)!.$value);
    return $double(result);
  }

  static const $Function __squaredDistanceTo = $Function(_squaredDistanceTo);
  static $Value? _squaredDistanceTo(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Point;
    final result = self.$value.squaredDistanceTo((r as $Value?)!.$value);
    return runtime.wrapAlways(result, recursive: true);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
