import 'dart:math';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval bimodal wrapper for [Random]
class $Random implements Random, $Instance {
  /// Configure the [$Random] wrapper for use in a [Runtime]
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Random.', __$Random$new.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Random.secure', __$Random$secure.call,
        isBridge: false);
  }

  late final $Instance _superclass = $Object($value);

  static const $type = BridgeTypeRef(MathTypes.random);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      $extends: null,
      $implements: [],
      isAbstract: true,
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
                'seed',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                    nullable: true),
                true)
          ],
          namedParams: [],
        ),
        isFactory: true,
      ),
      'secure': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [],
          namedParams: [],
        ),
        isFactory: true,
      )
    },
    fields: {},
    methods: {
      'nextInt': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'max',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'nextDouble': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'nextBool': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
    },
    getters: {},
    setters: {},
    bridge: false,
    wrap: true,
  );

  /// Wrap an [Random] in an [$Random]
  $Random.wrap(this.$value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'nextInt':
        return __$nextInt;
      case 'nextDouble':
        return __$nextDouble;
      case 'nextBool':
        return __$nextBool;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  Random get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) =>
      _superclass.$setProperty(runtime, identifier, value);

  @override
  final Random $value;

  @override
  int nextInt(int max) => $value.nextInt(max);
  static const __$nextInt = $Function(_$nextInt);
  static $Value? _$nextInt(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Random;
    final max = args[0]?.$value as int;
    final $result = $this.nextInt(max);
    return $int($result);
  }

  @override
  double nextDouble() => $value.nextDouble();
  static const __$nextDouble = $Function(_$nextDouble);
  static $Value? _$nextDouble(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Random;
    final $result = $this.nextDouble();
    return $double($result);
  }

  @override
  bool nextBool() => $value.nextBool();
  static const __$nextBool = $Function(_$nextBool);
  static $Value? _$nextBool(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Random;
    final $result = $this.nextBool();
    return $bool($result);
  }

  static const __$Random$new = $Function(_$Random$new);
  static $Value? _$Random$new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final seed = args[0]?.$value as int?;
    return $Random.wrap(Random(seed));
  }

  static const __$Random$secure = $Function(_$Random$secure);
  static $Value? _$Random$secure(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $Random.wrap(Random.secure());
  }
}
