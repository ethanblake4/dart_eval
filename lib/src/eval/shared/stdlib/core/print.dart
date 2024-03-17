import 'package:dart_eval/dart_eval_bridge.dart';

void configurePrintForCompile(BridgeDeclarationRegistry registry) {
  registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
      'dart:core',
      'print',
      BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [
            BridgeParameter(
                'object',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                    nullable: true),
                false)
          ],
          namedParams: [])));
}

void configurePrintForRuntime(Runtime runtime) {
  runtime.registerBridgeFunc('dart:core', 'print', const _$print().call);
}

class _$print implements EvalCallable {
  const _$print();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    print(runtime.valueToString(args[0]));
    return null;
  }
}
