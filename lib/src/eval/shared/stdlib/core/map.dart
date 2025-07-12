part of 'collection.dart';

/// dart_eval bimodal wrapper for [Map]
class $Map<K, V> implements Map<K, V>, $Instance {
  /// Wrap a [Map] in a [$Map]
  $Map.wrap(this.$value);

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFunc(
        'dart:core', 'Map.from', __$Map$from.call);
  }

  static const $type = BridgeTypeRef(CoreTypes.map);

  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.map),
          generics: {'K': BridgeGenericParam(), 'V': BridgeGenericParam()}),
      constructors: {
        'from': BridgeConstructorDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation($type),
            params: [
              BridgeParameter(
                'other',
                BridgeTypeAnnotation($type, nullable: false),
                false,
              )
            ],
            generics: {'K': BridgeGenericParam(), 'V': BridgeGenericParam()},
          ),
          isFactory: true,
        ),
      },
      methods: {
        '[]': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter(
                  'key', BridgeTypeAnnotation(BridgeTypeRef.ref('K')), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V'))),
            isStatic: false),
        '[]=': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter(
                  'key', BridgeTypeAnnotation(BridgeTypeRef.ref('K')), false),
              BridgeParameter(
                  'value', BridgeTypeAnnotation(BridgeTypeRef.ref('V')), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V'))),
            isStatic: false),
        'length': BridgeMethodDef(
            BridgeFunctionDef(
                params: [],
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))),
            isStatic: false),
        'cast': BridgeMethodDef(
            BridgeFunctionDef(
                generics: {
                  'RK': BridgeGenericParam(),
                  'RV': BridgeGenericParam()
                },
                params: [],
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('RK')),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('RV'))
                ]))),
            isStatic: false),
        'addAll': BridgeMethodDef(
            BridgeFunctionDef(
                params: [
                  BridgeParameter(
                      'other',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.map, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                        BridgeTypeAnnotation(BridgeTypeRef.ref('V'))
                      ])),
                      false),
                ],
                returns:
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType))),
            isStatic: false),
        'containsKey': BridgeMethodDef(
          BridgeFunctionDef(params: [
            BridgeParameter(
                'key',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                    nullable: true),
                false),
          ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool))),
          isStatic: false,
        ),
        'remove': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter(
                  'key',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                      nullable: true),
                  false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V'))),
            isStatic: false),
      },
      getters: {
        'keys': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable)))),
        'values': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable)))),
        'entries': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable)))),
        'isEmpty': BridgeMethodDef(
            BridgeFunctionDef(
                params: [],
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool))),
            isStatic: false),
        'isNotEmpty': BridgeMethodDef(
            BridgeFunctionDef(
                params: [],
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool))),
            isStatic: false),
      },
      setters: {},
      fields: {},
      wrap: true);

  static const __$Map$from = $Function(_$Map$from);
  static $Value? _$Map$from(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0]?.$value as Map;

    return $Map.wrap(Map.from(other));
  }

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
      case 'addAll':
        return __addAll;
      case 'cast':
        return __cast;
      case 'length':
        return $int($value.length);
      case 'containsKey':
        return __containsKey;
      case 'remove':
        return __remove;
      case 'entries':
        return $Iterable.wrap(entries.map((e) => $MapEntry.wrap(e)));
      case 'isEmpty':
        return $bool($value.isEmpty);
      case 'keys':
        return $Iterable.wrap(keys);
      case 'values':
        return $Iterable.wrap(values);
      case 'isNotEmpty':
        return $bool($value.isNotEmpty);
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
    return map[idx];
  }

  static const $Function __indexSet = $Function(_indexSet);

  static $Value? _indexSet(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final idx = args[0]!;
    final value = args[1]!;
    return (target!.$value as Map)[idx] = value;
  }

  static const $Function __addAll = $Function(_addAll);

  static $Value? _addAll(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0]!;
    (target!.$value as Map).addAll(other.$value);
    return null;
  }

  static const $Function __cast = $Function(_cast);

  static $Value? _cast(Runtime runtime, $Value? target, List<$Value?> args) {
    return target;
  }

  static const $Function __containsKey = $Function(_containsKey);

  static $Value? _containsKey(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $bool((target!.$value as Map).containsKey(args[0]));
  }

  static const $Function __remove = $Function(_remove);

  static $Value? _remove(Runtime runtime, $Value? target, List<$Value?> args) {
    return (target!.$value as Map).remove(args[0]);
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
class $MapEntry<K, V> implements $Instance {
  /// Wrap a [MapEntry] in a [$MapEntry]
  $MapEntry.wrap(this.$value);

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFunc('dart:core', 'MapEntry.', _$new.call);
  }

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

  static $Value? _$new(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    return $MapEntry.wrap(MapEntry(args[0], args[1]));
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'key':
        return $value.key as $Value?;
      case 'value':
        return $value.value as $Value?;
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
}
