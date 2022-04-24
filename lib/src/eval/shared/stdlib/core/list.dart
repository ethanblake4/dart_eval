part of 'collection.dart';

class $List<E> implements List<E>, $Instance {
  $List(String id, List<E> value) : $value = runtimeOverride(id) as List<E>? ?? value;

  $List.wrap(this.$value);

  @override
  final List<E> $value;

  late final $Iterable $super = $Iterable.wrap($value);

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
    return $super.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw EvalUnknownPropertyException(identifier);
  }

  static const $Function __indexGet = $Function(_indexGet);

  static $Value? _indexGet(Runtime runtime, $Value? target, List<$Value?> args) {
    final idx = args[0]!;
    return (target!.$value as List)[idx.$value];
  }

  static const $Function __indexSet = $Function(_indexSet);

  static $Value? _indexSet(Runtime runtime, $Value? target, List<$Value?> args) {
    final idx = args[0]!;
    final value = args[1]!;
    return (target!.$value as List)[idx.$value] = value;
  }

  @override
  List get $reified => $value.map((e) => e is $Value ? e.$reified : e).toList().cast();

  @override
  bool any(bool Function(E element) test) => $value.any(test);

  @override
  List<R> cast<R>() => $value.cast<R>();

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
  Map<int, E> asMap() => $value.asMap();

  @override
  void replaceRange(int start, int end, Iterable<E> replacements) => $value.replaceRange(start, end, replacements);

  @override
  void fillRange(int start, int end, [E? fillValue]) => $value.fillRange(start, end, fillValue);

  @override
  void removeRange(int start, int end) => $value.removeRange(start, end);

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) =>
      $value.setRange(start, end, iterable, skipCount);

  @override
  Iterable<E> getRange(int start, int end) => $value.getRange(start, end);

  @override
  List<E> sublist(int start, [int? end]) => $value.sublist(start, end);

  @override
  List<E> operator +(List<E> other) => $value + other;

  @override
  void retainWhere(bool Function(E element) test) => $value.retainWhere(test);

  @override
  void removeWhere(bool Function(E element) test) => $value.removeWhere(test);

  @override
  E removeLast() => $value.removeLast();

  @override
  E removeAt(int index) => $value.removeAt(index);

  @override
  bool remove(Object? value) => $value.remove(value);

  @override
  void setAll(int index, Iterable<E> iterable) => $value.setAll(index, iterable);

  @override
  void insertAll(int index, Iterable<E> iterable) => $value.insertAll(index, iterable);

  @override
  void insert(int index, E element) => $value.insert(index, element);

  @override
  void clear() => $value.clear();

  @override
  int lastIndexOf(E element, [int? start]) => $value.lastIndexOf(element, start);

  @override
  int lastIndexWhere(bool Function(E element) test, [int? start]) => $value.lastIndexWhere(test, start);

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) => $value.indexWhere(test, start);

  @override
  int indexOf(E element, [int start = 0]) => $value.indexOf(element, start);

  @override
  void shuffle([Random? random]) => $value.shuffle(random);

  @override
  void sort([int Function(E a, E b)? compare]) => $value.sort(compare);

  @override
  Iterable<E> get reversed => $value.reversed;

  @override
  void addAll(Iterable<E> iterable) => $value.addAll(iterable);

  @override
  void add(E value) => $value.add(value);

  @override
  set length(int newLength) => $value.length = newLength;

  @override
  set last(E value) => $value.last = value;

  @override
  set first(E value) => $value.first = value;

  @override
  void operator []=(int index, E value) => $value[index] = value;

  @override
  E operator [](int index) => $value[index];

  @override
  int get $runtimeType => RuntimeTypes.listType;
}

$Function get$List_filled(Runtime _) => _$List_filled;

const _$List_filled = $Function(_List_filled);

$Value? _List_filled(Runtime runtime, $Value? target, List<$Value?> args) {
  return $List.wrap(List.filled(args[0]!.$value, args[1]));
}

$Function get$List_generate(Runtime _) => _$List_generate;

const _$List_generate = $Function(_List_generate);

$Value? _List_generate(Runtime runtime, $Value? target, List<$Value?> args) {
  return $List.wrap(List.generate(args[0]!.$value, args[1]!.$value, growable: args[2]?.$value ?? true));
}
