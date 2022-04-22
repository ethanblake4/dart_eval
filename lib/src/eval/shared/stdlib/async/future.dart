import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

class $Completer<T> implements Completer<T>, $Instance {
  static void configureForCompile(Compiler compiler) {
    compiler.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        'dart:async', 'Completer.', const _$Completer_new());
  }

  $Completer.wrap(this.$value);

  static const _$type = BridgeTypeReference.unresolved(
      BridgeUnresolvedTypeReference('dart:async', 'Completer'), []);

  static const $declaration =
      BridgeClassDeclaration(_$type, isAbstract: false, constructors: {
    '': BridgeConstructorDeclaration(
        false,
        BridgeFunctionDescriptor(
            BridgeTypeAnnotation(_$type, false), {}, [], {}))
  }, methods: {
    'complete': BridgeMethodDeclaration(
        false,
        BridgeFunctionDescriptor(
            BridgeTypeAnnotation(
                BridgeTypeReference.type(RuntimeTypes.voidType, []), false),
            {},
            [
              BridgeParameter(
                  'value',
                  BridgeTypeAnnotation(
                      BridgeTypeReference.type(RuntimeTypes.dynamicType, []),
                      false),
                  false)
            ],
            {}))
  }, getters: {}, setters: {}, fields: {});

  @override
  final Completer<T> $value;

  @override
  Completer<T> get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'complete':
        return const _$Completer_complete();
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
  void completeError(Object error, [StackTrace? stackTrace]) =>
      $value.completeError(error, stackTrace);

  @override
  Future<T> get future => $value.future;

  @override
  bool get isCompleted => $value.isCompleted;
}

class _$Completer_new implements EvalCallable {
  const _$Completer_new();

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
