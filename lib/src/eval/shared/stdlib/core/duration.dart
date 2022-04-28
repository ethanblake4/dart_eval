import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/compiler.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

class $Duration implements Duration, $Instance {
  static void configureForCompile(Compiler compiler) {
    compiler.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:core', 'Duration.', const _$Duration_new());
  }

  static const $type = BridgeTypeRef.spec(BridgeTypeSpec('dart:core', 'Duration'));

  static const $declaration = BridgeClassDef(BridgeClassType($type), constructors: {
    '': BridgeConstructorDef(BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [], namedParams: [
      BridgeParameter('days', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType), nullable: true), true),
      BridgeParameter('hours', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType), nullable: true), true),
      BridgeParameter('minutes', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType), nullable: true), true),
      BridgeParameter('seconds', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType), nullable: true), true),
      BridgeParameter(
          'milliseconds', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType), nullable: true), true),
      BridgeParameter(
          'microseconds', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType), nullable: true), true),
    ]))
  }, methods: {
    '*': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation($type),
        params: [BridgeParameter('factor', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.numType)), false)],
        namedParams: []))
  }, getters: {}, setters: {}, fields: {});

  $Duration.wrap(this.$value);

  @override
  final Duration $value;

  @override
  Duration get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    throw UnimplementedError();
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError();
  }

  @override
  int get $runtimeType => RuntimeTypes.durationType;

  @override
  Duration operator *(num factor) => $value * factor;

  @override
  Duration operator +(Duration other) => $value + other;

  @override
  Duration operator -() => -$value;

  @override
  Duration operator -(Duration other) => $value - other;

  @override
  bool operator <(Duration other) => $value < other;

  @override
  bool operator <=(Duration other) => $value <= other;

  @override
  bool operator >(Duration other) => $value > other;

  @override
  bool operator >=(Duration other) => $value >= other;

  @override
  Duration abs() => $value.abs();

  @override
  int compareTo(Duration other) => $value.compareTo(other);

  @override
  int get inDays => $value.inDays;

  @override
  int get inHours => $value.inHours;

  @override
  int get inMicroseconds => $value.inMicroseconds;

  @override
  int get inMilliseconds => $value.inMilliseconds;

  @override
  int get inMinutes => $value.inMinutes;

  @override
  int get inSeconds => $value.inSeconds;

  @override
  bool get isNegative => $value.isNegative;

  @override
  Duration operator ~/(int quotient) => $value ~/ quotient;
}

class _$Duration_new implements EvalCallable {
  const _$Duration_new();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Duration.wrap(Duration(
        days: args[0]?.$value ?? 0,
        hours: args[1]?.$value ?? 0,
        minutes: args[2]?.$value ?? 0,
        seconds: args[3]?.$value ?? 0,
        milliseconds: args[4]?.$value ?? 0,
        microseconds: args[5]?.$value ?? 0));
  }
}
