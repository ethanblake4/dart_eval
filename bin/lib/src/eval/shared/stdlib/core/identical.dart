import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';

void configureIdenticalForCompile(BridgeDeclarationRegistry registry) {
  registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
      'dart:core',
      'identical',
      BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [
            BridgeParameter(
                'a',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                    nullable: true),
                false),
            BridgeParameter(
                'b',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                    nullable: true),
                false)
          ],
          namedParams: [])));
}

void configureIdenticalForRuntime(Runtime runtime) {
  runtime.registerBridgeFunc(
      'dart:core', 'identical', const _$identical().call);
}

class _$identical implements EvalCallable {
  const _$identical();

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return $bool(identical(args[0]?.$value, args[1]?.$value));
  }
}
