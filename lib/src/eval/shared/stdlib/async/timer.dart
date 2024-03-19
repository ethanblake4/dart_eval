import 'dart:async';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [Timer]
class $Timer implements $Instance {
  static const _$type = BridgeTypeRef(AsyncTypes.timer);

  static const $declaration = BridgeClassDef(BridgeClassType(_$type),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation(_$type), params: [
              BridgeParameter(
                  'duration',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration)),
                  false),
              BridgeParameter(
                  'callback',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                  false)
            ], namedParams: []),
            isFactory: true),
        'periodic': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation(_$type), params: [
          BridgeParameter('duration',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration)), false),
          BridgeParameter('callback',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)), false)
        ], namedParams: [])),
      },
      methods: {
        'run': BridgeMethodDef(
            BridgeFunctionDef(
                returns:
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
                params: [
                  BridgeParameter(
                      'callback',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                      false)
                ],
                namedParams: []),
            isStatic: true),
        'cancel': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)))),
      },
      getters: {
        'tick': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
        'isActive': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)))),
      },
      setters: {},
      fields: {},
      wrap: true);

  /// Create a new [Timer] with [args]
  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Timer.wrap(Timer(Duration(milliseconds: args[0]!.$value as int),
        () => (args[1]!.$value as EvalFunction).call(runtime, null, [])));
  }

  /// Create a new [Timer.periodic] with [args]
  static $Value? $periodic(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $Timer.wrap(Timer.periodic(
        Duration(milliseconds: args[0]!.$value as int),
        (timer) => (args[1]!.$value as EvalFunction)
            .call(runtime, null, [$Timer.wrap(timer)])));
  }

  /// Run a [Timer] with [args]
  static $Value? $run(Runtime runtime, $Value? target, List<$Value?> args) {
    Timer.run(() => (args[0]!.$value as EvalFunction).call(runtime, null, []));
    return null;
  }

  final $Instance _superclass;

  /// Wrap a [Timer] in a [$Timer]
  $Timer.wrap(this.$value) : _superclass = $Object($value);

  @override
  final Timer $value;

  @override
  Timer get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => throw UnimplementedError();

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'tick':
        return $int($value.tick);
      case 'isActive':
        return $bool($value.isActive);
      case 'cancel':
        return __$cancel;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __$cancel = $Function(_$cancel);

  static $Value? _$cancel(Runtime runtime, $Value? target, List<$Value?> args) {
    (target!.$value as Timer).cancel();
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
