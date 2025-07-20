part of 'collection.dart';

/// dart_eval bimodal wrapper for [Iterable]
class $Iterable<E> implements Iterable<E>, $Instance {
  /// Configure the [$Iterable] wrapper for use in a [Runtime]
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Iterable.generate', __$Iterable$generate.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Iterable.empty', __$Iterable$empty.call,
        isBridge: false);
    runtime.registerBridgeFunc($type.spec!.library, 'Iterable.castFrom',
        __$static$method$castFrom.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'Iterable.iterableToShortString',
        __$static$method$iterableToShortString.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'Iterable.iterableToFullString',
        __$static$method$iterableToFullString.call,
        isBridge: false);
  }

  late final $Instance _superclass = $Object($value);

  static const $type = BridgeTypeRef(CoreTypes.iterable);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      generics: {'E': BridgeGenericParam()},
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [],
          namedParams: [],
        ),
        isFactory: false,
      ),
      'generate': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
                'count',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                    nullable: false),
                false),
            BridgeParameter(
                'generator',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                    nullable: true),
                true)
          ],
          namedParams: [],
          generics: {'E': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
      'empty': BridgeConstructorDef(
        BridgeFunctionDef(
            returns: BridgeTypeAnnotation($type),
            params: [],
            namedParams: [],
            generics: {'E': BridgeGenericParam()}),
        isFactory: true,
      )
    },
    fields: {},
    methods: {
      'castFrom': BridgeMethodDef(
          BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.iterable, [
                    BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
                  ]),
                  nullable: false),
              params: [
                BridgeParameter(
                    'source',
                    BridgeTypeAnnotation(
                        BridgeTypeRef(CoreTypes.iterable, [
                          BridgeTypeAnnotation(BridgeTypeRef.ref('S', [])),
                        ]),
                        nullable: false),
                    false)
              ],
              namedParams: [],
              generics: {
                'S': BridgeGenericParam(),
                'T': BridgeGenericParam(),
              }),
          isStatic: true),
      'iterableToShortString': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'iterable',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'leftDelimiter',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  true),
              BridgeParameter(
                  'rightDelimiter',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: true),
      'iterableToFullString': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'iterable',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'leftDelimiter',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  true),
              BridgeParameter(
                  'rightDelimiter',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: true),
      'cast': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('R', [])),
                ]),
                nullable: false),
            params: [],
            namedParams: [],
            generics: {'R': BridgeGenericParam()},
          ),
          isStatic: false),
      'followedBy': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'other',
                  BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.iterable, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                      ]),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'map': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'toElement',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
            generics: {'T': BridgeGenericParam()},
          ),
          isStatic: false),
      'where': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'whereType': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
                ]),
                nullable: false),
            params: [],
            namedParams: [],
            generics: {'T': BridgeGenericParam()},
          ),
          isStatic: false),
      'expand': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'toElements',
                  BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.iterable, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
                      ]),
                      nullable: false),
                  false)
            ],
            namedParams: [],
            generics: {'T': BridgeGenericParam()},
          ),
          isStatic: false),
      'contains': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'element',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, []),
                      nullable: true),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'forEach': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'action',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'reduce': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                nullable: false),
            params: [
              BridgeParameter(
                  'combine',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'fold': BridgeMethodDef(
          BridgeFunctionDef(
              returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T', []),
                  nullable: false),
              params: [
                BridgeParameter(
                    'initialValue',
                    BridgeTypeAnnotation(BridgeTypeRef.ref('T', []),
                        nullable: false),
                    false),
                BridgeParameter(
                    'combine',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                        nullable: false),
                    false)
              ],
              namedParams: [],
              generics: {
                'T': BridgeGenericParam()
              }),
          isStatic: false),
      'every': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'join': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'separator',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'any': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'toList': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false),
            params: [],
            namedParams: [
              BridgeParameter(
                  'growable',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                      nullable: false),
                  true)
            ],
          ),
          isStatic: false),
      'toSet': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'take': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'count',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'takeWhile': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'skip': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'count',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'skipWhile': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'firstWhere': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                nullable: false),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  false)
            ],
            namedParams: [
              BridgeParameter(
                  'orElse',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                      nullable: false),
                  true)
            ],
          ),
          isStatic: false),
      'lastWhere': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                nullable: false),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  false)
            ],
            namedParams: [
              BridgeParameter(
                  'orElse',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function),
                      nullable: false),
                  true)
            ],
          ),
          isStatic: false),
      'singleWhere': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                nullable: false),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  false)
            ],
            namedParams: [
              BridgeParameter(
                  'orElse',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: false),
                  true)
            ],
          ),
          isStatic: false),
      'elementAt': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                nullable: false),
            params: [
              BridgeParameter(
                  'index',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
    },
    getters: {
      'iterator': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterator, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'length': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'isEmpty': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'isNotEmpty': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'first': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'last': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'single': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
    },
    setters: {},
    bridge: false,
    wrap: true,
  );

  /// Wrap an [Iterable] in an [$Iterable]
  $Iterable.wrap(this.$value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'iterator':
        return $Iterator.wrap($value.iterator);
      case 'length':
        return $int($value.length);
      case 'isEmpty':
        return $bool($value.isEmpty);
      case 'isNotEmpty':
        return $bool($value.isNotEmpty);
      case 'first':
        return $value.first as $Value?;
      case 'last':
        return $value.last as $Value?;
      case 'single':
        return $value.single as $Value?;
      case 'cast':
        return __$cast;
      case 'followedBy':
        return __$followedBy;
      case 'map':
        return __$map;
      case 'where':
        return __$where;
      case 'whereType':
        return __$whereType;
      case 'expand':
        return __$expand;
      case 'contains':
        return __$contains;
      case 'forEach':
        return __$forEach;
      case 'reduce':
        return __$reduce;
      case 'fold':
        return __$fold;
      case 'every':
        return __$every;
      case 'join':
        return __$join;
      case 'any':
        return __$any;
      case 'toList':
        return __$toList;
      case 'toSet':
        return __$toSet;
      case 'take':
        return __$take;
      case 'takeWhile':
        return __$takeWhile;
      case 'skip':
        return __$skip;
      case 'skipWhile':
        return __$skipWhile;
      case 'firstWhere':
        return __$firstWhere;
      case 'lastWhere':
        return __$lastWhere;
      case 'singleWhere':
        return __$singleWhere;
      case 'elementAt':
        return __$elementAt;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  Iterable<E> get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  final Iterable<E> $value;

  @override
  Iterator<E> get iterator => $value.iterator;

  @override
  int get length => $value.length;

  @override
  bool get isEmpty => $value.isEmpty;

  @override
  bool get isNotEmpty => $value.isNotEmpty;

  @override
  E get first => $value.first;

  @override
  E get last => $value.last;

  @override
  E get single => $value.single;

  @override
  Iterable<R> cast<R>() => $value.cast();
  static const __$cast = $Function(_$cast);
  static $Value? _$cast(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final $result = $this.cast();
    return $Iterable.wrap($result);
  }

  @override
  Iterable<E> followedBy(Iterable<E> other) => $value.followedBy(other);
  static const __$followedBy = $Function(_$followedBy);
  static $Value? _$followedBy(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final other = args[0]?.$value as Iterable;
    final $result = $this.followedBy(other);
    return $Iterable.wrap($result);
  }

  @override
  Iterable<T> map<T>(T Function(E e) toElement) => $value.map(toElement);
  static const __$map = $Function(_$map);
  static $Value? _$map(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final toElement = args[0] as EvalCallable;
    final $result = $this.map((e) => toElement.call(runtime, null, [e]));
    return $Iterable.wrap($result);
  }

  @override
  Iterable<E> where(bool Function(E element) test) => $value.where(test);
  static const __$where = $Function(_$where);
  static $Value? _$where(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final test = args[0] as EvalCallable;
    final $result = $this.where(
      (element) =>
          test.call(runtime, null, [element as $Value?])!.$value as bool,
    );
    return $Iterable.wrap($result);
  }

  @override
  Iterable<T> whereType<T>() => $value.whereType();
  static const __$whereType = $Function(_$whereType);
  static $Value? _$whereType(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final $result = $this.whereType();
    return $Iterable.wrap($result);
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) toElements) =>
      $value.expand(toElements);
  static const __$expand = $Function(_$expand);
  static $Value? _$expand(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final toElements = args[0] as EvalCallable;
    final $result = $this.expand(
      (element) =>
          toElements.call(runtime, null, [element])!.$value as Iterable,
    );
    return $Iterable.wrap($result);
  }

  @override
  bool contains(Object? element) => $value.contains(element);
  static const __$contains = $Function(_$contains);
  static $Value? _$contains(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final element = args[0];
    final $result = $this.contains(element);
    return $bool($result);
  }

  @override
  void forEach(void Function(E element) action) => $value.forEach(action);
  static const __$forEach = $Function(_$forEach);
  static $Value? _$forEach(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final action = args[0] as EvalCallable;
    for (var element in $this) {
      action.call(runtime, null, [element]);
    }
    return null;
  }

  @override
  E reduce(E Function(E value, E element) combine) => $value.reduce(combine);
  static const __$reduce = $Function(_$reduce);
  static $Value? _$reduce(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final combine = args[0] as EvalCallable;
    final $result = $this.reduce(
      (value, element) => combine.call(runtime, null, [value, element]),
    );
    return $result;
  }

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      $value.fold(initialValue, combine);
  static const __$fold = $Function(_$fold);
  static $Value? _$fold(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final initialValue = args[0];
    final combine = args[1] as EvalCallable;
    final $result = $this.fold(
      initialValue,
      (previousValue, element) =>
          combine.call(runtime, null, [previousValue, element]),
    );
    return $result;
  }

  @override
  bool every(bool Function(E element) test) => $value.every(test);
  static const __$every = $Function(_$every);
  static $Value? _$every(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final test = args[0] as EvalCallable;
    final $result = $this.every(
      (element) => test.call(runtime, null, [element])!.$value as bool,
    );
    return $bool($result);
  }

  @override
  String join([String separator = ""]) => $value.join(separator);
  static const __$join = $Function(_$join);
  static $Value? _$join(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final separator = args[0]?.$value as String? ?? "";
    final $result = $this
        .map((v) => v is $Value ? runtime.valueToString(v) : v)
        .join(separator);
    return $String($result);
  }

  @override
  bool any(bool Function(E element) test) => $value.any(test);
  static const __$any = $Function(_$any);
  static $Value? _$any(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final test = args[0] as EvalCallable;
    final $result = $this.any(
      (element) => test.call(runtime, null, [element])!.$value as bool,
    );
    return $bool($result);
  }

  @override
  List<E> toList({bool growable = true}) => $value.toList(growable: growable);
  static const __$toList = $Function(_$toList);
  static $Value? _$toList(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final growable = args[0]?.$value as bool? ?? true;
    final $result = $this.toList(growable: growable);
    return $List.wrap($result);
  }

  @override
  Set<E> toSet() => $value.toSet();
  static const __$toSet = $Function(_$toSet);
  static $Value? _$toSet(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final $result = $this.toList();
    return $List.wrap($result);
  }

  @override
  Iterable<E> take(int count) => $value.take(count);
  static const __$take = $Function(_$take);
  static $Value? _$take(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final count = args[0]?.$value as int;
    final $result = $this.take(count);
    return $Iterable.wrap($result);
  }

  @override
  Iterable<E> takeWhile(bool Function(E value) test) => $value.takeWhile(test);
  static const __$takeWhile = $Function(_$takeWhile);
  static $Value? _$takeWhile(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final test = args[0] as EvalCallable;
    final $result = $this.takeWhile(
      (value) => test.call(runtime, null, [value])!.$value as bool,
    );
    return $Iterable.wrap($result);
  }

  @override
  Iterable<E> skip(int count) => $value.skip(count);
  static const __$skip = $Function(_$skip);
  static $Value? _$skip(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final count = args[0]?.$value as int;
    final $result = $this.skip(count);
    return $Iterable.wrap($result);
  }

  @override
  Iterable<E> skipWhile(bool Function(E value) test) => $value.skipWhile(test);
  static const __$skipWhile = $Function(_$skipWhile);
  static $Value? _$skipWhile(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final test = args[0] as EvalCallable;
    final $result = $this.skipWhile(
      (value) => test.call(runtime, null, [value])!.$value as bool,
    );
    return $Iterable.wrap($result);
  }

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      $value.firstWhere(test, orElse: orElse);
  static const __$firstWhere = $Function(_$firstWhere);
  static $Value? _$firstWhere(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final test = args[0] as EvalCallable;
    final orElse = args[1] as EvalCallable?;
    final $result = $this.firstWhere(
      (element) => test.call(runtime, null, [element])!.$value as bool,
      orElse: orElse == null ? null : () => orElse.call(runtime, null, [])!,
    );
    return $result;
  }

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      $value.lastWhere(test, orElse: orElse);
  static const __$lastWhere = $Function(_$lastWhere);
  static $Value? _$lastWhere(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final test = args[0] as EvalCallable;
    final orElse = args[1] as EvalCallable?;
    final $result = $this.lastWhere(
      (element) => test.call(runtime, null, [element])!.$value as bool,
      orElse: orElse == null ? null : () => orElse.call(runtime, null, [])!,
    );
    return $result;
  }

  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      $value.singleWhere(test, orElse: orElse);
  static const __$singleWhere = $Function(_$singleWhere);
  static $Value? _$singleWhere(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final test = args[0] as EvalCallable;
    final orElse = args[1] as EvalCallable?;
    final $result = $this.singleWhere(
      (element) => test.call(runtime, null, [element])!.$value as bool,
      orElse: orElse == null ? null : () => orElse.call(runtime, null, [])!,
    );
    return $result;
  }

  @override
  E elementAt(int index) => $value.elementAt(index);
  static const __$elementAt = $Function(_$elementAt);
  static $Value? _$elementAt(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Iterable;
    final index = args[0]?.$value as int;
    final $result = $this.elementAt(index);
    return $result;
  }

  static const __$static$method$castFrom = $Function(_$static$method$castFrom);
  static $Value? _$static$method$castFrom(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final source = (args[0]?.$reified as Iterable).cast();
    final $result = Iterable.castFrom(source);
    return $Iterable.wrap($result);
  }

  static const __$static$method$iterableToShortString =
      $Function(_$static$method$iterableToShortString);
  static $Value? _$static$method$iterableToShortString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final iterable = (args[0]?.$reified as Iterable).cast();
    final leftDelimiter = args[1]?.$value as String? ?? '(';
    final rightDelimiter = args[2]?.$value as String? ?? ')';
    final $result = Iterable.iterableToShortString(
      iterable,
      leftDelimiter,
      rightDelimiter,
    );
    return $String($result);
  }

  static const __$static$method$iterableToFullString =
      $Function(_$static$method$iterableToFullString);
  static $Value? _$static$method$iterableToFullString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final iterable = (args[0]?.$reified as Iterable).cast();
    final leftDelimiter = args[1]?.$value as String? ?? '(';
    final rightDelimiter = args[2]?.$value as String? ?? ')';
    final $result = Iterable.iterableToFullString(
      iterable,
      leftDelimiter,
      rightDelimiter,
    );
    return $String($result);
  }

  static const __$Iterable$generate = $Function(_$Iterable$generate);
  static $Value? _$Iterable$generate(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final count = args[0]?.$value as int;
    final generator = args[1] as EvalFunction? ??
        $Function((runtime, target, args) => args[0]);
    return $Iterable.wrap(Iterable.generate(
      count,
      (index) => generator.call(runtime, null, [$int(index)]),
    ));
  }

  static const __$Iterable$empty = $Function(_$Iterable$empty);
  static $Value? _$Iterable$empty(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $Iterable.wrap(Iterable.empty());
  }
}
