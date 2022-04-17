import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration/class.dart';
import 'package:dart_eval/src/eval/bridge/declaration/function.dart';
import 'package:dart_eval/src/eval/bridge/declaration/type.dart';
import 'package:dart_eval/src/eval/runtime/stdlib/core/duration.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

class $Future<T> implements Future<T>, $Instance {
  static void configureForCompile(Compiler compiler) {
    compiler.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:core', 'Future.delayed', $Function((runtime, target, args) {
      return $Future.wrap(Future.delayed(args[0]!.$value), (value) => $null());
    }));
  }

  static const _$type = BridgeTypeReference.unresolved(BridgeUnresolvedTypeReference('dart:core', 'Future'), []);

  static const $declaration = BridgeClassDeclaration(_$type, isAbstract: true, constructors: {
    'delayed': BridgeConstructorDeclaration(
        false,
        BridgeFunctionDescriptor(BridgeTypeAnnotation(_$type, false), {},
            [BridgeParameter('duration', BridgeTypeAnnotation($Duration.$type, false), false)], {}))
  }, methods: {
    'then': BridgeMethodDeclaration(
        false,
        BridgeFunctionDescriptor(BridgeTypeAnnotation(_$type, false), {}, [
          BridgeParameter(
              'onValue', BridgeTypeAnnotation(BridgeTypeReference.type(RuntimeTypes.functionType, []), false), false)
        ], {}))
  }, getters: {}, setters: {}, fields: {});

  $Future.wrap(this.$value, this.$typeMapper);

  @override
  final Future<T> $value;

  final $Value? Function(T value) $typeMapper;

  @override
  Future<T> get $reified => $value;

  final $Instance $super = const $Object();

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'then':
        return __then;
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {}

  @override
  int get $runtimeType => RuntimeTypes.futureType;

  @override
  Stream<T> asStream() => $value.asStream();

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) => $value.catchError(onError, test: test);

  static const $Function __then = $Function(_then);

  static $Value? _then(Runtime runtime, $Value? target, List<$Value?> args) {
    final $t = target as $Future;
    return $Future.wrap(
        ($t.$value).then((value) => (args[0] as EvalFunction)(runtime, target, [$t.$typeMapper(value)])),
        $t.$typeMapper);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) =>
      $value.then(onValue, onError: onError);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      $value.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) => $value.whenComplete(action);
}
