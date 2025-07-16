part of 'collection.dart';

/// dart_eval bimodal wrapper for [Set]
class $Set<E> implements Set<E>, $Instance {
  /// Wrap a [Set] in a [$Set]
  $Set.wrap(this.$value);

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFunc('dart:core', 'Set.from', __$Set$from);
  }

  static const $type = BridgeTypeRef(CoreTypes.set);

  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.set),
          $extends: BridgeTypeRef(CoreTypes.iterable,
              [BridgeTypeAnnotation(BridgeTypeRef.ref('E'))]),
          generics: {'E': BridgeGenericParam()}),
      constructors: {
        'from': BridgeConstructorDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation($type),
            params: [
              BridgeParameter(
                'elements',
                BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.iterable,
                        [BridgeTypeAnnotation(BridgeTypeRef.ref('E'))]),
                    nullable: false),
                false,
              )
            ],
            generics: {'E': BridgeGenericParam()},
          ),
          isFactory: true,
        ),
      },
      methods: {
        // Most methods are inherited from Iterable, so we don't need to
        // redefine them here.
        'add': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter(
                  'value', BridgeTypeAnnotation(BridgeTypeRef.ref('E')), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool))),
            isStatic: false),
        'addAll': BridgeMethodDef(
            BridgeFunctionDef(
                params: [
                  BridgeParameter(
                      'other',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable,
                          [BridgeTypeAnnotation(BridgeTypeRef.ref('E'))])),
                      false),
                ],
                returns:
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType))),
            isStatic: false),
        'contains': BridgeMethodDef(
          BridgeFunctionDef(params: [
            BridgeParameter(
                'value',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                    nullable: true),
                false),
          ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool))),
          isStatic: false,
        ),
        'remove': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter(
                  'value',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                      nullable: true),
                  false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E'))),
            isStatic: false),
        'clear': BridgeMethodDef(
            BridgeFunctionDef(
                returns:
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType))),
            isStatic: false),
        'lookup': BridgeMethodDef(
            BridgeFunctionDef(
                params: [
                  BridgeParameter(
                      'value',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      false),
                ],
                returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E'),
                    nullable: true)),
            isStatic: false),
        'removeAll': BridgeMethodDef(
            BridgeFunctionDef(
                params: [
                  BridgeParameter(
                      'elements',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable,
                          [BridgeTypeAnnotation(BridgeTypeRef.ref('E'))])),
                      false),
                ],
                returns:
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType))),
            isStatic: false),
        'retainAll': BridgeMethodDef(
            BridgeFunctionDef(
                params: [
                  BridgeParameter(
                      'elements',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable,
                          [BridgeTypeAnnotation(BridgeTypeRef.ref('E'))])),
                      false),
                ],
                returns:
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType))),
            isStatic: false),
        'intersection': BridgeMethodDef(
            BridgeFunctionDef(
                params: [
                  BridgeParameter(
                      'other',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.set, [
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object))
                      ])),
                      false),
                ],
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.set,
                    [BridgeTypeAnnotation(BridgeTypeRef.ref('E'))]))),
            isStatic: false),
        'union': BridgeMethodDef(
            BridgeFunctionDef(
                params: [
                  BridgeParameter(
                      'other',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.set,
                          [BridgeTypeAnnotation(BridgeTypeRef.ref('E'))])),
                      false),
                ],
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.set,
                    [BridgeTypeAnnotation(BridgeTypeRef.ref('E'))]))),
            isStatic: false),
        'difference': BridgeMethodDef(
            BridgeFunctionDef(
                params: [
                  BridgeParameter(
                      'other',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.set, [
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object))
                      ])),
                      false),
                ],
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.set,
                    [BridgeTypeAnnotation(BridgeTypeRef.ref('E'))]))),
            isStatic: false),
      },
      getters: {},
      setters: {},
      fields: {},
      wrap: true);

  static $Value? __$Set$from(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0]?.$value as Set;

    return $Set.wrap(Set.from(other));
  }

  @override
  final Set<E> $value;

  late final $Instance _superclass = $Iterable.wrap($value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'add':
        return __add;
      case 'addAll':
        return __addAll;
      case 'contains':
        return __contains;
      case 'remove':
        return __remove;
      case 'clear':
        return __clear;
      case 'lookup':
        return __lookup;
      case 'intersection':
        return __intersection;
      case 'union':
        return __union;
      case 'difference':
        return __difference;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  static const $Function __add = $Function(_add);

  static $Value? _add(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = args[0]!;
    (target!.$value as Set).add(value);
    return null;
  }

  static const $Function __addAll = $Function(_addAll);

  static $Value? _addAll(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0]!;
    (target!.$value as Set).addAll(other.$value);
    return null;
  }

  static const $Function __contains = $Function(_contains);

  static $Value? _contains(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $bool((target!.$value as Set).contains(args[0]));
  }

  static const $Function __remove = $Function(_remove);

  static $Value? _remove(Runtime runtime, $Value? target, List<$Value?> args) {
    return $bool((target!.$value as Set).remove(args[0]));
  }

  static const $Function __clear = $Function(_clear);
  static $Value? _clear(Runtime runtime, $Value? target, List<$Value?> args) {
    (target!.$value as Set).clear();
    return null;
  }

  static const $Function __lookup = $Function(_lookup);
  static $Value? _lookup(Runtime runtime, $Value? target, List<$Value?> args) {
    return (target!.$value as Set).lookup(args[0]) as $Value?;
  }

  static const $Function __union = $Function(_union);
  static $Value? _union(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0]!.$value as Set<Object?>;
    return $Set.wrap((target!.$value as Set).union(other));
  }

  static const $Function __difference = $Function(_difference);
  static $Value? _difference(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0]!.$value as Set<Object?>;
    return $Set.wrap((target!.$value as Set).difference(other));
  }

  static const $Function __intersection = $Function(_intersection);
  static $Value? _intersection(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0]!.$value as Set<Object?>;
    return $Set.wrap((target!.$value as Set).intersection(other));
  }

  @override
  Set get $reified => Set.from($value.map((e) => e is $Value ? e.$reified : e));

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.map);

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
