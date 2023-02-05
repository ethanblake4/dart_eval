part of 'collection.dart';

class $Iterable<E> implements Iterable<E>, $Instance {
  static void configureForCompile(Compiler compiler) {
    compiler.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    //runtime.registerBridgeFunc('dart:core', 'Future.delayed', const _$Future_delayed());
  }

  static const $type = BridgeTypeRef.spec(BridgeTypeSpec('dart:core', 'Iterable'));

  static const $declaration = BridgeClassDef(BridgeClassType($type, generics: {'E': BridgeGenericParam()}),
      constructors: {},
      methods: {
        'join': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('separator', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.stringType)), true),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.stringType))),
            isStatic: false),
        'map': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('toElement', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.functionType)), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef.spec(BridgeTypeSpec('dart:core', 'Iterable')))),
            isStatic: false),
      },
      getters: {
        'iterator': BridgeMethodDef(
            BridgeFunctionDef(
                params: [],
                returns: BridgeTypeAnnotation(BridgeTypeRef.spec(BridgeTypeSpec('dart:core', 'Iterator'), [
                  BridgeTypeRef.ref('E'),
                ]))),
            isStatic: false),
      },
      setters: {},
      fields: {},
      wrap: true);

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
      case 'map':
        return $Function(__map);
      case 'iterator':
        return $Iterator.wrap($value.iterator);
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

  static const $Function __map = $Function(_map);

  static $Value? _map(Runtime runtime, $Value? target, List<$Value?> args) {
    final toElement = args[0] as EvalCallable;
    return $Iterable.wrap((target!.$value as Iterable).map((e) => toElement.call(runtime, null, [e])!.$value));
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
  int get $runtimeType => throw UnimplementedError();
}
