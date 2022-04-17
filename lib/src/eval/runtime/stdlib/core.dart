import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration/function.dart';
import 'package:dart_eval/src/eval/bridge/declaration/type.dart';
import 'package:dart_eval/src/eval/runtime/stdlib/core/duration.dart';
import 'package:dart_eval/src/eval/runtime/stdlib/core/future.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

void configureCoreForCompile(Compiler compiler) {
  compiler.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
      'dart:core',
      'print',
      BridgeFunctionDescriptor(BridgeTypeAnnotation(BridgeTypeReference.type(RuntimeTypes.voidType, []), false), {}, [
        BridgeParameter(
            'object', BridgeTypeAnnotation(BridgeTypeReference.type(RuntimeTypes.objectType, []), true), false)
      ], {})));

  $Future.configureForCompile(compiler);
  $Duration.configureForCompile(compiler);
}

void configureCoreForRuntime(Runtime runtime) {
  runtime.registerBridgeFunc('dart:core', 'print', $Function((rt, target, args) {
    print(args[0]!.$value);
  }));

  $Duration.configureForRuntime(runtime);
  $Future.configureForRuntime(runtime);
}
