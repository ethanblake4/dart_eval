import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/double_linked_queue.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/hash_map.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/hash_set.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/linked_hash_map.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/linked_hash_set.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/list_queue.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/queue.dart';

/// [EvalPlugin] for the `dart:collection` library
class DartCollectionPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:collection';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    $LinkedHashMap.configureForCompile(registry);
    $ListQueue.configureForCompile(registry);
    $Queue.configureForCompile(registry);
    $DoubleLinkedQueue.configureForCompile(registry);
    $HashMap.configureForCompile(registry);
    $HashSet.configureForCompile(registry);
    $LinkedHashSet.configureForCompile(registry);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $LinkedHashMap.configureForRuntime(runtime);
    $ListQueue.configureForRuntime(runtime);
    $Queue.configureForRuntime(runtime);
    $DoubleLinkedQueue.configureForRuntime(runtime);
    $HashMap.configureForRuntime(runtime);
    $HashSet.configureForRuntime(runtime);
    $LinkedHashSet.configureForRuntime(runtime);
  }
}
