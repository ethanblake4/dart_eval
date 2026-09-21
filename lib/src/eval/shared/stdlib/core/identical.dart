import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_instance.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/type.dart';

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

Object? _hostObject($Value? v) => v is TypedInstance ? v : v?.$value;

$Value? _identical(Runtime runtime, Object? r, Object? s, Object? c) {
  // $TypeImpl has no host Type instance to unwrap; type identity is
  // descriptor equality (handled by its ==, which also compares runtimes).
  if (r is $TypeImpl && s is $TypeImpl) return $bool(r == s);
  return $bool(
    identical(_hostObject(r as $Value?), _hostObject(s as $Value?)),
  );
}
