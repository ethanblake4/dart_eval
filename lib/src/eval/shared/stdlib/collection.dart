import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/double_linked_queue.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/hash_map.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/hash_set.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/linked_hash_map.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/linked_hash_set.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/map_base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/list_queue.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/queue.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/typedefs.dart';

/// [EvalPlugin] for the `dart:collection` library
class DartCollectionPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:collection';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.addSource(
      DartSource('dart:collection', '''
      ${sdkTypedefsSource.stringSource}
      class UnmodifiableMapView<K, V> implements Map<K, V> {
        final Map<K, V> _map;
        UnmodifiableMapView(this._map);

        V? operator [](Object? key) => _map[key];
        Iterable<K> get keys => _map.keys;
        Iterable<V> get values => _map.values;
        Iterable<MapEntry<K, V>> get entries => _map.entries;
        int get length => _map.length;
        bool get isEmpty => _map.isEmpty;
        bool get isNotEmpty => _map.isNotEmpty;
        bool containsKey(Object? key) => _map.containsKey(key);
        bool containsValue(Object? value) => _map.containsValue(value);
        void forEach(void Function(K, V) action) => _map.forEach(action);
      }
    '''),
    );
    $LinkedHashMap.configureForCompile(registry);
    $ListQueue.configureForCompile(registry);
    $Queue.configureForCompile(registry);
    $DoubleLinkedQueue.configureForCompile(registry);
    $HashMap.configureForCompile(registry);
    $HashSet.configureForCompile(registry);
    $LinkedHashSet.configureForCompile(registry);
    $MapBase.configureForCompile(registry);
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
    $MapBase.configureForRuntime(runtime);
  }
}
