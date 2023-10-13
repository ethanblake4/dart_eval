part of 'collection.dart';

/// dart_eval bimodal wrapper for [Iterable]
class $Iterable<E> implements Iterable<E>, $Instance {
  /// Compile-time class definition for [$Iterable]
  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.iterable),
          generics: {'E': BridgeGenericParam()}),
      constructors: {},
      methods: {
        'join': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('separator',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), true),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string))),
            isStatic: false),
        'map': BridgeMethodDef(
            BridgeFunctionDef(
                params: [
                  BridgeParameter(
                      'toElement',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                      false),
                ],
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable')))),
            isStatic: false),
        'toList': BridgeMethodDef(
            BridgeFunctionDef(
                params: [
                  BridgeParameter(
                      'growable',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
                      true),
                ],
                returns: BridgeTypeAnnotation(BridgeTypeRef(
                    CoreTypes.list, [BridgeTypeRef(CoreTypes.dynamic)]))),
            isStatic: false),
      },
      getters: {
        'iterator': BridgeMethodDef(
            BridgeFunctionDef(
                params: [],
                returns:
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterator, [
                  BridgeTypeRef.ref('E'),
                ]))),
            isStatic: false),
      },
      setters: {},
      fields: {},
      wrap: true);

  /// Wrap an [Iterable] in an [$Iterable]
  $Iterable.wrap(this.$value);

  @override
  final Iterable<E> $value;

  @override
  Iterable<E> get $reified => $value;

  late final $Instance _superclass = $Object($value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'any':
        return __any;
      case 'elementAt':
        return __elementAt;
      case 'every':
        return __every;
      case 'iterator':
        return $Iterator.wrap($value.iterator);
      case 'followedBy':
        return __followedBy;
      case 'skip':
        return __skip;
      case 'skipWhile':
        return __skipWhile;
      case 'join':
        return __join;
      case 'map':
        return __map;
      case 'take':
        return __take;
      case 'toSet':
        return __toSet;
      case 'toList':
        return __toList;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  static const $Function __join = $Function(_join);

  static $Value? _join(Runtime runtime, $Value? target, List<$Value?> args) {
    final separator = (args[0] as String?) ?? '';
    return $String((target!.$value as Iterable).join(separator));
  }

  static const $Function __map = $Function(_map);

  static $Value? _map(Runtime runtime, $Value? target, List<$Value?> args) {
    final toElement = args[0] as EvalCallable;
    return $Iterable.wrap((target!.$value as Iterable)
        .map((e) => toElement.call(runtime, null, [e])!.$value));
  }

  static const $Function __toList = $Function(_toList);

  static $Value? _toList(Runtime runtime, $Value? target, List<$Value?> args) {
    return $List.wrap(
        (target!.$value as Iterable).toList(growable: args[0]?.$value ?? true));
  }

  static const $Function __any = $Function(_any);

  static $Value? _any(Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    return $bool((target!.$value as Iterable)
        .any((e) => test.call(runtime, null, [e])!.$value as bool));
  }

  static const $Function __every = $Function(_every);

  static $Value? _every(Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    return $bool((target!.$value as Iterable)
        .every((e) => test.call(runtime, null, [e])!.$value as bool));
  }

  static const $Function __elementAt = $Function(_elementAt);

  static $Value? _elementAt(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return (target!.$value as List).elementAt(args[0]!.$value);
  }

  static const $Function __followedBy = $Function(_followedBy);

  static $Value? _followedBy(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $Iterable.wrap(
        (target!.$value as Iterable).followedBy(args[0]!.$value as Iterable));
  }

  static const $Function __skip = $Function(_skip);

  static $Value? _skip(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Iterable.wrap((target!.$value as Iterable).skip(args[0]!.$value));
  }

  static const $Function __skipWhile = $Function(_skipWhile);

  static $Value? _skipWhile(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    return $Iterable.wrap((target!.$value as List)
        .skipWhile((e) => test.call(runtime, null, [e])!.$value as bool));
  }

  static const $Function __take = $Function(_take);

  static $Value? _take(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Iterable.wrap((target!.$value as Iterable).take(args[0]!.$value));
  }

  static const $Function __toSet = $Function(_toSet);

  static $Value? _toSet(Runtime runtime, $Value? target, List<$Value?> args) {
    return $List.wrap((target!.$value as Iterable).toSet().toList());
  }

  @override
  bool any(bool Function(E element) test) => $value.any(test);

  @override
  Iterable<R> cast<R>() => $value.cast<R>();

  @override
  bool contains(Object? element) => $value.contains(element);

  @override
  E elementAt(int index) => $value.elementAt(index);

  @override
  bool every(bool Function(E element) test) => $value.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) toElements) =>
      $value.expand<T>(toElements);

  @override
  E get first => $value.first;

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      $value.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      $value.fold(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) => $value.followedBy(other);

  @override
  void forEach(void Function(E element) action) => $value.forEach(action);

  @override
  bool get isEmpty => $value.isEmpty;

  @override
  bool get isNotEmpty => $value.isNotEmpty;

  @override
  Iterator<E> get iterator => $value.iterator;

  @override
  String join([String separator = '']) => $value.join(separator);

  @override
  E get last => $value.last;

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      $value.lastWhere(test, orElse: orElse);

  @override
  int get length => $value.length;

  @override
  Iterable<T> map<T>(T Function(E e) toElement) => $value.map(toElement);

  @override
  E reduce(E Function(E value, E element) combine) => $value.reduce(combine);

  @override
  E get single => $value.single;

  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      $value.singleWhere(test, orElse: orElse);

  @override
  Iterable<E> skip(int count) => $value.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E value) test) => $value.skipWhile(test);

  @override
  Iterable<E> take(int count) => $value.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E value) test) => $value.takeWhile(test);

  @override
  List<E> toList({bool growable = true}) => $value.toList(growable: growable);

  @override
  Set<E> toSet() => $value.toSet();

  @override
  Iterable<E> where(bool Function(E element) test) => $value.where(test);

  @override
  Iterable<T> whereType<T>() => $value.whereType<T>();

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.iterable);
}
