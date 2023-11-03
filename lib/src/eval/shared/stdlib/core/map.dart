part of 'collection.dart';

/// dart_eval bimodal wrapper for [Map]
class $Map<K, V> implements Map<K, V>, $Instance {
  /// Wrap a [Map] in a [$Map]
  $Map.wrap(this.$value);

  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.map),
          generics: {'K': BridgeGenericParam(), 'V': BridgeGenericParam()}),
      constructors: {},
      methods: {
        /*'[]': BridgeMethodDef(
            BridgeFunctionDef(
                params: [
                  BridgeParameter(
                      'key',
                      BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.dynamic)), 
                      false),
                ],
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.dynamic))), 
            isStatic: false),
        '[]=': BridgeMethodDef(
            BridgeFunctionDef(
                params: [
                  BridgeParameter(
                      'key',
                      BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.dynamic)),
                      false),
                  BridgeParameter(
                      'value',
                      BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.dynamic)),
                      false),
                ],
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.dynamic))),
            isStatic: false),
        'length': BridgeMethodDef(
            BridgeFunctionDef(
                params: [],
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.intType))),
            isStatic: false),*/
      },
      getters: {
        'entries': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable))))
      },
      setters: {},
      fields: {},
      wrap: true);

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
      case 'entries':
        return $Iterable.wrap(entries.map((e) => $MapEntry.wrap(e)));
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  static const $Function __indexGet = $Function(_indexGet);

  static $Value? _indexGet(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final idx = args[0]!;
    final map = target!.$value as Map;
    if (map.values.first is $Value) {
      return map[idx];
    }
    return map[idx.$value];
  }

  static const $Function __indexSet = $Function(_indexSet);

  static $Value? _indexSet(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final idx = args[0]!;
    final value = args[1]!;
    return (target!.$value as Map)[idx.$value] = value;
  }

  @override
  Map get $reified => $value.map((k, v) =>
      MapEntry(k is $Value ? k.$reified : k, v is $Value ? v.$reified : v));

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.map);

  @override
  V? operator [](Object? key) {
    return $value[key];
  }

  @override
  void operator []=(K key, V value) {
    $value[key] = value;
  }

  @override
  void addAll(Map<K, V> other) => $value.addAll(other);

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) =>
      $value.addEntries(newEntries);

  @override
  Map<RK, RV> cast<RK, RV>() => $value.cast<RK, RV>();

  @override
  void clear() {
    return $value.clear();
  }

  @override
  bool containsKey(Object? key) {
    return $value.containsKey(key);
  }

  @override
  bool containsValue(Object? value) {
    return $value.containsValue(value);
  }

  @override
  Iterable<MapEntry<K, V>> get entries => $value.entries;

  @override
  void forEach(void Function(K key, V value) action) {
    return $value.forEach(action);
  }

  @override
  bool get isEmpty => $value.isEmpty;

  @override
  bool get isNotEmpty => $value.isNotEmpty;

  @override
  Iterable<K> get keys => $value.keys;

  @override
  int get length => $value.length;

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) convert) {
    return $value.map(convert);
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    return $value.putIfAbsent(key, ifAbsent);
  }

  @override
  V? remove(Object? key) => $value.remove(key);

  @override
  void removeWhere(bool Function(K key, V value) test) =>
      $value.removeWhere(test);

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) =>
      $value.update(key, update, ifAbsent: ifAbsent);

  @override
  void updateAll(V Function(K key, V value) update) => $value.updateAll(update);

  @override
  Iterable<V> get values => $value.values;
}

/// dart_eval bimodal wrapper for [MapEntry]
class $MapEntry<K, V> implements MapEntry<K, V>, $Instance {
  /// Wrap a [MapEntry] in a [$MapEntry]
  $MapEntry.wrap(this.$value);

  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.mapEntry),
          generics: {'K': BridgeGenericParam(), 'V': BridgeGenericParam()}),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.mapEntry)),
            params: [
              BridgeParameter(
                  'key', BridgeTypeAnnotation(BridgeTypeRef.ref('K')), false),
              BridgeParameter(
                  'value', BridgeTypeAnnotation(BridgeTypeRef.ref('V')), false),
            ],
            generics: {
              'K': BridgeGenericParam(),
              'V': BridgeGenericParam()
            }))
      },
      getters: {},
      setters: {},
      fields: {
        'key': BridgeFieldDef(BridgeTypeAnnotation(BridgeTypeRef.ref('K'))),
        'value': BridgeFieldDef(BridgeTypeAnnotation(BridgeTypeRef.ref('V'))),
      },
      wrap: true);

  @override
  final MapEntry<K, V> $value;

  late final $Instance _superclass = $Object($value);

  static $Value? $new(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    return $MapEntry.wrap(MapEntry(args[0], args[1]));
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'key':
        return key as $Value?;
      case 'value':
        return value as $Value?;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.mapEntry);

  @override
  MapEntry<K, V> get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  K get key => $value.key;

  @override
  V get value => $value.value;
}
