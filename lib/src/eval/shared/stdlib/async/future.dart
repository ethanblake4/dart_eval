// ignore_for_file: body_might_complete_normally_nullable

import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/future.dart';

/// dart_eval wrapper for [Completer]
class $Completer<T> implements Completer<T>, $Instance {
  $Completer.wrap(this.$value);

  static const _$type = BridgeTypeRef(BridgeTypeSpec('dart:async', 'Completer'), []);

  static const $declaration = BridgeClassDef(BridgeClassType(_$type),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(returns: BridgeTypeAnnotation(_$type), params: [], namedParams: []))
      },
      methods: {
        'complete': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.voidType)),
            params: [
              BridgeParameter('value', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.dynamicType)), false)
            ],
            namedParams: []))
      },
      getters: {
        'future': BridgeMethodDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Future')))))
      },
      setters: {},
      fields: {},
      wrap: true);

  @override
  final Completer<T> $value;

  @override
  Completer<T> get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'complete':
        return const _$Completer_complete();
      case 'future':
        return const _$Completer_future();
    }
  }

  @override
  int get $runtimeType => throw UnimplementedError();

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError();
  }

  @override
  void complete([FutureOr<T>? value]) => $value.complete(value);

  @override
  void completeError(Object error, [StackTrace? stackTrace]) => $value.completeError(error, stackTrace);

  @override
  Future<T> get future => $value.future;

  @override
  bool get isCompleted => $value.isCompleted;
}

class $Completer_new implements EvalCallable {
  const $Completer_new();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Completer.wrap(Completer());
  }
}

class _$Completer_complete extends EvalFunction {
  const _$Completer_complete() : super();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    (target as $Completer).complete(args[0]);
  }

  @override
  int get $runtimeType => RuntimeTypes.functionType;
}

class _$Completer_future extends EvalFunction {
  const _$Completer_future() : super();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Future.wrap((target as $Completer).future);
  }

  @override
  int get $runtimeType => RuntimeTypes.functionType;
}
