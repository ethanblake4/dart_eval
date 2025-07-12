import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// Converts a Dart list of generic type `T` into a `$List` of `$Value` by
/// applying a wrapping function to each element in the list.
$List<$Value> wrapList<T>(List<T> list, $Value Function(T element) wrap) {
  return $List.wrap([for (var e in list) wrap(e)]);
}

/// Converts a Dart list of nullable generic type `T` into a `$List` of `$Value?`
/// by applying a wrapping function to each non-null element and using `$null()` for null elements.
$List<$Value?> wrapNullableList<T>(
    List<T?> list, $Value Function(T element) wrap) {
  return $List.wrap([for (var e in list) e == null ? $null() : wrap(e)]);
}

/// Converts a Dart map with keys of type `K` and values of type `V` into a
/// `$Map` of `$Value` by applying a wrapping function to each entry in the map.
$Map<$Value, $Value> wrapMap<K, V>(
    Map<K, V> map, MapEntry<$Value, $Value> Function(K key, V value) wrap) {
  return $Map.wrap(map.map((key, value) => wrap(key, value)));
}
