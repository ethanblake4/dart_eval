import 'dart:math' as math;
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';
import 'math/point.dart';

const mathSource = '''
const double e = 2.718281828459045;
const double ln10 = 2.302585092994046;
const double ln2 = 0.6931471805599453;
const double log2e = 1.4426950408889634;
const double log10e = 0.4342944819032518;
const double pi = 3.1415926535897932;
const double sqrt1_2 = 0.7071067811865476;
const double sqrt2 = 1.4142135623730951;
T min<T extends num>(T a, T b) => a < b ? a : b;
T max<T extends num>(T a, T b) => a > b ? a : b;
''';

/// [EvalPlugin] for the dart:math library
class DartMathPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:math';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    $Point.configureForCompile(registry);
    registry.addSource(DartSource('dart:math', mathSource));
    registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
        'dart:math',
        'atan2',
        BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
            params: [
              BridgeParameter('a',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)), false),
              BridgeParameter('b',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)), false)
            ])));
    registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
        'dart:math',
        'pow',
        BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)),
            params: [
              BridgeParameter('x',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)), false),
              BridgeParameter('exponent',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)), false)
            ])));
    registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
        'dart:math',
        'cos',
        BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
            params: [
              BridgeParameter('radians',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)), false)
            ])));
    registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
        'dart:math',
        'sin',
        BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
            params: [
              BridgeParameter('radians',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)), false)
            ])));
    registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
        'dart:math',
        'tan',
        BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
            params: [
              BridgeParameter('radians',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)), false)
            ])));
    registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
        'dart:math',
        'acos',
        BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
            params: [
              BridgeParameter('x',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)), false)
            ])));
    registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
        'dart:math',
        'asin',
        BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
            params: [
              BridgeParameter('x',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)), false)
            ])));
    registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
        'dart:math',
        'atan',
        BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
            params: [
              BridgeParameter('x',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)), false)
            ])));
    registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
        'dart:math',
        'sqrt',
        BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
            params: [
              BridgeParameter('x',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)), false)
            ])));
    registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
        'dart:math',
        'exp',
        BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
            params: [
              BridgeParameter('x',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)), false)
            ])));
    registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
        'dart:math',
        'log',
        BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
            params: [
              BridgeParameter('x',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)), false)
            ])));
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $Point.configureForRuntime(runtime);
    runtime.registerBridgeFunc('dart:math', 'atan2', const _$atan2());
    runtime.registerBridgeFunc('dart:math', 'pow', const _$pow());
    runtime.registerBridgeFunc('dart:math', 'cos', const _$cos());
    runtime.registerBridgeFunc('dart:math', 'sin', const _$sin());
    runtime.registerBridgeFunc('dart:math', 'tan', const _$tan());
    runtime.registerBridgeFunc('dart:math', 'acos', const _$acos());
    runtime.registerBridgeFunc('dart:math', 'asin', const _$asin());
    runtime.registerBridgeFunc('dart:math', 'atan', const _$atan());
    runtime.registerBridgeFunc('dart:math', 'sqrt', const _$sqrt());
    runtime.registerBridgeFunc('dart:math', 'exp', const _$exp());
    runtime.registerBridgeFunc('dart:math', 'log', const _$log());
  }
}

class _$atan2 implements EvalCallable {
  const _$atan2();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $double(math.atan2(args[0]?.$value, args[1]?.$value));
  }
}

class _$pow implements EvalCallable {
  const _$pow();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $num(math.pow(args[0]?.$value, args[1]?.$value));
  }
}

class _$cos implements EvalCallable {
  const _$cos();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $double(math.cos(args[0]?.$value));
  }
}

class _$sin implements EvalCallable {
  const _$sin();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $double(math.sin(args[0]?.$value));
  }
}

class _$tan implements EvalCallable {
  const _$tan();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $double(math.tan(args[0]?.$value));
  }
}

class _$acos implements EvalCallable {
  const _$acos();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $double(math.acos(args[0]?.$value));
  }
}

class _$asin implements EvalCallable {
  const _$asin();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $double(math.asin(args[0]?.$value));
  }
}

class _$atan implements EvalCallable {
  const _$atan();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $double(math.atan(args[0]?.$value));
  }
}

class _$sqrt implements EvalCallable {
  const _$sqrt();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $double(math.sqrt(args[0]?.$value));
  }
}

class _$exp implements EvalCallable {
  const _$exp();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $double(math.exp(args[0]?.$value));
  }
}

class _$log implements EvalCallable {
  const _$log();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $double(math.log(args[0]?.$value));
  }
}
