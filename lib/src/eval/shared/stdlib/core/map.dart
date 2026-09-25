part of 'collection.dart';

/// dart_eval bimodal wrapper for [Map]
class $Map<K, V> implements Map<K, V>, $Instance {
  /// Wrap a [Map] in a [$Map]
  $Map.wrap(this.$value, {int? runtimeTypeId, Runtime? runtime})
    : _runtimeTypeId = runtimeTypeId,
      _runtime = runtime;

  final int? _runtimeTypeId;
  final Runtime? _runtime;

  // The translated owner descriptor id is stable per (wrapper, runtime) pair;
  // keep the last translation instead of importing on every entry write.
  Runtime? _checkRuntime;
  int _checkOwnerType = -1;

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:core', 'Map.', _$Map$new);
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Map.from',
      _$Map$from,
    );
    runtime.registerBridgeFuncRegisters('dart:core', 'Map.of', _$Map$of);
  }

  static const $type = BridgeTypeRef(CoreTypes.map);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      BridgeTypeRef(CoreTypes.map),
      generics: {'K': BridgeGenericParam(), 'V': BridgeGenericParam()},
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [],
          generics: {'K': BridgeGenericParam(), 'V': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
      'of': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation($type, nullable: false),
              false,
            ),
          ],
          generics: {'K': BridgeGenericParam(), 'V': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
      'from': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation($type, nullable: false),
              false,
            ),
          ],
          generics: {'K': BridgeGenericParam(), 'V': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
    },
    methods: {
      '[]': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'key',
              BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
        ),
        isStatic: false,
      ),
      '[]=': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'key',
              BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
              false,
            ),
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
        ),
        isStatic: false,
      ),
      'cast': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'RK': BridgeGenericParam(), 'RV': BridgeGenericParam()},
          params: [],
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('RK')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('RV')),
            ]),
          ),
        ),
        isStatic: false,
      ),
      'addAll': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                ]),
              ),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        ),
        isStatic: false,
      ),
      'addEntries': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'newEntries',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.mapEntry, [
                      BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                      BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                    ]),
                  ),
                ]),
              ),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        ),
        isStatic: false,
      ),
      'update': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
          namedParams: [
            BridgeParameter(
              'ifAbsent',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                    params: [],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'key',
              BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
              false,
            ),
            BridgeParameter(
              'update',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                    params: [
                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),
      'updateAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'update',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                    params: [
                      BridgeParameter(
                        'key',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                        false,
                      ),
                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),
      'removeWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'key',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                        false,
                      ),
                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),
      'toString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [],
        ),
        isStatic: false,
      ),
      'clear': BridgeMethodDef(
        BridgeFunctionDef(
          params: [],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        ),
        isStatic: false,
      ),
      'containsValue': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
        ),
        isStatic: false,
      ),
      'putIfAbsent': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'key',
              BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
              false,
            ),
            BridgeParameter(
              'ifAbsent',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
        ),
        isStatic: false,
      ),
      'forEach': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'action',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        ),
        isStatic: false,
      ),
      'containsKey': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'key',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
        ),
        isStatic: false,
      ),
      'remove': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'key',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
        ),
        isStatic: false,
      ),
    },
    getters: {
      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
        ),
        isStatic: false,
      ),
      'keys': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
            ]),
          ),
        ),
      ),
      'values': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
            ]),
          ),
        ),
      ),
      'entries': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.mapEntry, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                ]),
              ),
            ]),
          ),
        ),
      ),
      'isEmpty': BridgeMethodDef(
        BridgeFunctionDef(
          params: [],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
        ),
        isStatic: false,
      ),
      'isNotEmpty': BridgeMethodDef(
        BridgeFunctionDef(
          params: [],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
        ),
        isStatic: false,
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
  );

  static $Value? _$Map$new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Map.wrap({});
  }

  static $Value? _$Map$from(Runtime runtime, Object? r, Object? s, Object? c) {
    final other = (r as $Value?)?.$value as Map;

    return $Map.wrap(Map.from(other));
  }

  static $Value? _$Map$of(Runtime runtime, Object? r, Object? s, Object? c) {
    final other = (r as $Value?)?.$value as Map;

    return $Map.wrap(Map.of(other));
  }

  @override
  final Map<K, V> $value;

  late final $Instance _superclass = $Object($value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '[]':
        return $Closure(__indexGet.func, this);
      case '[]=':
        return $Closure(__indexSet.func, this);
      case 'addAll':
        return $Closure(__addAll.func, this);
      case 'addEntries':
        return $Closure(__addEntries.func, this);
      case 'update':
        return $Closure(__update.func, this);
      case 'updateAll':
        return $Closure(__updateAll.func, this);
      case 'removeWhere':
        return $Closure(__removeWhere.func, this);
      case 'cast':
        return $Closure(__cast.func, this);
      case 'length':
        return $int($value.length);
      case 'toString':
        return $Closure(__toString.func, this);
      case 'clear':
        return $Closure(__clear.func, this);
      case 'containsKey':
        return $Closure(__containsKey.func, this);
      case 'containsValue':
        return $Closure(__containsValue.func, this);
      case 'putIfAbsent':
        return $Closure(__putIfAbsent.func, this);
      case 'forEach':
        return $Closure(__forEach.func, this);
      case 'remove':
        return $Closure(__remove.func, this);
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
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final idx = (r as $Value?)!;
    final map = target!.$value as Map;
    return map[idx];
  }

  static const $Function __indexSet = $Function(_indexSet);

  static $Value? _indexSet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $Map;
    final key = (r as $Value?);
    final value = (s as $Value?);
    wrapper._checkEntry(runtime, key, value);
    return wrapper.$value[key] = value;
  }

  static const $Function __addAll = $Function(_addAll);

  static $Value? _addAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $Map;
    final other = (r as $Value?)!.$value as Map;
    final entries = other.entries.toList(growable: false);
    for (final entry in entries) {
      wrapper._checkEntry(runtime, entry.key, entry.value);
    }
    for (final entry in entries) {
      wrapper.$value[entry.key] = entry.value;
    }
    return null;
  }

  static const $Function __addEntries = $Function(_addEntries);

  static $Value? _addEntries(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $Map;
    final newEntries = (r as $Value?)!.$value as Iterable;
    final entries = [
      for (final e in newEntries) (e is $Value ? e.$value : e) as MapEntry,
    ];
    for (final entry in entries) {
      wrapper._checkEntry(runtime, entry.key, entry.value);
    }
    for (final entry in entries) {
      wrapper.$value[entry.key] = entry.value;
    }
    return null;
  }

  static const $Function __update = $Function(_update);

  static $Value? _update(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $Map;
    final key = r as $Value?;
    final update = (s as $Value?) as EvalFunction;
    // `c` is the arg count below three args, else the trailing-arg list —
    // named `ifAbsent` arrives as its first element when supplied.
    final ifAbsent = c is List && c.isNotEmpty ? c[0] as EvalFunction? : null;
    final result = wrapper.$value.update(
      key,
      (value) => update.call(runtime, null, value as $Value?, null, 1),
      ifAbsent: ifAbsent == null
          ? null
          : () => ifAbsent.call(runtime, null, null, null, 0),
    );
    wrapper._checkEntry(runtime, key, result);
    return result as $Value?;
  }

  static const $Function __updateAll = $Function(_updateAll);

  static $Value? _updateAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final update = (r as $Value?) as EvalFunction;
    (target!.$value as Map).updateAll(
      (key, value) =>
          update.call(runtime, null, key as $Value?, value as $Value?, 2),
    );
    return null;
  }

  static const $Function __removeWhere = $Function(_removeWhere);

  static $Value? _removeWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final test = (r as $Value?) as EvalFunction;
    (target!.$value as Map).removeWhere(
      (key, value) =>
          test.call(runtime, null, key as $Value?, value as $Value?, 2)!
              .$value as bool,
    );
    return null;
  }

  static const $Function __cast = $Function(_cast);

  static $Value? _cast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return target;
  }

  static const $Function __containsKey = $Function(_containsKey);

  static $Value? _containsKey(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $bool((target!.$value as Map).containsKey((r as $Value?)));
  }

  static const $Function __toString = $Function(_toString);

  static $Value? _toString(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return mapToString(runtime, (target as $Map).$value.cast());
  }

  static const $Function __clear = $Function(_clear);

  static $Value? _clear(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    (target!.$value as Map).clear();
    return null;
  }

  static const $Function __containsValue = $Function(_containsValue);

  static $Value? _containsValue(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $bool((target!.$value as Map).containsValue((r as $Value?)));
  }

  static const $Function __putIfAbsent = $Function(_putIfAbsent);

  static $Value? _putIfAbsent(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $Map;
    final key = (r as $Value?);
    final ifAbsent = (s as $Value?) as EvalFunction;
    final result = wrapper.$value.putIfAbsent(
      key,
      () => ifAbsent.call(runtime, null, null, null, 0),
    );
    wrapper._checkEntry(runtime, key, result);
    return result as $Value?;
  }

  static const $Function __forEach = $Function(_forEach);

  static $Value? _forEach(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final action = (r as $Value?) as EvalFunction;
    (target!.$value as Map).forEach(
      (key, value) => action.call(runtime, null, key as $Value?, value as $Value?, 2),
    );
    return null;
  }

  static const $Function __remove = $Function(_remove);

  static $Value? _remove(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return (target!.$value as Map).remove((r as $Value?));
  }

  @override
  Map get $reified => $value.map(
    (k, v) =>
        MapEntry(k is $Value ? k.$reified : k, v is $Value ? v.$reified : v),
  );

  @override
  int $getRuntimeType(Runtime runtime) {
    final typeId = _runtimeTypeId;
    return typeId == null
        ? runtime.lookupType(CoreTypes.map)
        : runtime.importRuntimeType(_runtime ?? runtime, typeId);
  }

  void _checkEntry(Runtime runtime, Object? key, Object? value) {
    final runtimeTypeId = _runtimeTypeId;
    if (runtimeTypeId == null) return;
    if (!identical(_checkRuntime, runtime)) {
      _checkRuntime = runtime;
      _checkOwnerType = $getRuntimeType(runtime);
    }
    runtime.assertTypedTypeArgument(key, _checkOwnerType, 0);
    runtime.assertTypedTypeArgument(value, _checkOwnerType, 1);
  }

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
