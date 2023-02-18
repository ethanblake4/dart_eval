import 'dart:math';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';

/// dart_eval wrapper for [Point]
class $Point implements Point, $Instance {
  /// Configure this class for compilation in a [Compiler].
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Configure this class for runtime in a [Runtime].
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:math', 'Point.', const _$Point_new());
  }

  static const _$type = BridgeTypeRef(BridgeTypeSpec('dart:math', 'Point'));

  /// The bridge class definition for this class.
  static const $declaration = BridgeClassDef(BridgeClassType(_$type, isAbstract: true),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(returns: BridgeTypeAnnotation(_$type), params: [
          BridgeParameter('x', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.numType)), false),
          BridgeParameter('y', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.numType)), false)
        ], namedParams: []))
      },
      methods: {
        '*': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(_$type),
            params: [BridgeParameter('factor', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.numType)), false)],
            namedParams: [])),
        '+': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(_$type),
            params: [BridgeParameter('other', BridgeTypeAnnotation(_$type), false)],
            namedParams: [])),
        '-': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(_$type),
            params: [BridgeParameter('other', BridgeTypeAnnotation(_$type), false)],
            namedParams: [])),
        'squaredDistanceTo': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.numType)),
            params: [BridgeParameter('other', BridgeTypeAnnotation(_$type), false)],
            namedParams: [])),
        'distanceTo': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.doubleType)),
            params: [BridgeParameter('other', BridgeTypeAnnotation(_$type), false)],
            namedParams: [])),
      },
      getters: {
        'x':
            BridgeMethodDef(BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.numType)))),
        'y':
            BridgeMethodDef(BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.numType)))),
        'magnitude': BridgeMethodDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.doubleType)))),
      },
      setters: {},
      fields: {},
      wrap: true);

  /// Create a [$Point] wrapping a [Point].
  $Point.wrap(this.$value) : _superclass = $Object($value);

  @override
  final Point $value;

  @override
  Point get $reified => $value;

  final $Instance _superclass;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '+':
        return __add;
      case '-':
        return __subtract;
      case '*':
        return __multiply;
      case 'squaredDistanceTo':
        return __squaredDistanceTo;
      case 'distanceTo':
        return __distanceTo;
      case 'x':
        return $num($value.x);
      case 'y':
        return $num($value.y);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  static const $Function __add = $Function(_add);

  static $Value? _add(Runtime runtime, $Value? target, List<$Value?> args) {
    final $t = target as $Point;
    return $Point.wrap(($t.$value) + (args[0] as $Point).$value);
  }

  static const $Function __squaredDistanceTo = $Function(_squaredDistanceTo);

  static $Value? _squaredDistanceTo(Runtime runtime, $Value? target, List<$Value?> args) {
    final $t = target as $Point;
    return $num(($t.$value).squaredDistanceTo((args[0] as $Point).$value));
  }

  static const $Function __multiply = $Function(_multiply);

  static $Value? _multiply(Runtime runtime, $Value? target, List<$Value?> args) {
    final $t = target as $Point;
    return $Point.wrap(($t.$value) * (args[0] as $num).$value);
  }

  static const $Function __subtract = $Function(_subtract);

  static $Value? _subtract(Runtime runtime, $Value? target, List<$Value?> args) {
    final $t = target as $Point;
    return $Point.wrap(($t.$value) - (args[0] as $Point).$value);
  }

  static const $Function __distanceTo = $Function(_distanceTo);

  static $Value? _distanceTo(Runtime runtime, $Value? target, List<$Value?> args) {
    final $t = target as $Point;
    return $double(($t.$value).distanceTo((args[0] as $Point).$value));
  }

  @override
  int get $runtimeType => throw UnimplementedError();

  @override
  Point<num> operator *(num factor) => $value * factor;

  @override
  Point<num> operator +(Point<num> other) => $value + other;

  @override
  Point<num> operator -(Point<num> other) => $value - other;

  @override
  double distanceTo(Point<num> other) => $value.distanceTo(other);

  @override
  double get magnitude => $value.magnitude;

  @override
  num squaredDistanceTo(Point<num> other) => $value.squaredDistanceTo(other);

  @override
  num get x => $value.x;

  @override
  num get y => $value.y;
}

class _$Point_new implements EvalCallable {
  const _$Point_new();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Point.wrap(Point(args[0]!.$value, args[1]!.$value));
  }
}
