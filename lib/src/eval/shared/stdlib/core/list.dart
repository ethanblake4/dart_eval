part of 'collection.dart';

/// dart_eval bimodal wrapper for [List]
class $List<E> implements List<E>, $Instance {
  /// Configure the [$List] wrapper for use in a [Runtime]
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        $type.spec!.library, 'List.filled', __$List$filled.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'List.empty', __$List$empty.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'List.from', __$List$from.call,
        isBridge: false);
    runtime.registerBridgeFunc($type.spec!.library, 'List.of', __$List$of.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'List.generate', __$List$generate.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'List.unmodifiable', __$List$unmodifiable.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'List.castFrom', __$static$method$castFrom.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'List.copyRange', __$static$method$copyRange.call,
        isBridge: false);
    runtime.registerBridgeFunc($type.spec!.library, 'List.writeIterable',
        __$static$method$writeIterable.call,
        isBridge: false);
  }

  late final $Iterable _superclass = $Iterable.wrap($value);

  static const $type = BridgeTypeRef(CoreTypes.list);

  static const $declaration = BridgeClassDef(
    BridgeClassType($type,
        $extends: BridgeTypeRef(CoreTypes.iterable),
        generics: {'E': BridgeGenericParam()}),
    constructors: {
      'filled': BridgeConstructorDef(
        BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
          BridgeParameter(
              'length',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                  nullable: false),
              false),
          BridgeParameter(
              'fill',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', []), nullable: false),
              false)
        ], namedParams: [
          BridgeParameter(
              'growable',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                  nullable: false),
              true)
        ], generics: {
          'E': BridgeGenericParam()
        }),
        isFactory: true,
      ),
      'empty': BridgeConstructorDef(
        BridgeFunctionDef(
            returns: BridgeTypeAnnotation($type),
            params: [],
            namedParams: [
              BridgeParameter(
                  'growable',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                      nullable: false),
                  true)
            ],
            generics: {
              'E': BridgeGenericParam()
            }),
        isFactory: true,
      ),
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
                false)
          ],
          namedParams: [
            BridgeParameter(
                'growable',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                    nullable: false),
                true)
          ],
          generics: {'E': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
      'of': BridgeConstructorDef(
        BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
          BridgeParameter(
              'elements',
              BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.iterable, [
                    BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                  ]),
                  nullable: false),
              false)
        ], namedParams: [
          BridgeParameter(
              'growable',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                  nullable: false),
              true)
        ], generics: {
          'E': BridgeGenericParam()
        }),
        isFactory: true,
      ),
      'generate': BridgeConstructorDef(
        BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
          BridgeParameter(
              'length',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                  nullable: false),
              false),
          BridgeParameter(
              'generator',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                  nullable: false),
              false)
        ], namedParams: [
          BridgeParameter(
              'growable',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                  nullable: false),
              true)
        ], generics: {
          'E': BridgeGenericParam()
        }),
        isFactory: true,
      ),
      'unmodifiable': BridgeConstructorDef(
        BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
          BridgeParameter(
              'elements',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable, []),
                  nullable: false),
              false)
        ], namedParams: [], generics: {
          'E': BridgeGenericParam()
        }),
        isFactory: true,
      )
    },
    fields: {},
    methods: {
      'castFrom': BridgeMethodDef(
          BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.list, [
                    BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
                  ]),
                  nullable: false),
              params: [
                BridgeParameter(
                    'source',
                    BridgeTypeAnnotation(
                        BridgeTypeRef(CoreTypes.list, [
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
      'copyRange': BridgeMethodDef(
          BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType, []),
                  nullable: false),
              params: [
                BridgeParameter(
                    'target',
                    BridgeTypeAnnotation(
                        BridgeTypeRef(CoreTypes.list, [
                          BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
                        ]),
                        nullable: false),
                    false),
                BridgeParameter(
                    'at',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                        nullable: false),
                    false),
                BridgeParameter(
                    'source',
                    BridgeTypeAnnotation(
                        BridgeTypeRef(CoreTypes.list, [
                          BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
                        ]),
                        nullable: false),
                    false),
                BridgeParameter(
                    'start',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                        nullable: true),
                    true),
                BridgeParameter(
                    'end',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                        nullable: true),
                    true)
              ],
              namedParams: [],
              generics: {
                'T': BridgeGenericParam(),
              }),
          isStatic: true),
      'writeIterable': BridgeMethodDef(
          BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType, []),
                  nullable: false),
              params: [
                BridgeParameter(
                    'target',
                    BridgeTypeAnnotation(
                        BridgeTypeRef(CoreTypes.list, [
                          BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
                        ]),
                        nullable: false),
                    false),
                BridgeParameter(
                    'at',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                        nullable: false),
                    false),
                BridgeParameter(
                    'source',
                    BridgeTypeAnnotation(
                        BridgeTypeRef(CoreTypes.iterable, [
                          BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
                        ]),
                        nullable: false),
                    false)
              ],
              namedParams: [],
              generics: {
                'T': BridgeGenericParam(),
              }),
          isStatic: true),
      'cast': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('R', [])),
                ]),
                nullable: false),
            params: [],
            namedParams: [],
            generics: {'R': BridgeGenericParam()},
          ),
          isStatic: false),
      '[]': BridgeMethodDef(
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
      '[]=': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'index',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'value',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'add': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'value',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'addAll': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'iterable',
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
      'sort': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'compare',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                      nullable: true),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'shuffle': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'random',
                  BridgeTypeAnnotation(BridgeTypeRef(MathTypes.random, []),
                      nullable: true),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'indexOf': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'element',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'indexWhere': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'lastIndexWhere': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'test',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: true),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'lastIndexOf': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'element',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: true),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'clear': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'insert': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'index',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'element',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'insertAll': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'index',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'iterable',
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
      'setAll': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'index',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'iterable',
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
      'remove': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'value',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, []),
                      nullable: true),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'removeAt': BridgeMethodDef(
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
      'removeLast': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'removeWhere': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
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
      'retainWhere': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
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
      '+': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'other',
                  BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.list, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                      ]),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'sublist': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'end',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: true),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'getRange': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'end',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'setRange': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'end',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'iterable',
                  BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.iterable, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                      ]),
                      nullable: false),
                  false),
              BridgeParameter(
                  'skipCount',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'removeRange': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'end',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'fillRange': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'end',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'fillValue',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                      nullable: true),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'replaceRange': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'end',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'replacements',
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
      'asMap': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
    },
    getters: {
      'length': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'reversed': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
    },
    setters: {
      'first': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'value',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'last': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'value',
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'length': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'newLength',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
    },
    bridge: false,
    wrap: true,
  );

  /// Wrap an [List] in an [$List]
  $List.wrap(this.$value);

  /// Create a view of a [List] as a [$List] (supports writeback)
  factory $List.view(List<E> value, $Value Function(E value) mapper) =
      _$List$view;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'length':
        return $int($value.length);
      case 'reversed':
        return $Iterable.wrap($value.reversed);
      case 'cast':
        return __$cast;
      case '[]':
        return __$indexGet;
      case '[]=':
        return __$indexSet;
      case 'add':
        return __$add;
      case 'addAll':
        return __$addAll;
      case 'sort':
        return __$sort;
      case 'shuffle':
        return __$shuffle;
      case 'indexOf':
        return __$indexOf;
      case 'indexWhere':
        return __$indexWhere;
      case 'lastIndexWhere':
        return __$lastIndexWhere;
      case 'lastIndexOf':
        return __$lastIndexOf;
      case 'clear':
        return __$clear;
      case 'insert':
        return __$insert;
      case 'insertAll':
        return __$insertAll;
      case 'setAll':
        return __$setAll;
      case 'remove':
        return __$remove;
      case 'removeAt':
        return __$removeAt;
      case 'removeLast':
        return __$removeLast;
      case 'removeWhere':
        return __$removeWhere;
      case 'retainWhere':
        return __$retainWhere;
      case '+':
        return __$combine;
      case 'sublist':
        return __$sublist;
      case 'getRange':
        return __$getRange;
      case 'setRange':
        return __$setRange;
      case 'removeRange':
        return __$removeRange;
      case 'fillRange':
        return __$fillRange;
      case 'replaceRange':
        return __$replaceRange;
      case 'asMap':
        return __$asMap;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  List get $reified => $value.map((e) => e is $Value ? e.$reified : e).toList();

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      case 'first':
        first = value as E;
        break;
      case 'last':
        last = value as E;
        break;
      case 'length':
        length = value.$value as int;
        break;
      default:
        _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  final List<E> $value;

  @override
  int get length => $value.length;

  @override
  Iterable<E> get reversed => $value.reversed;

  @override
  set first(E value) {
    $value.first = value;
  }

  @override
  set last(E value) {
    $value.last = value;
  }

  @override
  set length(int newLength) {
    $value.length = newLength;
  }

  @override
  List<R> cast<R>() => $value.cast();
  static const __$cast = $Function(_$cast);
  static $Value? _$cast(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final $result = $this.cast();
    return $List.wrap($result);
  }

  @override
  E operator [](int index) => $value[index];
  static const __$indexGet = $Function(_$indexGet);
  static $Value? _$indexGet(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final index = args[0]?.$value as int;
    final $result = $this[index];
    return $result;
  }

  @override
  void operator []=(int index, E value) => $value[index] = value;
  static const __$indexSet = $Function(_$indexSet);
  static $Value? _$indexSet(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final index = args[0]?.$value as int;
    final value = args[1];
    $this[index] = value;
    return null;
  }

  @override
  void add(E value) => $value.add(value);
  static const __$add = $Function(_$add);
  static $Value? _$add(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final value = args[0];
    $this.add(value);
    return null;
  }

  @override
  void addAll(Iterable<E> iterable) => $value.addAll(iterable);
  static const __$addAll = $Function(_$addAll);
  static $Value? _$addAll(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final iterable = args[0]?.$value as Iterable;
    $this.addAll(iterable);
    return null;
  }

  @override
  void sort([int Function(E a, E b)? compare]) => $value.sort(compare);
  static const __$sort = $Function(_$sort);
  static $Value? _$sort(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final compare = args[0] as EvalFunction? ??
        $Function((runtime, target, args) =>
            $int(Comparable.compare(args[0]?.$value, args[0]?.$value)));
    $this.sort((a, b) => compare.call(runtime, null, [a, b])?.$value as int);
    return null;
  }

  @override
  void shuffle([Random? random]) => $value.shuffle(random);
  static const __$shuffle = $Function(_$shuffle);
  static $Value? _$shuffle(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final random = args[0]?.$value as Random?;
    $this.shuffle(random);
    return null;
  }

  @override
  int indexOf(E element, [int start = 0]) => $value.indexOf(element, start);
  static const __$indexOf = $Function(_$indexOf);
  static $Value? _$indexOf(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final element = args[0];
    final start = args[1]?.$value as int? ?? 0;
    final $result = $this.indexOf(element, start);
    return $int($result);
  }

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) =>
      $value.indexWhere(test, start);
  static const __$indexWhere = $Function(_$indexWhere);
  static $Value? _$indexWhere(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final test = args[0] as EvalCallable;
    final start = args[1]?.$value as int? ?? 0;
    final $result = $this.indexWhere(
      (element) => test.call(runtime, null, [element])!.$value as bool,
      start,
    );
    return $int($result);
  }

  @override
  int lastIndexWhere(bool Function(E element) test, [int? start]) =>
      $value.lastIndexWhere(test, start);
  static const __$lastIndexWhere = $Function(_$lastIndexWhere);
  static $Value? _$lastIndexWhere(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final test = args[0] as EvalCallable;
    final start = args[1]?.$value as int?;
    final $result = $this.lastIndexWhere(
      (element) => test.call(runtime, null, [element])!.$value as bool,
      start,
    );
    return $int($result);
  }

  @override
  int lastIndexOf(E element, [int? start]) =>
      $value.lastIndexOf(element, start);
  static const __$lastIndexOf = $Function(_$lastIndexOf);
  static $Value? _$lastIndexOf(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final element = args[0];
    final start = args[1]?.$value as int?;
    final $result = $this.lastIndexOf(element, start);
    return $int($result);
  }

  @override
  void clear() => $value.clear();
  static const __$clear = $Function(_$clear);
  static $Value? _$clear(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    $this.clear();
    return null;
  }

  @override
  void insert(int index, E element) => $value.insert(index, element);
  static const __$insert = $Function(_$insert);
  static $Value? _$insert(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final index = args[0]?.$value as int;
    final element = args[1];
    $this.insert(index, element);
    return null;
  }

  @override
  void insertAll(int index, Iterable<E> iterable) =>
      $value.insertAll(index, iterable);
  static const __$insertAll = $Function(_$insertAll);
  static $Value? _$insertAll(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final index = args[0]?.$value as int;
    final iterable = (args[1]?.$value as Iterable);
    $this.insertAll(index, iterable);
    return null;
  }

  @override
  void setAll(int index, Iterable<E> iterable) =>
      $value.setAll(index, iterable);
  static const __$setAll = $Function(_$setAll);
  static $Value? _$setAll(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final index = args[0]?.$value as int;
    final iterable = args[1]?.$value as Iterable;
    $this.setAll(index, iterable);
    return null;
  }

  @override
  bool remove(Object? value) => $value.remove(value);
  static const __$remove = $Function(_$remove);
  static $Value? _$remove(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final value = args[0];
    final $result = $this.remove(value);
    return $bool($result);
  }

  @override
  E removeAt(int index) => $value.removeAt(index);
  static const __$removeAt = $Function(_$removeAt);
  static $Value? _$removeAt(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final index = args[0]?.$value as int;
    final $result = $this.removeAt(index);
    return $result;
  }

  @override
  E removeLast() => $value.removeLast();
  static const __$removeLast = $Function(_$removeLast);
  static $Value? _$removeLast(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final $result = $this.removeLast();
    return $result;
  }

  @override
  void removeWhere(bool Function(E element) test) => $value.removeWhere(test);
  static const __$removeWhere = $Function(_$removeWhere);
  static $Value? _$removeWhere(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final test = args[0] as EvalCallable;
    $this.removeWhere(
      (element) => test.call(runtime, null, [element])!.$value as bool,
    );
    return null;
  }

  @override
  void retainWhere(bool Function(E element) test) => $value.retainWhere(test);
  static const __$retainWhere = $Function(_$retainWhere);
  static $Value? _$retainWhere(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final test = args[0] as EvalCallable;
    $this.retainWhere(
      (element) => test.call(runtime, null, [element])!.$value as bool,
    );
    return null;
  }

  @override
  List<E> operator +(List<E> other) => $value + other;
  static const __$combine = $Function(_$combine);
  static $Value? _$combine(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final other = args[0]?.$value as List;
    final $result = $this + other;
    return $List.wrap($result);
  }

  @override
  List<E> sublist(int start, [int? end]) => $value.sublist(start, end);
  static const __$sublist = $Function(_$sublist);
  static $Value? _$sublist(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final start = args[0]?.$value as int;
    final end = args[1]?.$value as int?;
    final $result = $this.sublist(start, end);
    return $List.wrap($result);
  }

  @override
  Iterable<E> getRange(int start, int end) => $value.getRange(start, end);
  static const __$getRange = $Function(_$getRange);
  static $Value? _$getRange(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final start = args[0]?.$value as int;
    final end = args[1]?.$value as int;
    final $result = $this.getRange(start, end);
    return $Iterable.wrap($result);
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable,
          [int skipCount = 0]) =>
      $value.setRange(start, end, iterable, skipCount);
  static const __$setRange = $Function(_$setRange);
  static $Value? _$setRange(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final start = args[0]?.$value as int;
    final end = args[1]?.$value as int;
    final iterable = args[2]?.$value as Iterable;
    final skipCount = args[3]?.$value as int? ?? 0;
    $this.setRange(start, end, iterable, skipCount);
    return null;
  }

  @override
  void removeRange(int start, int end) => $value.removeRange(start, end);
  static const __$removeRange = $Function(_$removeRange);
  static $Value? _$removeRange(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final start = args[0]?.$value as int;
    final end = args[1]?.$value as int;
    $this.removeRange(start, end);
    return null;
  }

  @override
  void fillRange(int start, int end, [E? fillValue]) =>
      $value.fillRange(start, end, fillValue);
  static const __$fillRange = $Function(_$fillRange);
  static $Value? _$fillRange(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final start = args[0]?.$value as int;
    final end = args[1]?.$value as int;
    final fillValue = args[2];
    $this.fillRange(start, end, fillValue);
    return null;
  }

  @override
  void replaceRange(int start, int end, Iterable<E> replacements) =>
      $value.replaceRange(start, end, replacements);
  static const __$replaceRange = $Function(_$replaceRange);
  static $Value? _$replaceRange(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final start = args[0]?.$value as int;
    final end = args[1]?.$value as int;
    final replacements = args[2]?.$value as Iterable;
    $this.replaceRange(start, end, replacements);
    return null;
  }

  @override
  Map<int, E> asMap() => $value.asMap();
  static const __$asMap = $Function(_$asMap);
  static $Value? _$asMap(Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as List;
    final $result = $this.asMap();
    return $Map.wrap({
      for (var entry in $result.entries)
        $int(entry.key): runtime.wrap(entry.value, recursive: true),
    });
  }

  static const __$static$method$castFrom = $Function(_$static$method$castFrom);
  static $Value? _$static$method$castFrom(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final source = args[0]?.$value;
    final $result = List.castFrom(source);
    return $List.wrap($result);
  }

  static const __$static$method$copyRange =
      $Function(_$static$method$copyRange);
  static $Value? _$static$method$copyRange(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final target = args[0]?.$value as List;
    final at = args[1]?.$value as int;
    final source = args[2]?.$value as List;
    final start = args[3]?.$value as int?;
    final end = args[4]?.$value as int?;
    List.copyRange(target, at, source, start, end);
    return null;
  }

  static const __$static$method$writeIterable =
      $Function(_$static$method$writeIterable);
  static $Value? _$static$method$writeIterable(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final target = args[0]?.$value as List;
    final at = args[1]?.$value as int;
    final source = args[2]?.$value as Iterable;
    List.writeIterable(target, at, source);
    return null;
  }

  static const __$List$filled = $Function(_$List$filled);
  static $Value? _$List$filled(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final length = args[0]?.$value as int;
    final fill = args[1];
    final growable = args[2]?.$value as bool? ?? false;
    return $List.wrap(List.filled(length, fill, growable: growable));
  }

  static const __$List$empty = $Function(_$List$empty);
  static $Value? _$List$empty(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final growable = args[0]?.$value as bool? ?? false;
    return $List.wrap(List.empty(growable: growable));
  }

  static const __$List$from = $Function(_$List$from);
  static $Value? _$List$from(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final elements = args[0]?.$value as Iterable;
    final growable = args[1]?.$value as bool? ?? true;
    return $List.wrap(List.from(elements, growable: growable));
  }

  static const __$List$of = $Function(_$List$of);
  static $Value? _$List$of(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final elements = args[0]?.$value;
    final growable = args[1]?.$value as bool? ?? true;
    return $List.wrap(List.of(elements, growable: growable));
  }

  static const __$List$generate = $Function(_$List$generate);
  static $Value? _$List$generate(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final length = args[0]?.$value as int;
    final generator = args[1] as EvalCallable;
    final growable = args[2]?.$value as bool? ?? true;
    return $List.wrap(List.generate(
      length,
      (index) => generator.call(runtime, null, [$int(index)]),
      growable: growable,
    ));
  }

  static const __$List$unmodifiable = $Function(_$List$unmodifiable);
  static $Value? _$List$unmodifiable(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final elements = args[0]?.$value as Iterable;
    return $List.wrap(List.unmodifiable(elements));
  }

  @override
  bool any(bool Function(E element) test) => $value.any(test);

  @override
  bool contains(Object? element) => $value.contains(element);

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
  String join([String separator = ""]) => $value.join(separator);

  @override
  E get last => $value.last;

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      $value.lastWhere(test, orElse: orElse);

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
}

/// Writeback-capable wrapper for [List] with type mapping function
class _$List$view<E> extends $List<E> {
  _$List$view(super.$value, this.mapper) : super.wrap();

  final $Value Function(E) mapper;

  $Value $map(E value) {
    if (value == null) return $null();
    return mapper(value);
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '[]':
        return __indexGet;
      case '[]=':
        return __indexSet;
      case 'add':
        return __add;
      case 'addAll':
        return __addAll;
      case 'first':
        return $map(_superclass.first);
      case 'contains':
        return __listContains;
      case 'where':
        return __where;
      case 'last':
        return $map(_superclass.last);
      case 'reversed':
        return $Iterable.wrap($value.reversed.map($map));
      case 'iterator':
        return $Iterator.wrap($value.map($map).iterator);
      case 'insert':
        return __insert;
      case 'insertAll':
        return __insertAll;
      case 'remove':
        return __remove;
      case 'asMap':
        return __asMap;
      case 'lastIndexOf':
        return __lastIndexOf;
      case 'indexOf':
        return __indexOf;
      case 'retainWhere':
        return __retainWhere;
      case 'removeWhere':
        return __removeWhere;
      case 'replaceRange':
        return __replaceRange;
      case 'getRange':
        return __getRange;
      case 'sort':
        return __sort;
      case 'removeAt':
        return __removeAt;
      case 'sublist':
        return __sublist;
      case 'takeWhile':
        return __takeWhile;
    }
    return super.$getProperty(runtime, identifier);
  }

  static const $Function __add = $Function(_add);

  static $Value? _add(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = args[0]!;
    (target! as _$List$view).add(value.$value);
    return null;
  }

  static const $Function __addAll = $Function(_addAll);

  static $Value? _addAll(Runtime runtime, $Value? target, List<$Value?> args) {
    (target! as _$List$view).addAll(args[0]!.$reified);
    return null;
  }

  static const $Function __insertAll = $Function(_insertAll);

  static $Value? _insertAll(
      Runtime runtime, $Value? target, List<$Value?> args) {
    (target! as _$List$view).insertAll(args[0]!.$value, args[1]!.$reified);
    return null;
  }

  static const $Function __insert = $Function(_insert);

  static $Value? _insert(Runtime runtime, $Value? target, List<$Value?> args) {
    (target! as _$List$view).insert(args[0]!.$value, args[1]!.$reified);
    return null;
  }

  static const $Function __remove = $Function(_remove);

  static $Value? _remove(Runtime runtime, $Value? target, List<$Value?> args) {
    return $bool((target! as _$List$view).remove(args[0]!.$reified));
  }

  static const $Function __removeAt = $Function(_removeAt);

  static $Value? _removeAt(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return (target! as _$List$view).removeAt(args[0]!.$value);
  }

  static const $Function __lastIndexOf = $Function(_lastIndexOf);

  static $Value? _lastIndexOf(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $int((target! as _$List$view).lastIndexOf(args[0]!.$reified));
  }

  static const $Function __indexOf = $Function(_indexOf);

  static $Value? _indexOf(Runtime runtime, $Value? target, List<$Value?> args) {
    return $int((target! as _$List$view).indexOf(args[0]!.$reified));
  }

  static const $Function __indexGet = $Function(_indexGet);

  static $Value? _indexGet(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final idx = args[0]!;
    final view = (target! as _$List$view);
    return view.$map(view.$value[idx.$value]);
  }

  static const $Function __indexSet = $Function(_indexSet);

  static $Value? _indexSet(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final idx = args[0]!;
    final value = args[1]!;
    (target! as _$List$view).$value[idx.$value] = value.$value;
    return value;
  }

  static const $Function __sublist = $Function(_sublist);

  static $Value? _sublist(Runtime runtime, $Value? target, List<$Value?> args) {
    return $List.wrap((target! as _$List$view)
        .$value
        .sublist(args[0]!.$value, args[1]?.$value));
  }

  static const $Function __listContains = $Function(_listContains);

  static $Value? _listContains(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $bool((target! as _$List$view).contains(args[0]!.$reified));
  }

  static const $Function __where = $Function(_where);

  static $Value? _where(Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    return $Iterable.wrap((target! as _$List$view)
        .$value
        .where((e) => test.call(runtime, null, [e])!.$value as bool)
        .map((e) => (target as _$List$view).$map(e)));
  }

  static const $Function __asMap = $Function(_asMap);

  static $Value? _asMap(Runtime runtime, $Value? target, List<$Value?> args) {
    final view = (target! as _$List$view);
    return $Map.wrap(view.$value
        .asMap()
        .map((key, value) => MapEntry($int(key), view.$map(value))));
  }

  static const $Function __retainWhere = $Function(_retainWhere);

  static $Value? _retainWhere(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    final view = (target! as _$List$view);

    view.retainWhere(
        (e) => test.call(runtime, null, [view.$map(e)])!.$value as bool);
    return null;
  }

  static const $Function __removeWhere = $Function(_removeWhere);

  static $Value? _removeWhere(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    final view = (target! as _$List$view);

    view.removeWhere(
        (e) => test.call(runtime, null, [view.$map(e)])!.$value as bool);
    return null;
  }

  static const $Function __replaceRange = $Function(_replaceRange);

  static $Value? _replaceRange(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final view = (target! as _$List$view);
    view.$value
        .replaceRange(args[0]!.$value, args[1]!.$value, args[2]!.$reified);
    return null;
  }

  static const $Function __getRange = $Function(_getRange);

  static $Value? _getRange(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final view = (target! as _$List$view);
    return $Iterable.wrap(
        view.$value.getRange(args[0]!.$value, args[1]!.$value).map(view.$map));
  }

  static const $Function __sort = $Function(_sort);

  static $Value? _sort(Runtime runtime, $Value? target, List<$Value?> args) {
    final compare = args[0] as EvalCallable;
    final view = (target! as _$List$view);

    view.$value.sort((a, b) =>
        compare.call(runtime, null, [view.$map(a), view.$map(b)])!.$value);
    return null;
  }

  static const $Function __takeWhile = $Function(_takeWhile);

  static $Value? _takeWhile(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    final view = (target! as _$List$view);

    return $Iterable.wrap(view.$value
        .takeWhile((e) => test.call(runtime, null, [view.$map(e)])!.$value));
  }
}
