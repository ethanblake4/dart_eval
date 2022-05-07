import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

void configurePrintForCompile(Compiler compiler) {
  compiler.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
      'dart:core',
      'print',
      BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.voidType)),
          params: [BridgeParameter('object', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.objectType)), false)],
          namedParams: [])));
}

void configurePrintForRuntime(Runtime runtime) {
  runtime.registerBridgeFunc('dart:core', 'print', const _$print());
}

class _$print implements EvalCallable {
  const _$print();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    print(args[0]?.$value);
  }
}
