part of 'collection.dart';

class $Iterable$bridge<E> with $Bridge<Iterable<E>> implements Iterable<E> {
  const $Iterable$bridge(List<Object?> _);

  @override
  Iterable<E> get $reified => ($value as $Iterable$bridge).map((e) => e.$reified);

  static const $type = BridgeTypeRef.spec(BridgeTypeSpec('dart:core', 'Iterable'));

  static const $classDef =
      BridgeClassDef(BridgeClassType($type, isAbstract: true), constructors: {}, methods: {}, getters: {
    'length': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), params: [], namedParams: []))
  }, setters: {}, fields: {});

  static const runtime$fields = <String, $BridgeField>{
    'length': $BridgeField(_length, null),
  };

  static const $Function _length = $Function(__length);

  static $Value? __length(Runtime runtime, $Value? target, List<$Value?> args) {
    return $int((target!.$value as Iterable).length);
  }

  @override
  $Value? $bridgeGet(String identifier) {
    switch (identifier) {
    }
    throw UnimplementedError();
  }

  @override
  void $bridgeSet(String identifier, $Value value) {
    throw UnimplementedError();
  }

  @override
  bool any(bool Function(E element) test) =>
      $_invoke('any', [$Function((_, __, args) => $bool(test(args[0]!.$value)))]);

  @override
  Iterable<R> cast<R>() => Iterable.castFrom<E, R>(this);

  @override
  bool contains(Object? element) =>
      $_invoke('contains', [element == null ? $null() : $ValueImpl(RuntimeTypes.objectType, element)]);

  @override
  E elementAt(int index) => $_invoke('elementAt', [$int(index)]);

  @override
  bool every(bool Function(E element) test) =>
      $_invoke('every', [$Function((_, __, args) => $bool(test(args[0]!.$value)))]);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) toElements) =>
      $_invoke('expand', [$Function((runtime, target, args) => $Iterable.wrap(toElements(args[0]!.$value)))]);

  @override
  E get first => $_get('first');

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) {
    // TODO: implement firstWhere
    throw UnimplementedError();
  }

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) {
    // TODO: implement fold
    throw UnimplementedError();
  }

  @override
  Iterable<E> followedBy(Iterable<E> other) {
    // TODO: implement followedBy
    throw UnimplementedError();
  }

  @override
  void forEach(void Function(E element) action) {
    // TODO: implement forEach
  }

  @override
  // TODO: implement isEmpty
  bool get isEmpty => throw UnimplementedError();

  @override
  // TODO: implement isNotEmpty
  bool get isNotEmpty => throw UnimplementedError();

  @override
  // TODO: implement iterator
  Iterator<E> get iterator => throw UnimplementedError();

  @override
  String join([String separator = '']) {
    // TODO: implement join
    throw UnimplementedError();
  }

  @override
  // TODO: implement last
  E get last => throw UnimplementedError();

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) {
    // TODO: implement lastWhere
    throw UnimplementedError();
  }

  @override
  // TODO: implement length
  int get length => throw UnimplementedError();

  @override
  Iterable<T> map<T>(T Function(E e) toElement) {
    // TODO: implement map
    throw UnimplementedError();
  }

  @override
  E reduce(E Function(E value, E element) combine) {
    // TODO: implement reduce
    throw UnimplementedError();
  }

  @override
  // TODO: implement single
  E get single => throw UnimplementedError();

  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) {
    // TODO: implement singleWhere
    throw UnimplementedError();
  }

  @override
  Iterable<E> skip(int count) {
    // TODO: implement skip
    throw UnimplementedError();
  }

  @override
  Iterable<E> skipWhile(bool Function(E value) test) {
    // TODO: implement skipWhile
    throw UnimplementedError();
  }

  @override
  Iterable<E> take(int count) {
    // TODO: implement take
    throw UnimplementedError();
  }

  @override
  Iterable<E> takeWhile(bool Function(E value) test) {
    // TODO: implement takeWhile
    throw UnimplementedError();
  }

  @override
  List<E> toList({bool growable = true}) {
    // TODO: implement toList
    throw UnimplementedError();
  }

  @override
  Set<E> toSet() {
    // TODO: implement toSet
    throw UnimplementedError();
  }

  @override
  Iterable<E> where(bool Function(E element) test) {
    // TODO: implement where
    throw UnimplementedError();
  }

  @override
  Iterable<T> whereType<T>() {
    // TODO: implement whereType
    throw UnimplementedError();
  }

  @override
  int get $runtimeType => RuntimeTypes.iterableType;
}

class $Iterable<E> implements Iterable<E>, $Instance {
  $Iterable(String id, Iterable<E> value) : $value = runtimeOverride(id) as Iterable<E>? ?? value;

  $Iterable.wrap(this.$value);

  @override
  final Iterable<E> $value;

  @override
  Iterable<E> get $reified => $value;

  late final $Instance _superclass = $Object($value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'join':
        return $Function(__join);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    // TODO: implement $setProperty
  }

  static const $Function __join = $Function(_join);

  static $Value? _join(Runtime runtime, $Value? target, List<$Value?> args) {
    final separator = (args[0] as String?) ?? '';
    return $String((target!.$value as Iterable).join(separator));
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
  Iterable<T> expand<T>(Iterable<T> Function(E element) toElements) => $value.expand<T>(toElements);

  @override
  E get first => $value.first;

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) => $value.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) => $value.fold(initialValue, combine);

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
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) => $value.lastWhere(test, orElse: orElse);

  @override
  int get length => $value.length;

  @override
  Iterable<T> map<T>(T Function(E e) toElement) => $value.map(toElement);

  @override
  E reduce(E Function(E value, E element) combine) => $value.reduce(combine);

  @override
  E get single => $value.single;

  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) => $value.singleWhere(test, orElse: orElse);

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
  int get $runtimeType => RuntimeTypes.iterableType;
}
