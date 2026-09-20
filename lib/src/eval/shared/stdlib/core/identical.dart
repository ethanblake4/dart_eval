import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';

void configureIdenticalForCompile(BridgeDeclarationRegistry registry) {
  registry.defineBridgeTopLevelFunction(
    BridgeFunctionDeclaration(
      'dart:core',
      'identical',
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
        params: [
          BridgeParameter(
            'a',
            BridgeTypeAnnotation(
              BridgeTypeRef(CoreTypes.object),
              nullable: true,
            ),
            false,
          ),
          BridgeParameter(
            'b',
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

void configureIdenticalForRuntime(Runtime runtime) {
  runtime.registerBridgeFuncRegisters('dart:core', 'identical', _identical);
}

$Value? _identical(Runtime runtime, Object? r, Object? s, Object? c) {
  return $bool(identical((r as $Value?)?.$value, (s as $Value?)?.$value));
}
