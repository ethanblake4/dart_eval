part of 'collection.dart';

/// dart_eval bimodal wrapper for [Set]
class $Set<E> implements Set<E>, $Instance {
  /// Wrap a [Set] in a [$Set]
  $Set.wrap(
    this.$value, {
    int? runtimeTypeId,
    Runtime? runtime,
    this.isolateIdentity = false,
    int? castSourceRuntimeTypeId,
  }) : _runtimeTypeId = runtimeTypeId,
       _castSourceRuntimeTypeId = castSourceRuntimeTypeId,
       _runtime = runtime;

  final int? _runtimeTypeId;
  final int? _castSourceRuntimeTypeId;
  final Runtime? _runtime;
  final bool isolateIdentity;

  // The translated owner descriptor id is stable per (wrapper, runtime) pair;
  // keep the last translation instead of importing on every element write.
  Runtime? _checkRuntime;
  int _checkOwnerType = -1;

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:core', 'Set.', __$Set$new);
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Set.identity',
      __$Set$identity,
    );
    runtime.registerBridgeFuncRegisters('dart:core', 'Set.from', __$Set$from);
    runtime.registerBridgeFuncRegisters('dart:core', 'Set.of', __$Set$of);
  }

  static const $type = BridgeTypeRef(CoreTypes.set);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      BridgeTypeRef(CoreTypes.set),
      $extends: BridgeTypeRef(CoreTypes.iterable, [
        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
      ]),
      generics: {'E': BridgeGenericParam()},
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.set, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          params: [],
          generics: {'E': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
      'identity': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.set, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          params: [],
          generics: {'E': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
      'from': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
              'elements',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                ]),
                nullable: false,
              ),
              false,
            ),
          ],
          generics: {'E': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
      'of': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.set, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          params: [
            BridgeParameter(
              'elements',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                ]),
                nullable: false,
              ),
              false,
            ),
          ],
          generics: {'E': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
    },
    methods: {
      'toString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [],
        ),
        isStatic: false,
      ),
      // Most methods are inherited from Iterable, so we don't need to
      // redefine them here.
      'add': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
        ),
        isStatic: false,
      ),
      'addAll': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                ]),
              ),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        ),
        isStatic: false,
      ),
      'contains': BridgeMethodDef(
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
      'containsAll': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object),
                    nullable: true,
                  ),
                ]),
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
      'clear': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        ),
        isStatic: false,
      ),
      'removeWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
        isStatic: false,
      ),
      'retainWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
        isStatic: false,
      ),
      'lookup': BridgeMethodDef(
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
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E'), nullable: true),
        ),
        isStatic: false,
      ),
      'removeAll': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'elements',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                ]),
              ),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        ),
        isStatic: false,
      ),
      'retainAll': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'elements',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                ]),
              ),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        ),
        isStatic: false,
      ),
      'intersection': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.set, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)),
                ]),
              ),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.set, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
        ),
        isStatic: false,
      ),
      'union': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.set, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                ]),
              ),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.set, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
        ),
        isStatic: false,
      ),
      'difference': BridgeMethodDef(
        BridgeFunctionDef(
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.set, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)),
                ]),
              ),
              false,
            ),
          ],
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.set, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
        ),
        isStatic: false,
      ),
      'cast': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.set, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
            ]),
          ),
          generics: {'R': BridgeGenericParam()},
        ),
        isStatic: false,
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
  );

  static $Value? __$Set$new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Set<Object?>.wrap(
      TypedCollections.newSet(runtime),
      runtimeTypeId: runtime.bridgeConstructorTypeId,
      runtime: runtime,
    );
  }

  static $Value? __$Set$identity(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $Set<Object?>.wrap(
      LinkedHashSet<Object?>.identity(),
      isolateIdentity: true,
      runtimeTypeId: runtime.bridgeConstructorTypeId,
      runtime: runtime,
    );
  }

  static $Value? __$Set$from(Runtime runtime, Object? r, Object? s, Object? c) {
    final other = (r as $Value?)?.$value as Iterable;

    return $Set.wrap(Set.from(other));
  }

  static $Value? __$Set$of(Runtime runtime, Object? r, Object? s, Object? c) {
    final other = (r as $Value?)?.$value as Iterable;
    final wrapper = $Set<Object?>.wrap(
      TypedCollections.newSet(runtime),
      runtimeTypeId: runtime.bridgeConstructorTypeId,
      runtime: runtime,
    );
    for (final element in other) {
      wrapper._checkElement(runtime, element);
      wrapper.$value.add(element);
    }
    return wrapper;
  }

  @override
  final Set<E> $value;

  late final $Instance _superclass = $Iterable.wrap(
    $value,
    runtime: _runtime,
    runtimeTypeId: _iterableRuntimeTypeId(),
  );

  int? _iterableRuntimeTypeId() {
    final runtime = _runtime;
    if (runtime == null) return null;
    final elementType = runtime.runtimeTypeArgumentAt(
      $getRuntimeType(runtime),
      0,
    );
    return elementType == null
        ? null
        : runtime.internParameterizedType(CoreTypes.iterable, [elementType]);
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'toString':
        return $Closure(__toString.func, this);
      case 'add':
        return $Closure(__add.func, this);
      case 'addAll':
        return $Closure(__addAll.func, this);
      case 'contains':
        return $Closure(__contains.func, this);
      case 'containsAll':
        return $Closure(__containsAll.func, this);
      case 'remove':
        return $Closure(__remove.func, this);
      case 'clear':
        return $Closure(__clear.func, this);
      case 'removeWhere':
        return $Closure(__$removeWhere.func, this);
      case 'retainWhere':
        return $Closure(__$retainWhere.func, this);
      case 'lookup':
        return $Closure(__lookup.func, this);
      case 'intersection':
        return $Closure(__intersection.func, this);
      case 'union':
        return $Closure(__union.func, this);
      case 'difference':
        return $Closure(__difference.func, this);
      case 'cast':
        return $Closure(__cast.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  static const $Function __toString = $Function(_toString);

  static $Value? _toString(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return collectionToString(runtime, (target as $Set).$value, '{', '}');
  }

  static const __cast = $Function(_cast);

  static $Value? _cast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $Set;
    final typeArguments = runtime.bridgeCallTypeArguments;
    final elementType = typeArguments.isEmpty
        ? runtime.lookupType(CoreTypes.dynamic)
        : typeArguments.first;
    final sourceRuntimeTypeId =
        wrapper._castSourceRuntimeTypeId ?? wrapper.$getRuntimeType(runtime);
    final sourceElementType = runtime.runtimeTypeArgumentAt(
      sourceRuntimeTypeId,
      0,
    );
    return $Set.wrap(
      wrapper.$value.cast(),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.set, [
        elementType,
      ]),
      castSourceRuntimeTypeId: sourceElementType == null
          ? null
          : sourceRuntimeTypeId,
    );
  }

  static const $Function __add = $Function(_add);

  static $Value? _add(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $Set;
    final value = (r as $Value?);
    wrapper._checkElement(runtime, value);
    return $bool(wrapper.$value.add(value));
  }

  static const $Function __addAll = $Function(_addAll);

  static $Value? _addAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $Set;
    final other = (r as $Value?)!.$value as Iterable;
    final elements = other.toList(growable: false);
    for (final element in elements) {
      wrapper._checkElement(runtime, element);
    }
    wrapper.$value.addAll(elements);
    return null;
  }

  static const $Function __contains = $Function(_contains);

  static $Value? _contains(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $bool((target!.$value as Set).contains((r as $Value?)));
  }

  static const $Function __containsAll = $Function(_containsAll);

  static $Value? _containsAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $Set;
    final other = (r as $Value?)!.$value as Iterable<Object?>;
    return $bool(wrapper.$value.containsAll(other));
  }

  static const $Function __remove = $Function(_remove);

  static $Value? _remove(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $bool((target!.$value as Set).remove((r as $Value?)));
  }

  static const $Function __clear = $Function(_clear);
  static $Value? _clear(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    (target!.$value as Set).clear();
    return null;
  }

  static const $Function __$removeWhere = $Function(_removeWhere);

  static $Value? _removeWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final set = (target as $Set).$value;
    final test = (r as $Value?) as EvalCallable;
    set.removeWhere(
      (element) => test.call(runtime, null, element, null, 1)!.$value as bool,
    );
    return null;
  }

  static const $Function __$retainWhere = $Function(_retainWhere);

  static $Value? _retainWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final set = (target as $Set).$value;
    final test = (r as $Value?) as EvalCallable;
    set.retainWhere(
      (element) => test.call(runtime, null, element, null, 1)!.$value as bool,
    );
    return null;
  }

  static const $Function __lookup = $Function(_lookup);
  static $Value? _lookup(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return (target!.$value as Set).lookup((r as $Value?)) as $Value?;
  }

  static const $Function __union = $Function(_union);
  static $Value? _union(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $Set;
    final other = (r as $Value?)!.$value as Set<Object?>;
    for (final element in other) {
      wrapper._checkElement(runtime, element);
    }
    return $Set.wrap(
      wrapper.$value.union(other),
      runtimeTypeId: wrapper._runtimeTypeId,
      runtime: wrapper._runtime,
    );
  }

  static const $Function __difference = $Function(_difference);
  static $Value? _difference(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $Set;
    final other = (r as $Value?)!.$value as Set<Object?>;
    return $Set.wrap(
      wrapper.$value.difference(other),
      runtimeTypeId: wrapper._runtimeTypeId,
      runtime: wrapper._runtime,
    );
  }

  static const $Function __intersection = $Function(_intersection);
  static $Value? _intersection(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $Set;
    final other = (r as $Value?)!.$value as Set<Object?>;
    return $Set.wrap(
      wrapper.$value.intersection(other),
      runtimeTypeId: wrapper._runtimeTypeId,
      runtime: wrapper._runtime,
    );
  }

  @override
  Set get $reified => Set.from($value.map((e) => e is $Value ? e.$reified : e));

  @override
  int $getRuntimeType(Runtime runtime) {
    final typeId = _runtimeTypeId;
    return typeId == null
        ? runtime.lookupType(CoreTypes.set)
        : runtime.importRuntimeType(_runtime ?? runtime, typeId);
  }

  void _checkElement(Runtime runtime, Object? value) {
    final runtimeTypeId = _runtimeTypeId;
    if (runtimeTypeId != null) {
      if (!identical(_checkRuntime, runtime)) {
        _checkRuntime = runtime;
        _checkOwnerType = $getRuntimeType(runtime);
      }
      runtime.assertTypedTypeArgument(value, _checkOwnerType, 0);
    }
    final castSourceRuntimeTypeId = _castSourceRuntimeTypeId;
    if (castSourceRuntimeTypeId != null) {
      runtime.assertTypedTypeArgument(value, castSourceRuntimeTypeId, 0);
    }
  }

  @override
  void clear() {
    return $value.clear();
  }

  @override
  bool add(E value) => $value.add(value);

  @override
  void addAll(Iterable<E> elements) => $value.addAll(elements);

  @override
  bool any(bool Function(E element) test) => $value.any(test);

  @override
  Set<R> cast<R>() => $value.cast<R>();

  @override
  bool contains(Object? value) => $value.contains(value);

  @override
  bool containsAll(Iterable<Object?> other) => $value.containsAll(other);

  @override
  Set<E> difference(Set<Object?> other) => $value.difference(other);

  @override
  E elementAt(int index) => $value.elementAt(index);

  @override
  bool every(bool Function(E element) test) => $value.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) toElements) =>
      $value.expand(toElements);

  @override
  E get first => $value.first;

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) {
    return $value.firstWhere(test, orElse: orElse);
  }

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) {
    return $value.fold(initialValue, combine);
  }

  @override
  Iterable<E> followedBy(Iterable<E> other) => $value.followedBy(other);

  @override
  void forEach(void Function(E element) action) {
    $value.forEach(action);
  }

  @override
  Set<E> intersection(Set<Object?> other) {
    return $value.intersection(other);
  }

  @override
  bool get isEmpty => $value.isEmpty;

  @override
  bool get isNotEmpty => $value.isNotEmpty;

  @override
  Iterator<E> get iterator => $value.iterator;

  @override
  String join([String separator = ""]) {
    return $value.join(separator);
  }

  @override
  E get last => $value.last;

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) {
    return $value.lastWhere(test, orElse: orElse);
  }

  @override
  int get length => $value.length;

  @override
  E? lookup(Object? object) {
    return $value.lookup(object);
  }

  @override
  Iterable<T> map<T>(T Function(E e) toElement) {
    return $value.map(toElement);
  }

  @override
  E reduce(E Function(E value, E element) combine) {
    return $value.reduce(combine);
  }

  @override
  bool remove(Object? value) {
    return $value.remove(value);
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    $value.removeAll(elements);
  }

  @override
  void removeWhere(bool Function(E element) test) {
    $value.removeWhere(test);
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    $value.retainAll(elements);
  }

  @override
  void retainWhere(bool Function(E element) test) {
    $value.retainWhere(test);
  }

  @override
  E get single => $value.single;

  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) {
    return $value.singleWhere(test, orElse: orElse);
  }

  @override
  Iterable<E> skip(int count) {
    return $value.skip(count);
  }

  @override
  Iterable<E> skipWhile(bool Function(E value) test) {
    return $value.skipWhile(test);
  }

  @override
  Iterable<E> take(int count) {
    return $value.take(count);
  }

  @override
  Iterable<E> takeWhile(bool Function(E value) test) {
    return $value.takeWhile(test);
  }

  @override
  List<E> toList({bool growable = true}) {
    return $value.toList(growable: growable);
  }

  @override
  Set<E> toSet() {
    return $value.toSet();
  }

  @override
  Set<E> union(Set<E> other) {
    return $value.union(other);
  }

  @override
  Iterable<E> where(bool Function(E element) test) {
    return $value.where(test);
  }

  @override
  Iterable<T> whereType<T>() {
    return $value.whereType<T>();
  }
}
