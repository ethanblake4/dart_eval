part of 'collection.dart';

/// dart_eval bimodal bridge wrapper for [List]
class $List<E> implements List<E>, $Instance {
  /// Configure the [$List] wrapper for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:core', 'List.filled', _$List_filled);
    runtime.registerBridgeFunc('dart:core', 'List.generate', _$List_generate);
  }

  /// Bridge class declaration for [$List]
  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.list),
          $extends: BridgeTypeRef(CoreTypes.iterable), generics: {'E': BridgeGenericParam()}),
      constructors: {
        'filled': BridgeConstructorDef(BridgeFunctionDef(
            params: [
              BridgeParameter('length', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
              BridgeParameter('fill', BridgeTypeAnnotation(BridgeTypeRef.ref('E')), false),
            ],
            namedParams: [
              BridgeParameter('growable', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType)), true),
            ],
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list, [BridgeTypeRef.ref('E')])),
            generics: {'E': BridgeGenericParam()})),
        'generate': BridgeConstructorDef(BridgeFunctionDef(
            params: [
              BridgeParameter('length', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
              BridgeParameter('generator', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.functionType)), false),
            ],
            namedParams: [
              BridgeParameter('growable', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType)), true),
            ],
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list, [BridgeTypeRef.ref('E')])),
            generics: {'E': BridgeGenericParam()})),
      },
      methods: {
        '[]': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('index', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
        ], returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')))),
        'contains': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('element', BridgeTypeAnnotation(BridgeTypeRef.ref('E')), false),
        ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType)))),
        '[]=': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('index', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
          BridgeParameter('value', BridgeTypeAnnotation(BridgeTypeRef.ref('E')), false),
        ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.voidType)))),
        'add': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('value', BridgeTypeAnnotation(BridgeTypeRef.ref('E')), false),
        ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.voidType)))),
        'lastIndexOf': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('element', BridgeTypeAnnotation(BridgeTypeRef.ref('E')), false),
          BridgeParameter(
              'start', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType), nullable: true), true),
        ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)))),
        'join': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('separator', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.stringType)), true),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.stringType))),
            isStatic: false),
        'indexOf': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('element', BridgeTypeAnnotation(BridgeTypeRef.ref('E')), false),
          BridgeParameter(
              'start', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType), nullable: true), true),
        ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)))),
        'elementAt': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('index', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
        ], returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')))),
        'remove': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('value', BridgeTypeAnnotation(BridgeTypeRef.ref('E')), false),
        ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType)))),
        'removeAt': BridgeMethodDef(BridgeFunctionDef(
          params: [
            BridgeParameter('index', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
        )),
        'removeLast': BridgeMethodDef(BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
        )),
        'insert': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('index', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
          BridgeParameter('element', BridgeTypeAnnotation(BridgeTypeRef.ref('E')), false),
        ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.voidType)))),
        'toSet': BridgeMethodDef(BridgeFunctionDef(
            params: [], returns: BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable'))))),
        'map': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('toElement', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.functionType)), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable')))),
            isStatic: false),
        'followedBy': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter(
                  'other', BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable'))), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable')))),
            isStatic: false),
        'getRange': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('start', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
              BridgeParameter('end', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable')))),
            isStatic: false),
        'where': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('test', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.functionType)), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable')))),
            isStatic: false),
        'skipWhile': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('test', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.functionType)), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable')))),
            isStatic: false),
        'takeWhile': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('test', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.functionType)), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable')))),
            isStatic: false),
        'sort': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('compare', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.functionType)), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.voidType))),
            isStatic: false),
        'retainWhere': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('test', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.functionType)), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.voidType))),
            isStatic: false),
        'replaceRange': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('start', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
              BridgeParameter('end', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
              BridgeParameter(
                  'replacements', BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable'))), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.voidType))),
            isStatic: false),
        'sublist': BridgeMethodDef(
            BridgeFunctionDef(
                params: [
                  BridgeParameter('start', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
                  BridgeParameter(
                      'end', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType), nullable: true), true),
                ],
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeRef.ref('E'),
                ]))),
            isStatic: false),
        'any': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('test', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.functionType)), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType))),
            isStatic: false),
        'every': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('test', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.functionType)), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType))),
            isStatic: false),
        'skip': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('count', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable')))),
            isStatic: false),
        'take': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter('count', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable')))),
            isStatic: false),
        'asMap': BridgeMethodDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.mapType))),
            isStatic: false),
        'toString': BridgeMethodDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.stringType))),
            isStatic: false),
        'clear': BridgeMethodDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.voidType))),
            isStatic: false),
        'addAll': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter(
              'iterable', BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable'))), false),
        ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.voidType)))),
        'insertAll': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('index', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false),
          BridgeParameter(
              'iterable', BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable'))), false),
        ], returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.voidType)))),
      },
      getters: {
        'length':
            BridgeMethodDef(BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)))),
        'hashCode':
            BridgeMethodDef(BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)))),
        'iterator': BridgeMethodDef(
            BridgeFunctionDef(
                params: [],
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterator, [
                  BridgeTypeRef.ref('E'),
                ]))),
            isStatic: false),
        'reversed': BridgeMethodDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable')))),
            isStatic: false),
        'first': BridgeMethodDef(BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')))),
        'last': BridgeMethodDef(BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')))),
        'isEmpty': BridgeMethodDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType)))),
        'isNotEmpty': BridgeMethodDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType)))),
      },
      setters: {},
      fields: {},
      wrap: true);

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
      case 'add':
        return __add;
      case 'length':
        return $int($value.length);
      case 'addAll':
        return __addAll;
      case 'first':
        return $super.first;
      case 'contains':
        return __listContains;
      case 'map':
        return __map;
      case 'where':
        return __where;
      case 'isEmpty':
        return $bool($super.isEmpty);
      case 'isNotEmpty':
        return $bool($super.isNotEmpty);
      case 'last':
        return $super.last;
      case 'reversed':
        return $Iterable.wrap($value.reversed);
      case 'toSet':
        return __toSet;
      case 'iterator':
        return $Iterator.wrap($value.iterator);
      case 'insert':
        return __insert;
      case 'insertAll':
        return __insertAll;
      case 'remove':
        return __remove;
      case 'any':
        return __any;
      case 'asMap':
        return __asMap;
      case 'hashCode':
        return $int($value.hashCode);
      case 'lastIndexOf':
        return __lastIndexOf;
      case 'indexOf':
        return __indexOf;
      case 'elementAt':
        return __elementAt;
      case 'every':
        return __every;
      case 'retainWhere':
        return __retainWhere;
      case 'replaceRange':
        return __replaceRange;
      case 'followedBy':
        return __followedBy;
      case 'getRange':
        return __getRange;
      case 'join':
        return __join;
      case 'sort':
        return __sort;
      case 'removeAt':
        return __removeAt;
      case 'removeLast':
        return __removeLast;
      case 'skip':
        return __skip;
      case 'skipWhile':
        return __skipWhile;
      case 'sublist':
        return __sublist;
      case 'take':
        return __take;
      case 'takeWhile':
        return __takeWhile;
      case 'toString':
        return __toString;
      case 'clear':
        return __clear;
    }
    return $super.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw EvalUnknownPropertyException(identifier);
  }

  static const $Function __map = $Function(_map);

  static $Value? _map(Runtime runtime, $Value? target, List<$Value?> args) {
    final toElement = args[0] as EvalCallable;
    return $Iterable.wrap((target!.$value as Iterable).map((e) => toElement.call(runtime, null, [e])!.$value));
  }

  static const $Function __followedBy = $Function(_followedBy);

  static $Value? _followedBy(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Iterable.wrap((target!.$value as Iterable).followedBy(args[0]!.$value as Iterable));
  }

  static const $Function __getRange = $Function(_getRange);

  static $Value? _getRange(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Iterable.wrap((target!.$value as List).getRange(args[0]!.$value, args[1]!.$value));
  }

  static const $Function __where = $Function(_where);

  static $Value? _where(Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    return $Iterable.wrap((target!.$value as Iterable).where((e) => test.call(runtime, null, [e])!.$value as bool));
  }

  static const $Function __skipWhile = $Function(_skipWhile);

  static $Value? _skipWhile(Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    return $Iterable.wrap((target!.$value as List).skipWhile((e) => test.call(runtime, null, [e])!.$value as bool));
  }

  static const $Function __takeWhile = $Function(_takeWhile);

  static $Value? _takeWhile(Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    return $Iterable.wrap((target!.$value as List).takeWhile((e) => test.call(runtime, null, [e])!.$value as bool));
  }

  static const $Function __toString = $Function(_toString);

  static $Value? _toString(Runtime runtime, $Value? target, List<$Value?> args) {
    return $String((target!.$value as List).toString());
  }

  static const $Function __clear = $Function(_clear);

  static $Value? _clear(Runtime runtime, $Value? target, List<$Value?> args) {
    (target!.$value as List).clear();
    return null;
  }

  static const $Function __retainWhere = $Function(_retainWhere);

  static $Value? _retainWhere(Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    (target!.$value as List).retainWhere((e) => test.call(runtime, null, [e])!.$value as bool);
    return null;
  }

  static const $Function __replaceRange = $Function(_replaceRange);

  static $Value? _replaceRange(Runtime runtime, $Value? target, List<$Value?> args) {
    (target!.$value as List).replaceRange(args[0]!.$value, args[1]!.$value, args[2]!.$value as Iterable);
    return null;
  }

  static const $Function __lastIndexOf = $Function(_lastIndexOf);

  static $Value? _lastIndexOf(Runtime runtime, $Value? target, List<$Value?> args) {
    return $int((target!.$value as List).lastIndexOf(args[0], args[1]?.$value));
  }

  static const $Function __indexOf = $Function(_indexOf);

  static $Value? _indexOf(Runtime runtime, $Value? target, List<$Value?> args) {
    return $int((target!.$value as List).indexOf(args[0], args[1]?.$value ?? 0));
  }

  static const $Function __elementAt = $Function(_elementAt);

  static $Value? _elementAt(Runtime runtime, $Value? target, List<$Value?> args) {
    return (target!.$value as List).elementAt(args[0]!.$value);
  }

  static const $Function __any = $Function(_any);

  static $Value? _any(Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    return $bool((target!.$value as List).any((e) => test.call(runtime, null, [e])!.$value as bool));
  }

  static const $Function __every = $Function(_every);

  static $Value? _every(Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    return $bool((target!.$value as List).every((e) => test.call(runtime, null, [e])!.$value as bool));
  }

  static const $Function __sort = $Function(_sort);

  static $Value? _sort(Runtime runtime, $Value? target, List<$Value?> args) {
    final compare = args[0] as EvalCallable;

    (target!.$value as List).sort(
      (a, b) => compare.call(runtime, null, [a, b])?.$value,
    );
    return null;
  }

  static const $Function __addAll = $Function(_addAll);

  static $Value? _addAll(Runtime runtime, $Value? target, List<$Value?> args) {
    (target!.$value as List).addAll(args[0]!.$value as Iterable);
    return null;
  }

  static const $Function __insertAll = $Function(_insertAll);

  static $Value? _insertAll(Runtime runtime, $Value? target, List<$Value?> args) {
    (target!.$value as List).insertAll(args[0]!.$value, args[1]!.$value as Iterable);
    return null;
  }

  static const $Function __indexGet = $Function(_indexGet);

  static $Value? _indexGet(Runtime runtime, $Value? target, List<$Value?> args) {
    final idx = args[0]!;
    return (target!.$value as List)[idx.$value];
  }

  static const $Function __join = $Function(_join);

  static $Value? _join(Runtime runtime, $Value? target, List<$Value?> args) {
    final separator = args[0]?.$value ?? '';
    return $String((target!.$value as List).join(separator));
  }

  static const $Function __sublist = $Function(_sublist);

  static $Value? _sublist(Runtime runtime, $Value? target, List<$Value?> args) {
    return $List.wrap((target!.$value as List).sublist(args[0]!.$value, args[1]?.$value));
  }

  static const $Function __skip = $Function(_skip);

  static $Value? _skip(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Iterable.wrap((target!.$value as List).skip(args[0]!.$value));
  }

  static const $Function __take = $Function(_take);

  static $Value? _take(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Iterable.wrap((target!.$value as List).take(args[0]!.$value));
  }

  static const $Function __listContains = $Function(_listContains);

  static $Value? _listContains(Runtime runtime, $Value? target, List<$Value?> args) {
    return $bool((target!.$value as List).contains(args[0]));
  }

  static const $Function __indexSet = $Function(_indexSet);

  static $Value? _indexSet(Runtime runtime, $Value? target, List<$Value?> args) {
    final idx = args[0]!;
    final value = args[1]!;
    return (target!.$value as List)[idx.$value] = value;
  }

  static const $Function __insert = $Function(_insert);

  static $Value? _insert(Runtime runtime, $Value? target, List<$Value?> args) {
    final idx = args[0]!;
    final value = args[1]!;
    (target!.$value as List).insert(idx.$value, value);
    return null;
  }

  static const $Function __remove = $Function(_remove);

  static $Value? _remove(Runtime runtime, $Value? target, List<$Value?> args) {
    return $bool((target!.$value as List).remove(args[0]!));
  }

  static const $Function __removeAt = $Function(_removeAt);

  static $Value? _removeAt(Runtime runtime, $Value? target, List<$Value?> args) {
    return (target!.$value as List).removeAt(args[0]!.$value) as $Value?;
  }

  static const $Function __removeLast = $Function(_removeLast);

  static $Value? _removeLast(Runtime runtime, $Value? target, List<$Value?> args) {
    return (target!.$value as List).removeLast() as $Value?;
  }

  static const $Function __add = $Function(_add);

  static $Value? _add(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = args[0]!;
    (target!.$value as List).add(value);
    return null;
  }

  static const $Function __asMap = $Function(_asMap);

  static $Value? _asMap(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Map.wrap((target!.$value as List).asMap());
  }

  static const $Function __toSet = $Function(_toSet);

  static $Value? _toSet(Runtime runtime, $Value? target, List<$Value?> args) {
    return $List.wrap((target!.$value as List).toSet().toList());
  }

  @override
  List get $reified => $value.map((e) => e is $Value ? e.$reified : e).toList();

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
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.list);
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
