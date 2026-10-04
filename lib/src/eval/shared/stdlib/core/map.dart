part of 'collection.dart';

/// dart_eval bimodal wrapper for [Map]
class $Map<K, V> implements Map<K, V>, $Instance {
  /// Wrap a [Map] in a [$Map]
  $Map.wrap(
    this.$value, {
    int? runtimeTypeId,
    Runtime? runtime,
    bool identityKeys = false,
    bool unmodifiable = false,
  }) : _runtimeTypeId = runtimeTypeId,
       _runtime = runtime,
       _identityKeys = identityKeys,
       _unmodifiable = unmodifiable,
       _identityScalarKeys = identityKeys ? Map.identity() : null;

  final int? _runtimeTypeId;
  final Runtime? _runtime;
  final bool _identityKeys;
  final bool _unmodifiable;
  final Map<Object?, $Value>? _identityScalarKeys;

  // The translated owner descriptor id is stable per (wrapper, runtime) pair;
  // keep the last translation instead of importing on every entry write.
  Runtime? _checkRuntime;
  int _checkOwnerType = -1;

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:core', 'Map.', _$Map$new);
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Map.identity',
      _$Map$identity,
    );
    runtime.registerBridgeFuncRegisters('dart:core', 'Map.from', _$Map$from);
    runtime.registerBridgeFuncRegisters('dart:core', 'Map.of', _$Map$of);
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Map.fromIterables',
      _$Map$fromIterables,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Map.fromEntries',
      _$Map$fromEntries,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Map.unmodifiable',
      _$Map$unmodifiable,
    );
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
      'identity': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [],
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
      'fromIterables': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
              'keys',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                ]),
              ),
              false,
            ),
            BridgeParameter(
              'values',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                ]),
              ),
              false,
            ),
          ],
          generics: {'K': BridgeGenericParam(), 'V': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
      'fromEntries': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
              'entries',
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
          generics: {'K': BridgeGenericParam(), 'V': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
      'unmodifiable': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
              ),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
    },
    methods: {
      'map': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'K2': BridgeGenericParam(), 'V2': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('K2')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('V2')),
            ]),
          ),
          params: [
            BridgeParameter(
              'transform',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.mapEntry, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('K2')),
                        BridgeTypeAnnotation(BridgeTypeRef.ref('V2')),
                      ]),
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
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),
      '[]': BridgeMethodDef(
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
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V'), nullable: true),
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
    return $Map.wrap(
      {},
      runtimeTypeId: runtime.bridgeConstructorTypeId,
      runtime: runtime,
      unmodifiable: true,
    );
  }

  static $Value? _$Map$identity(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $Map.wrap(
      Map.identity(),
      runtimeTypeId: runtime.bridgeConstructorTypeId,
      runtime: runtime,
      identityKeys: true,
    );
  }

  static $Value? _$Map$from(Runtime runtime, Object? r, Object? s, Object? c) {
    final other = (r as $Value?)?.$value as Map;

    return $Map.wrap(
      Map.from(other),
      runtimeTypeId: runtime.bridgeConstructorTypeId,
      runtime: runtime,
    );
  }

  static $Value? _$Map$of(Runtime runtime, Object? r, Object? s, Object? c) {
    final other = (r as $Value?)?.$value as Map;

    return $Map.wrap(
      Map.of(other),
      runtimeTypeId: runtime.bridgeConstructorTypeId,
      runtime: runtime,
    );
  }

  static $Value? _$Map$fromIterables(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final keys = (r as $Value?)!.$value as Iterable;
    final values = (s as $Value?)!.$value as Iterable;
    return $Map.wrap(
      Map.fromIterables(keys, values),
      runtimeTypeId: runtime.bridgeConstructorTypeId,
      runtime: runtime,
    );
  }

  static $Value? _$Map$fromEntries(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final entries = (r as $Value).$reified as Iterable;
    return $Map.wrap(
      Map.fromEntries(
        entries.map(
          (entry) => (entry is $Value ? entry.$reified : entry) as MapEntry,
        ),
      ),
      runtimeTypeId: runtime.bridgeConstructorTypeId,
      runtime: runtime,
    );
  }

  static $Value? _$Map$unmodifiable(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final other = (r as $Value?)!.$value as Map;
    return $Map.wrap(
      Map.unmodifiable(other),
      runtimeTypeId: runtime.bridgeConstructorTypeId,
      runtime: runtime,
      unmodifiable: true,
    );
  }

  static const $Function __map = $Function(_map);

  static $Value? _map(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final transform = TypedInterop.nonGenericCallable(r);
    final typeArguments = runtime.bridgeCallTypeArguments;
    final resultType = typeArguments.length < 2
        ? null
        : runtime.internParameterizedType(CoreTypes.map, typeArguments);
    final ownerType = target!.$getRuntimeType(runtime);
    final keyType = runtime.runtimeTypeArgumentAt(ownerType, 0);
    final valueType = runtime.runtimeTypeArgumentAt(ownerType, 1);
    final mapped = (target.$value as Map).map((key, value) {
      final boxedKey = TypedInterop.boxExternal(
        key,
        runtime: runtime,
        runtimeTypeId: keyType,
      );
      final boxedValue = TypedInterop.boxExternal(
        value,
        runtime: runtime,
        runtimeTypeId: valueType,
      );
      if (keyType != null)
        runtime.assertTypedTypeArgument(boxedKey, ownerType, 0);
      if (valueType != null)
        runtime.assertTypedTypeArgument(boxedValue, ownerType, 1);
      final entry = transform.call(runtime, null, boxedKey, boxedValue, 2);
      final nativeEntry = (entry as $Value).$value as MapEntry;
      final mappedKey = TypedInterop.boxExternal(
        nativeEntry.key,
        runtime: runtime,
        runtimeTypeId: resultType == null
            ? null
            : runtime.runtimeTypeArgumentAt(resultType, 0),
      );
      final mappedValue = TypedInterop.boxExternal(
        nativeEntry.value,
        runtime: runtime,
        runtimeTypeId: resultType == null
            ? null
            : runtime.runtimeTypeArgumentAt(resultType, 1),
      );
      if (resultType != null) {
        runtime.assertTypedTypeArgument(mappedKey, resultType, 0);
        runtime.assertTypedTypeArgument(mappedValue, resultType, 1);
      }
      return MapEntry(mappedKey, mappedValue);
    });
    return $Map.wrap(mapped, runtime: runtime, runtimeTypeId: resultType);
  }

  @override
  final Map<K, V> $value;

  late final $Instance _superclass = $Object($value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'map':
        return $Closure(__map.func, this);
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
        return _iterableView(runtime, keys, 0);
      case 'values':
        return _iterableView(runtime, values, 1);
      case 'isNotEmpty':
        return $bool($value.isNotEmpty);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  $Iterable _iterableView(Runtime runtime, Iterable values, int argument) {
    final elementType = runtime.runtimeTypeArgumentAt(
      $getRuntimeType(runtime),
      argument,
    );
    return $Iterable.wrap(
      values,
      runtime: runtime,
      runtimeTypeId: elementType == null
          ? null
          : runtime.internParameterizedType(CoreTypes.iterable, [elementType]),
    );
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
    final idx = (r as $Value?) ?? const $null();
    final wrapper = target! as $Map;
    return wrapper.$value[wrapper._identityKey(idx)];
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
    if (wrapper._unmodifiable) {
      return wrapper.$value[wrapper._identityKey(key)] = value;
    }
    wrapper._checkEntry(runtime, key, value);
    return wrapper.$value[wrapper._identityKey(key, writing: true)] = value;
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
    if (wrapper._unmodifiable) {
      wrapper.$value.addAll(other);
      return null;
    }
    final entries = other.entries.toList(growable: false);
    for (final entry in entries) {
      wrapper._checkEntry(runtime, entry.key, entry.value);
    }
    for (final entry in entries) {
      wrapper.$value[wrapper._identityKey(entry.key, writing: true)] =
          entry.value;
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
    if (wrapper._unmodifiable) {
      wrapper.$value.addEntries(newEntries.cast<MapEntry>());
      return null;
    }
    final entries = [
      for (final e in newEntries) (e is $Value ? e.$value : e) as MapEntry,
    ];
    for (final entry in entries) {
      wrapper._checkEntry(runtime, entry.key, entry.value);
    }
    for (final entry in entries) {
      wrapper.$value[wrapper._identityKey(entry.key, writing: true)] =
          entry.value;
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
      wrapper._identityKey(key, writing: true),
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
    final wrapper = target! as $Map;
    wrapper.$value.removeWhere(
      (key, value) =>
          test.call(runtime, null, key as $Value?, value as $Value?, 2)!.$value
              as bool,
    );
    wrapper._pruneIdentityScalarKeys();
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
    final wrapper = target! as $Map;
    return $bool(
      wrapper.$value.containsKey(wrapper._identityKey(r as $Value?)),
    );
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
    final wrapper = target! as $Map;
    wrapper.$value.clear();
    wrapper._identityScalarKeys?.clear();
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
      wrapper._identityKey(key, writing: true),
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
      (key, value) =>
          action.call(runtime, null, key as $Value?, value as $Value?, 2),
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
    final wrapper = target! as $Map;
    final key = wrapper._identityKey(r as $Value?);
    final result = wrapper.$value.remove(key);
    wrapper._forgetIdentityScalarKey(key);
    return result;
  }

  @override
  Map get $reified {
    if (!_identityKeys) {
      return $value.map(
        (k, v) => MapEntry(
          k is $Value ? k.$reified : k,
          v is $Value ? v.$reified : v,
        ),
      );
    }
    final result = Map.identity();
    for (final entry in $value.entries) {
      final key = entry.key;
      final value = entry.value;
      result[key is $Value ? key.$reified : key] = value is $Value
          ? value.$reified
          : value;
    }
    return result;
  }

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

  Object? _identityKey(Object? key, {bool writing = false}) {
    if (!_identityKeys ||
        (key is! $num && key is! $bool && key is! $String && key is! $null)) {
      return key;
    }
    final scalarKey = key as $Value;
    final value = scalarKey.$value;
    final scalarKeys = _identityScalarKeys!;
    final existing = scalarKeys[value];
    if (existing != null) return existing;
    if (writing) scalarKeys[value] = scalarKey;
    return scalarKey;
  }

  void _forgetIdentityScalarKey(Object? key) {
    if (!_identityKeys ||
        (key is! $num && key is! $bool && key is! $String && key is! $null)) {
      return;
    }
    final value = (key as $Value).$value;
    _identityScalarKeys!.remove(value);
  }

  void _pruneIdentityScalarKeys() {
    final scalarKeys = _identityScalarKeys;
    if (scalarKeys == null) return;
    scalarKeys.removeWhere((_, key) => !$value.containsKey(key));
  }

  @override
  V? operator [](Object? key) {
    return $value[_identityKey(key)];
  }

  @override
  void operator []=(K key, V value) {
    $value[_identityKey(key, writing: true) as K] = value;
  }

  @override
  void addAll(Map<K, V> other) {
    if (!_identityKeys) {
      $value.addAll(other);
      return;
    }
    for (final entry in other.entries) {
      $value[_identityKey(entry.key, writing: true) as K] = entry.value;
    }
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    if (!_identityKeys) {
      $value.addEntries(newEntries);
      return;
    }
    for (final entry in newEntries) {
      $value[_identityKey(entry.key, writing: true) as K] = entry.value;
    }
  }

  @override
  Map<RK, RV> cast<RK, RV>() => $value.cast<RK, RV>();

  @override
  void clear() {
    $value.clear();
    _identityScalarKeys?.clear();
  }

  @override
  bool containsKey(Object? key) => $value.containsKey(_identityKey(key));

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
    return $value.putIfAbsent(_identityKey(key, writing: true) as K, ifAbsent);
  }

  @override
  V? remove(Object? key) {
    final identityKey = _identityKey(key);
    final result = $value.remove(identityKey);
    _forgetIdentityScalarKey(identityKey);
    return result;
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    $value.removeWhere(test);
    _pruneIdentityScalarKeys();
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) =>
      $value.update(
        _identityKey(key, writing: true) as K,
        update,
        ifAbsent: ifAbsent,
      );

  @override
  void updateAll(V Function(K key, V value) update) => $value.updateAll(update);

  @override
  Iterable<V> get values => $value.values;
}
