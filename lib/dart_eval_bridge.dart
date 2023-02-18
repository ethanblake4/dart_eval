library dart_eval.bridge;

export 'src/eval/runtime/class.dart' hide $InstanceImpl;
export 'src/eval/runtime/declaration.dart';
export 'src/eval/bridge/declaration/class.dart';
export 'src/eval/bridge/declaration/enum.dart';
export 'src/eval/bridge/declaration/type.dart';
export 'src/eval/bridge/declaration/function.dart';
export 'src/eval/bridge/registry.dart';
export 'src/eval/bridge/serializer.dart';
export 'src/eval/runtime/override.dart' show runtimeOverride;
export 'src/eval/compiler/model/source.dart';
export 'src/eval/plugin.dart';
export 'src/eval/shared/types.dart' hide runtimeTypeMap, inverseRuntimeTypeMap;
export 'src/eval/runtime/function.dart' hide EvalFunctionPtr, EvalStaticFunctionPtr;
export 'src/eval/bridge/runtime_bridge.dart' show $Bridge, $BridgeField;
export 'src/eval/bridge/declaration.dart' show BridgeDeclaration;
export 'src/eval/compiler/builtins.dart' show EvalTypes;
