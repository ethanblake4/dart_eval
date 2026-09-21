part of 'collection.dart';

/// dart_eval bimodal wrapper for [List]
class $List<E> implements List<E>, $Instance {
  /// Configure the [$List] wrapper for use in a [Runtime]
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      $type.spec!.library,
      'List.filled',
      _$List$filled,
      isBridge: false,
    );
    runtime.registerBridgeFuncRegisters(
      $type.spec!.library,
      'List.empty',
      _$List$empty,
      isBridge: false,
    );
    runtime.registerBridgeFuncRegisters(
      $type.spec!.library,
      'List.from',
      _$List$from,
      isBridge: false,
    );
    runtime.registerBridgeFuncRegisters(
      $type.spec!.library,
      'List.of',
      _$List$of,
      isBridge: false,
    );
    runtime.registerBridgeFuncRegisters(
      $type.spec!.library,
      'List.generate',
      _$List$generate,
      isBridge: false,
    );
    runtime.registerBridgeFuncRegisters(
      $type.spec!.library,
      'List.unmodifiable',
      _$List$unmodifiable,
      isBridge: false,
    );
    runtime.registerBridgeFuncRegisters(
      $type.spec!.library,
      'List.castFrom',
      _$static$method$castFrom,
      isBridge: false,
    );
    runtime.registerBridgeFuncRegisters(
      $type.spec!.library,
      'List.copyRange',
      _$static$method$copyRange,
      isBridge: false,
    );
    runtime.registerBridgeFuncRegisters(
      $type.spec!.library,
      'List.writeIterable',
      _$static$method$writeIterable,
      isBridge: false,
    );
  }

  late final $Iterable _superclass = $Iterable.wrap($value);

  static const $type = BridgeTypeRef(CoreTypes.list);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      $extends: BridgeTypeRef(CoreTypes.iterable),
      generics: {'E': BridgeGenericParam()},
    ),
    constructors: {
      'filled': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'fill',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', []), nullable: false),
              false,
            ),
          ],
          namedParams: [
            BridgeParameter(
              'growable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.bool, []),
                nullable: false,
              ),
              true,
            ),
          ],
          generics: {'E': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
      'empty': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [],
          namedParams: [
            BridgeParameter(
              'growable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.bool, []),
                nullable: false,
              ),
              true,
            ),
          ],
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
          namedParams: [
            BridgeParameter(
              'growable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.bool, []),
                nullable: false,
              ),
              true,
            ),
          ],
          generics: {'E': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
      'of': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
              'elements',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [
            BridgeParameter(
              'growable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.bool, []),
                nullable: false,
              ),
              true,
            ),
          ],
          generics: {'E': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
      'generate': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'generator',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.function, []),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [
            BridgeParameter(
              'growable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.bool, []),
                nullable: false,
              ),
              true,
            ),
          ],
          generics: {'E': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
      'unmodifiable': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
              'elements',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, []),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
          generics: {'E': BridgeGenericParam()},
        ),
        isFactory: true,
      ),
    },
    fields: {},
    methods: {
      'toString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [],
        ),
        isStatic: false,
      ),
      'castFrom': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
            ]),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('S', [])),
                ]),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
          generics: {'S': BridgeGenericParam(), 'T': BridgeGenericParam()},
        ),
        isStatic: true,
      ),
      'copyRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'target',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
                ]),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'at',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
                ]),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
          namedParams: [],
          generics: {'T': BridgeGenericParam()},
        ),
        isStatic: true,
      ),
      'writeIterable': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'target',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
                ]),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'at',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T', [])),
                ]),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
          generics: {'T': BridgeGenericParam()},
        ),
        isStatic: true,
      ),
      'cast': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('R', [])),
            ]),
            nullable: false,
          ),
          params: [],
          namedParams: [],
          generics: {'R': BridgeGenericParam()},
        ),
        isStatic: false,
      ),
      '[]': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef.ref('E', []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      '[]=': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', []), nullable: false),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'add': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', []), nullable: false),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'addAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'iterable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'sort': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'compare',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.function, []),
                nullable: true,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'shuffle': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'random',
              BridgeTypeAnnotation(
                BridgeTypeRef(MathTypes.random, []),
                nullable: true,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'indexOf': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.int, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'element',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', []), nullable: false),
              false,
            ),
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'indexWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.int, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.bool, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'lastIndexWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.int, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.bool, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'lastIndexOf': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.int, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'element',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', []), nullable: false),
              false,
            ),
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'clear': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'insert': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'element',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', []), nullable: false),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'insertAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'iterable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'setAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'iterable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'remove': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.bool, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'removeAt': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef.ref('E', []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'removeLast': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef.ref('E', []),
            nullable: false,
          ),
          params: [],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'removeWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.function, []),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'retainWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.function, []),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      '+': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
            ]),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'sublist': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
            ]),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'getRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
            ]),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'setRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'iterable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'skipCount',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'removeRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'fillRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'fillValue',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', []), nullable: true),
              true,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'replaceRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
            BridgeParameter(
              'replacements',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                ]),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'asMap': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
            ]),
            nullable: false,
          ),
          params: [],
          namedParams: [],
        ),
        isStatic: false,
      ),
    },
    getters: {
      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.int, []),
            nullable: false,
          ),
          params: [],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'reversed': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
            ]),
            nullable: false,
          ),
          params: [],
          namedParams: [],
        ),
        isStatic: false,
      ),
    },
    setters: {
      'first': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', []), nullable: false),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'last': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E', []), nullable: false),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.voidType, []),
            nullable: false,
          ),
          params: [
            BridgeParameter(
              'newLength',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: false,
              ),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: false,
      ),
    },
    bridge: false,
    wrap: true,
  );

  /// Wrap an [List] in an [$List]
  $List.wrap(this.$value, {int? runtimeTypeId, Runtime? runtime})
    : _runtimeTypeId = runtimeTypeId,
      _runtime = runtime;

  final int? _runtimeTypeId;
  final Runtime? _runtime;

  // The translated owner descriptor id is stable per (wrapper, runtime) pair;
  // keep the last translation instead of importing on every element write.
  Runtime? _checkRuntime;
  int _checkOwnerType = -1;

  /// Create a lazy canonical view of a host [List] (supports writeback).
  ///
  /// The typed VM can index this view directly because every read produces a
  /// [$Value]. Writes cross the boundary through [$Value.$reified].
  static $List<$Value?> view<T>(
    List<T> value,
    $Value Function(T value) mapper,
  ) => $MappedListView<T>(value, mapper);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'length':
        return $int($value.length);
      case 'toString':
        return __toString;
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
  int $getRuntimeType(Runtime runtime) {
    final typeId = _runtimeTypeId;
    return typeId == null
        ? runtime.lookupType($type.spec!)
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
  }

  List<Object?> _checkedElements(Runtime runtime, Iterable values) {
    final checked = values.toList(growable: false);
    for (final value in checked) {
      _checkElement(runtime, value);
    }
    return checked;
  }

  Iterable<Object?> _checkedIterable(Runtime runtime, Iterable values) sync* {
    for (final value in values) {
      _checkElement(runtime, value);
      yield value;
    }
  }

  @override
  List get $reified => $value.map((e) => e is $Value ? e.$reified : e).toList();

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      case 'first':
        _checkElement(runtime, value);
        first = value as E;
        break;
      case 'last':
        _checkElement(runtime, value);
        last = value as E;
        break;
      case 'length':
        final newLength = value.$value as int;
        if (newLength > length) _checkElement(runtime, null);
        length = newLength;
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
  static const __toString = $Function(_toString);

  static $Value? _toString(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return collectionToString(runtime, (target as $List).$value, '[', ']');
  }

  static const __$cast = $Function(_$cast);
  static $Value? _$cast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final $result = $this.cast();
    return $List.wrap($result);
  }

  @override
  E operator [](int index) => $value[index];
  static const __$indexGet = $Function(_$indexGet);
  static $Value? _$indexGet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final index = (r as $Value?)?.$value as int;
    final $result = $this[index];
    return $result;
  }

  @override
  void operator []=(int index, E value) => $value[index] = value;
  static const __$indexSet = $Function(_$indexSet);
  static $Value? _$indexSet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $List;
    final $this = wrapper.$value;
    final index = (r as $Value?)?.$value as int;
    final value = (s as $Value?);
    wrapper._checkElement(runtime, value);
    $this[index] = value;
    return null;
  }

  @override
  void add(E value) => $value.add(value);
  static const __$add = $Function(_$add);
  static $Value? _$add(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $List;
    final $this = wrapper.$value;
    final value = (r as $Value?);
    wrapper._checkElement(runtime, value);
    $this.add(value);
    return null;
  }

  @override
  void addAll(Iterable<E> iterable) => $value.addAll(iterable);
  static const __$addAll = $Function(_$addAll);
  static $Value? _$addAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $List;
    final $this = wrapper.$value;
    final iterable = (r as $Value?)?.$value as Iterable;
    $this.addAll(wrapper._checkedElements(runtime, iterable));
    return null;
  }

  @override
  void sort([int Function(E a, E b)? compare]) => $value.sort(compare);
  static const __$sort = $Function(_$sort);
  static $Value? _$sort(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final compare =
        (r as $Value?) as EvalFunction? ??
        $Function(
          (runtime, target, r, s, c) => $int(
            Comparable.compare((r as $Value?)?.$value, (s as $Value?)?.$value),
          ),
        );
    $this.sort((a, b) => compare.call(runtime, null, a, b, 2)?.$value as int);
    return null;
  }

  @override
  void shuffle([Random? random]) => $value.shuffle(random);
  static const __$shuffle = $Function(_$shuffle);
  static $Value? _$shuffle(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final random = (r as $Value?)?.$value as Random?;
    $this.shuffle(random);
    return null;
  }

  @override
  int indexOf(E element, [int start = 0]) => $value.indexOf(element, start);
  static const __$indexOf = $Function(_$indexOf);
  static $Value? _$indexOf(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final element = (r as $Value?);
    final start = (s as $Value?)?.$value as int? ?? 0;
    final $result = $this.indexOf(element, start);
    return $int($result);
  }

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) =>
      $value.indexWhere(test, start);
  static const __$indexWhere = $Function(_$indexWhere);
  static $Value? _$indexWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final test = (r as $Value?) as EvalCallable;
    final start = (s as $Value?)?.$value as int? ?? 0;
    final $result = $this.indexWhere(
      (element) => test.call(runtime, null, element, null, 1)!.$value as bool,
      start,
    );
    return $int($result);
  }

  @override
  int lastIndexWhere(bool Function(E element) test, [int? start]) =>
      $value.lastIndexWhere(test, start);
  static const __$lastIndexWhere = $Function(_$lastIndexWhere);
  static $Value? _$lastIndexWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final test = (r as $Value?) as EvalCallable;
    final start = (s as $Value?)?.$value as int?;
    final $result = $this.lastIndexWhere(
      (element) => test.call(runtime, null, element, null, 1)!.$value as bool,
      start,
    );
    return $int($result);
  }

  @override
  int lastIndexOf(E element, [int? start]) =>
      $value.lastIndexOf(element, start);
  static const __$lastIndexOf = $Function(_$lastIndexOf);
  static $Value? _$lastIndexOf(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final element = (r as $Value?);
    final start = (s as $Value?)?.$value as int?;
    final $result = $this.lastIndexOf(element, start);
    return $int($result);
  }

  @override
  void clear() => $value.clear();
  static const __$clear = $Function(_$clear);
  static $Value? _$clear(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    $this.clear();
    return null;
  }

  @override
  void insert(int index, E element) => $value.insert(index, element);
  static const __$insert = $Function(_$insert);
  static $Value? _$insert(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $List;
    final $this = wrapper.$value;
    final index = (r as $Value?)?.$value as int;
    final element = (s as $Value?);
    wrapper._checkElement(runtime, element);
    $this.insert(index, element);
    return null;
  }

  @override
  void insertAll(int index, Iterable<E> iterable) =>
      $value.insertAll(index, iterable);
  static const __$insertAll = $Function(_$insertAll);
  static $Value? _$insertAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $List;
    final $this = wrapper.$value;
    final index = (r as $Value?)?.$value as int;
    final iterable = ((s as $Value?)?.$value as Iterable);
    $this.insertAll(index, wrapper._checkedElements(runtime, iterable));
    return null;
  }

  @override
  void setAll(int index, Iterable<E> iterable) =>
      $value.setAll(index, iterable);
  static const __$setAll = $Function(_$setAll);
  static $Value? _$setAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $List;
    final $this = wrapper.$value;
    final index = (r as $Value?)?.$value as int;
    final iterable = (s as $Value?)?.$value as Iterable;
    $this.setAll(index, wrapper._checkedElements(runtime, iterable));
    return null;
  }

  @override
  bool remove(Object? value) => $value.remove(value);
  static const __$remove = $Function(_$remove);
  static $Value? _$remove(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final value = (r as $Value?);
    final $result = $this.remove(value);
    return $bool($result);
  }

  @override
  E removeAt(int index) => $value.removeAt(index);
  static const __$removeAt = $Function(_$removeAt);
  static $Value? _$removeAt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final index = (r as $Value?)?.$value as int;
    final $result = $this.removeAt(index);
    return $result;
  }

  @override
  E removeLast() => $value.removeLast();
  static const __$removeLast = $Function(_$removeLast);
  static $Value? _$removeLast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final $result = $this.removeLast();
    return $result;
  }

  @override
  void removeWhere(bool Function(E element) test) => $value.removeWhere(test);
  static const __$removeWhere = $Function(_$removeWhere);
  static $Value? _$removeWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final test = (r as $Value?) as EvalCallable;
    $this.removeWhere(
      (element) => test.call(runtime, null, element, null, 1)!.$value as bool,
    );
    return null;
  }

  @override
  void retainWhere(bool Function(E element) test) => $value.retainWhere(test);
  static const __$retainWhere = $Function(_$retainWhere);
  static $Value? _$retainWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final test = (r as $Value?) as EvalCallable;
    $this.retainWhere(
      (element) => test.call(runtime, null, element, null, 1)!.$value as bool,
    );
    return null;
  }

  @override
  List<E> operator +(List<E> other) => $value + other;
  static const __$combine = $Function(_$combine);
  static $Value? _$combine(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final other = (r as $Value?)?.$value as List;
    final $result = $this + other;
    return $List.wrap($result);
  }

  @override
  List<E> sublist(int start, [int? end]) => $value.sublist(start, end);
  static const __$sublist = $Function(_$sublist);
  static $Value? _$sublist(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final start = (r as $Value?)?.$value as int;
    final end = (s as $Value?)?.$value as int?;
    final $result = $this.sublist(start, end);
    return $List.wrap($result);
  }

  @override
  Iterable<E> getRange(int start, int end) => $value.getRange(start, end);
  static const __$getRange = $Function(_$getRange);
  static $Value? _$getRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final start = (r as $Value?)?.$value as int;
    final end = (s as $Value?)?.$value as int;
    final $result = $this.getRange(start, end);
    return $Iterable.wrap($result);
  }

  @override
  void setRange(
    int start,
    int end,
    Iterable<E> iterable, [
    int skipCount = 0,
  ]) => $value.setRange(start, end, iterable, skipCount);
  static const __$setRange = $Function(_$setRange);
  static $Value? _$setRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $List;
    final $this = wrapper.$value;
    final start = (r as $Value?)?.$value as int;
    final end = (s as $Value?)?.$value as int;
    final iterable = ((c as List<Object?>)[0] as $Value?)?.$value as Iterable;
    final skipCount = (c as List).length > 1
        ? (c[1] as $Value?)?.$value as int? ?? 0
        : 0;
    $this.setRange(
      start,
      end,
      wrapper._checkedIterable(runtime, iterable),
      skipCount,
    );
    return null;
  }

  @override
  void removeRange(int start, int end) => $value.removeRange(start, end);
  static const __$removeRange = $Function(_$removeRange);
  static $Value? _$removeRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final start = (r as $Value?)?.$value as int;
    final end = (s as $Value?)?.$value as int;
    $this.removeRange(start, end);
    return null;
  }

  @override
  void fillRange(int start, int end, [E? fillValue]) =>
      $value.fillRange(start, end, fillValue);
  static const __$fillRange = $Function(_$fillRange);
  static $Value? _$fillRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $List;
    final $this = wrapper.$value;
    final start = (r as $Value?)?.$value as int;
    final end = (s as $Value?)?.$value as int;
    final fillValue = c is List && c.isNotEmpty ? c[0] as $Value? : null;
    wrapper._checkElement(runtime, fillValue);
    $this.fillRange(start, end, fillValue);
    return null;
  }

  @override
  void replaceRange(int start, int end, Iterable<E> replacements) =>
      $value.replaceRange(start, end, replacements);
  static const __$replaceRange = $Function(_$replaceRange);
  static $Value? _$replaceRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final wrapper = target as $List;
    final $this = wrapper.$value;
    final start = (r as $Value?)?.$value as int;
    final end = (s as $Value?)?.$value as int;
    final replacements =
        ((c as List<Object?>)[0] as $Value?)?.$value as Iterable;
    $this.replaceRange(
      start,
      end,
      wrapper._checkedElements(runtime, replacements),
    );
    return null;
  }

  @override
  Map<int, E> asMap() => $value.asMap();
  static const __$asMap = $Function(_$asMap);
  static $Value? _$asMap(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final $this = target?.$value as List;
    final $result = $this.asMap();
    return $Map.wrap({
      for (var entry in $result.entries)
        $int(entry.key): runtime.wrap(entry.value, recursive: true),
    });
  }

  static $Value? _$static$method$castFrom(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final source = (r as $Value?)?.$value;
    final $result = List.castFrom(source);
    return $List.wrap($result);
  }

  static $Value? _$static$method$copyRange(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final rest = c as List<Object?>;
    final target = (r as $Value?)?.$value as List;
    final at = (s as $Value?)?.$value as int;
    final source = (rest[0] as $Value?)?.$value as List;
    final start = (rest[1] as $Value?)?.$value as int?;
    final end = (rest[2] as $Value?)?.$value as int?;
    List.copyRange(target, at, source, start, end);
    return null;
  }

  static $Value? _$static$method$writeIterable(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final target = (r as $Value?)?.$value as List;
    final at = (s as $Value?)?.$value as int;
    final source = (c as $Value?)?.$value as Iterable;
    List.writeIterable(target, at, source);
    return null;
  }

  static $Value? _$List$filled(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final length = (r as $Value?)?.$value as int;
    final fill = s as $Value?;
    final growable = (c as $Value?)?.$value as bool? ?? false;
    return $List.wrap(List.filled(length, fill, growable: growable));
  }

  static $Value? _$List$empty(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final growable = (r as $Value?)?.$value as bool? ?? false;
    return $List.wrap(List.empty(growable: growable));
  }

  static $Value? _$List$from(Runtime runtime, Object? r, Object? s, Object? c) {
    final elements = (r as $Value?)?.$value as Iterable;
    final growable = (s as $Value?)?.$value as bool? ?? true;
    return $List.wrap(List.from(elements, growable: growable));
  }

  static $Value? _$List$of(Runtime runtime, Object? r, Object? s, Object? c) {
    final elements = (r as $Value?)?.$value;
    final growable = (s as $Value?)?.$value as bool? ?? true;
    return $List.wrap(List.of(elements, growable: growable));
  }

  static $Value? _$List$generate(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final length = (r as $Value?)?.$value as int;
    final generator = s as EvalCallable;
    final growable = (c as $Value?)?.$value as bool? ?? true;
    return $List.wrap(
      List.generate(
        length,
        (index) => generator.call(runtime, null, $int(index), null, 1),
        growable: growable,
      ),
    );
  }

  static $Value? _$List$unmodifiable(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final elements = (r as $Value?)?.$value as Iterable;
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

/// Canonical list storage over a native host list. Conversion stays lazy and
/// direct list bytecodes can use it without knowing which wrapper created it.
final class $MappedListView<E> extends $List<$Value?> {
  $MappedListView(this.hostBacking, $Value Function(E value) mapper)
    : super.wrap(_MappedCanonicalList<E>(hostBacking, mapper));

  final List<E> hostBacking;
}

final class _MappedCanonicalList<E> extends ListBase<$Value?> {
  _MappedCanonicalList(this.backing, this.mapper);

  final List<E> backing;
  final $Value Function(E value) mapper;

  @override
  int get length => backing.length;

  @override
  set length(int value) => backing.length = value;

  @override
  $Value? operator [](int index) {
    final value = backing[index];
    return value == null ? null : mapper(value);
  }

  @override
  void operator []=(int index, $Value? value) {
    backing[index] = _export(value);
  }

  E _export($Value? value) =>
      (value == null || value is $null ? null : value.$reified) as E;

  @override
  void add($Value? value) => backing.add(_export(value));

  @override
  void addAll(Iterable<$Value?> iterable) =>
      backing.addAll(iterable.map(_export));

  @override
  void insert(int index, $Value? value) =>
      backing.insert(index, _export(value));

  @override
  void insertAll(int index, Iterable<$Value?> iterable) =>
      backing.insertAll(index, iterable.map(_export));
}
