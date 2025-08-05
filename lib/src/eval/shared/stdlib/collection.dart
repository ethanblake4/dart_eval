import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/linked_hash_map.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/list_queue.dart';

/// [EvalPlugin] for the `dart:collection` library
class DartCollectionPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:collection';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($LinkedHashMap.$declaration);
    registry.defineBridgeClass($ListQueue.$declaration);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        'dart:collection', 'LinkedHashMap.', $LinkedHashMap.$new);
    runtime.registerBridgeFunc(
        'dart:collection', 'LinkedHashMap.identity', $LinkedHashMap.$identity);
    runtime.registerBridgeFunc(
        'dart:collection', 'LinkedHashMap.from', $LinkedHashMap.$from);
    runtime.registerBridgeFunc(
        'dart:collection', 'LinkedHashMap.of', $LinkedHashMap.$of);
    runtime.registerBridgeFunc('dart:collection', 'LinkedHashMap.fromIterable',
        $LinkedHashMap.$fromIterable);
    runtime.registerBridgeFunc('dart:collection', 'LinkedHashMap.fromIterables',
        $LinkedHashMap.$fromIterables);
  }
}
