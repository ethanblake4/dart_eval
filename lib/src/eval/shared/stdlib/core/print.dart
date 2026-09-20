import 'package:dart_eval/dart_eval_bridge.dart';

void configurePrintForCompile(BridgeDeclarationRegistry registry) {
  registry.defineBridgeTopLevelFunction(
    BridgeFunctionDeclaration(
      'dart:core',
      'print',
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        params: [
          BridgeParameter(
            'object',
            BridgeTypeAnnotation(
              BridgeTypeRef(CoreTypes.object),
              nullable: true,
            ),
            false,
          ),
        ],
        namedParams: [],
      ),
    ),
  );
}

void configurePrintForRuntime(Runtime runtime) {
  runtime.registerBridgeFuncRegisters('dart:core', 'print', _print);
}

$Value? _print(Runtime runtime, Object? r, Object? s, Object? c) {
  print(runtime.valueToString(r as $Value?));
  return null;
}
