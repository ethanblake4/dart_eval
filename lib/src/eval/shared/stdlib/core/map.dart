part of 'collection.dart';

/// dart_eval wrapper for [Map]
class $Map<K, V> implements $Instance {
  /// Wrap a [Map] in a [$Map]
  $Map.wrap(this.$value);

  @override
  final Map<K, V> $value;

  late final $Instance _superclass = $Object($value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '[]':
        return __indexGet;
      case '[]=':
        return __indexSet;
      case 'length':
        return $int($value.length);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  static const $Function __indexGet = $Function(_indexGet);

  static $Value? _indexGet(Runtime runtime, $Value? target, List<$Value?> args) {
    final idx = args[0]!;
    return (target!.$value as Map)[idx.$value];
  }

  static const $Function __indexSet = $Function(_indexSet);

  static $Value? _indexSet(Runtime runtime, $Value? target, List<$Value?> args) {
    final idx = args[0]!;
    final value = args[1]!;
    return (target!.$value as Map)[idx.$value] = value;
  }

  @override
  Map get $reified => $value.map((k, v) => MapEntry(k is $Value ? k.$reified : k, v is $Value ? v.$reified : v));

  @override
  int $getRuntimeType(Runtime runtime) => RuntimeTypes.mapType;
}
