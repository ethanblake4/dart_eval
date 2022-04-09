import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration/function.dart';
import 'package:dart_eval/src/eval/bridge/declaration/type.dart';
import 'package:dart_eval/src/eval/runtime/override.dart';

void $print(String id, Object? object) => print(runtimeOverride(id) ?? object);

const _$print = $Function(_print);

$Value? _print(Runtime runtime, $Value? target, List<$Value?> args) {
  print(args[0]!.$reified);
}

$Function get$print(Runtime _) => _$print;

final printDescriptor = BridgeFunctionDescriptor(BridgeTypeAnnotation(BridgeTypeReference.ref('void', []), false), {},
    [BridgeParameter('object', BridgeTypeAnnotation(BridgeTypeReference.ref('Object', []), true), false)], {});
