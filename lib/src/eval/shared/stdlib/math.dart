import 'package:dart_eval/dart_eval_bridge.dart';
import 'math/functions.dart';
import 'math/point.dart';
import 'math/random.dart';

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
    $Random.configureForCompile(registry);
    registry.addSource(DartSource('dart:math', mathSource));
    registry.defineBridgeTopLevelFunction($atan2Fn.$declaration);
    registry.defineBridgeTopLevelFunction($powFn.$declaration);
    registry.defineBridgeTopLevelFunction($cosFn.$declaration);
    registry.defineBridgeTopLevelFunction($sinFn.$declaration);
    registry.defineBridgeTopLevelFunction($tanFn.$declaration);
    registry.defineBridgeTopLevelFunction($acosFn.$declaration);
    registry.defineBridgeTopLevelFunction($asinFn.$declaration);
    registry.defineBridgeTopLevelFunction($atanFn.$declaration);
    registry.defineBridgeTopLevelFunction($sqrtFn.$declaration);
    registry.defineBridgeTopLevelFunction($expFn.$declaration);
    registry.defineBridgeTopLevelFunction($logFn.$declaration);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $Point.configureForRuntime(runtime);
    $Random.configureForRuntime(runtime);
    $atan2Fn.configureForRuntime(runtime);
    $powFn.configureForRuntime(runtime);
    $cosFn.configureForRuntime(runtime);
    $sinFn.configureForRuntime(runtime);
    $tanFn.configureForRuntime(runtime);
    $acosFn.configureForRuntime(runtime);
    $asinFn.configureForRuntime(runtime);
    $atanFn.configureForRuntime(runtime);
    $sqrtFn.configureForRuntime(runtime);
    $expFn.configureForRuntime(runtime);
    $logFn.configureForRuntime(runtime);
  }
}
