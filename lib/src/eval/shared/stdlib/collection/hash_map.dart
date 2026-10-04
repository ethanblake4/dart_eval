// ignore_for_file: unused_import, unnecessary_import
// ignore_for_file: always_specify_types, avoid_redundant_argument_values
// ignore_for_file: sort_constructors_first
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_is_empty
// ignore_for_file: undefined_hidden_name
// ignore_for_file: dead_code, unused_local_variable
// ignore_for_file: unnecessary_type_check, unnecessary_non_null_assertion
// ignore_for_file: unnecessary_cast
// ignore_for_file: sdk_version_since
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: argument_type_not_assignable_to_error_handler
// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import 'dart:collection';

import 'package:dart_eval/stdlib/core.dart'
    hide
        $LinkedHashMap,
        $UnmodifiableListView,
        $ListQueue,
        $Queue,
        $HashMap,
        $SplayTreeMap,
        $SplayTreeSet,
        $HashSet,
        $LinkedHashSet,
        $DoubleLinkedQueue,
        $DoubleLinkedQueueEntry,
        $ListBase,
        $MapBase,
        $SetBase;
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

import '../core/map_entry.dart';

import 'package:dart_eval/src/eval/utils/wrap_helper.dart';

import 'hash_collection_hooks.dart' as hooks;

/// dart_eval wrapper binding for [HashMap]
class $HashMap<K, V> implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'HashMap.',
      $HashMap.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'HashMap.identity',
      $HashMap.$identity,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'HashMap.from',
      $HashMap.$from,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'HashMap.of',
      $HashMap.$of,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'HashMap.fromIterable',
      $HashMap.$fromIterable,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'HashMap.fromIterables',
      $HashMap.$fromIterables,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'HashMap.fromEntries',
      $HashMap.$fromEntries,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$HashMap]
  static const $spec = BridgeTypeSpec('dart:collection', 'HashMap');

  /// Compile-time type declaration of [$HashMap]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$HashMap]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      generics: {'K': BridgeGenericParam(), 'V': BridgeGenericParam()},

      $implements: [
        BridgeTypeRef(CoreTypes.map, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
          BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
        ]),
      ],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'equals',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'null',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                        false,
                      ),

                      BridgeParameter(
                        'null',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'hashCode',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.int, []),
                    ),
                    params: [
                      BridgeParameter(
                        'null',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'isValidKey',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'null',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [],
        ),
        isFactory: true,
      ),

      'identity': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: true,
      ),

      'from': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
              ),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'of': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                ]),
              ),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'fromIterable': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'key',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'iterable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
              ),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'fromIterables': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'keys',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                ]),
              ),
              false,
            ),

            BridgeParameter(
              'values',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                ]),
              ),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'fromEntries': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'entries',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.mapEntry, [
                      BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                      BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                    ]),
                  ),
                ]),
              ),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'cast': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'RK': BridgeGenericParam(), 'RV': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('RK')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('RV')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'containsValue': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
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
        ),

        isAbstract: true,
      ),

      'containsKey': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'key',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '[]': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V'), nullable: true),
          namedParams: [],
          params: [
            BridgeParameter(
              'key',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '[]=': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'key',
              BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'map': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'K2': BridgeGenericParam(), 'V2': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('K2')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('V2')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'convert',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.mapEntry, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('K2')),
                        BridgeTypeAnnotation(BridgeTypeRef.ref('V2')),
                      ]),
                    ),
                    params: [
                      BridgeParameter(
                        'key',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                        false,
                      ),

                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'addEntries': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'newEntries',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.mapEntry, [
                      BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                      BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                    ]),
                  ),
                ]),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'update': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
          namedParams: [
            BridgeParameter(
              'ifAbsent',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                    params: [],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'key',
              BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
              false,
            ),

            BridgeParameter(
              'update',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                    params: [
                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'updateAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'update',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                    params: [
                      BridgeParameter(
                        'key',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                        false,
                      ),

                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'removeWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'key',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                        false,
                      ),

                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'putIfAbsent': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
          namedParams: [],
          params: [
            BridgeParameter(
              'key',
              BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
              false,
            ),

            BridgeParameter(
              'ifAbsent',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                    params: [],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'addAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                ]),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'remove': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('V'), nullable: true),
          namedParams: [],
          params: [
            BridgeParameter(
              'key',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'clear': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'forEach': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'action',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'key',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                        false,
                      ),

                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),
    },
    getters: {
      'entries': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.mapEntry, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
                ]),
              ),
            ]),
          ),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'keys': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'values': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'isEmpty': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'isNotEmpty': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [HashMap.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $HashMap.wrap(
      hooks.nativeHashMap(
        runtime,
        equals:
            (r is $Value ? r : null) == null ||
                (r is $Value ? r : null) is $null
            ? null
            : (() {
                final _callbackType0 =
                    runtime.runtimeTypeArgumentAt(
                      (runtime.bridgeConstructorTypeId ??
                          runtime.lookupType(CollectionTypes.hashMap)),
                      0,
                    ) ??
                    runtime.lookupType(CoreTypes.dynamic);
                final _callbackType1 =
                    runtime.runtimeTypeArgumentAt(
                      (runtime.bridgeConstructorTypeId ??
                          runtime.lookupType(CollectionTypes.hashMap)),
                      0,
                    ) ??
                    runtime.lookupType(CoreTypes.dynamic);
                return runtime.cachedCallback(
                  (r is $Value ? r : null)! as EvalCallable,
                  "bool Function(K, K);export=false" +
                      ";types=$_callbackType0,$_callbackType1",
                  (_callable) => (dynamic arg0, dynamic arg1) {
                    return _callable
                            .call(
                              runtime,
                              null,
                              TypedInterop.boxExternal(
                                arg0,
                                runtime: runtime,
                                runtimeTypeId: _callbackType0,
                              ),
                              TypedInterop.boxExternal(
                                arg1,
                                runtime: runtime,
                                runtimeTypeId: _callbackType1,
                              ),
                              2,
                            )
                            ?.$value
                        as bool;
                  },
                );
              })(),
        hashCode:
            (s is $Value ? s : null) == null ||
                (s is $Value ? s : null) is $null
            ? null
            : (() {
                final _callbackType0 =
                    runtime.runtimeTypeArgumentAt(
                      (runtime.bridgeConstructorTypeId ??
                          runtime.lookupType(CollectionTypes.hashMap)),
                      0,
                    ) ??
                    runtime.lookupType(CoreTypes.dynamic);
                return runtime.cachedCallback(
                  (s is $Value ? s : null)! as EvalCallable,
                  "int Function(K);export=false" + ";types=$_callbackType0",
                  (_callable) => (dynamic arg0) {
                    return _callable
                            .call(
                              runtime,
                              null,
                              TypedInterop.boxExternal(
                                arg0,
                                runtime: runtime,
                                runtimeTypeId: _callbackType0,
                              ),
                              null,
                              1,
                            )
                            ?.$value
                        as int;
                  },
                );
              })(),
        isValidKey:
            (c is $Value ? c : null) == null ||
                (c is $Value ? c : null) is $null
            ? null
            : (() {
                final _callbackType0 = runtime.lookupType(CoreTypes.dynamic);
                return runtime.cachedCallback(
                  (c is $Value ? c : null)! as EvalCallable,
                  "bool Function(dynamic);export=false" +
                      ";types=$_callbackType0",
                  (_callable) => (dynamic arg0) {
                    return _callable
                            .call(
                              runtime,
                              null,
                              TypedInterop.boxExternal(
                                arg0,
                                runtime: runtime,
                                runtimeTypeId: _callbackType0,
                              ),
                              null,
                              1,
                            )
                            ?.$value
                        as bool;
                  },
                );
              })(),
      ),
    );
  }

  /// Wrapper for the [HashMap.identity] constructor
  static $Value? $identity(Runtime runtime, Object? r, Object? s, Object? c) {
    return $HashMap.wrap(HashMap.identity());
  }

  /// Wrapper for the [HashMap.from] constructor
  static $Value? $from(Runtime runtime, Object? r, Object? s, Object? c) {
    return $HashMap.wrap(
      HashMap.from(((r as $Value?)!.$reified as Map).cast<dynamic, dynamic>()),
    );
  }

  /// Wrapper for the [HashMap.of] constructor
  static $Value? $of(Runtime runtime, Object? r, Object? s, Object? c) {
    return $HashMap.wrap(
      HashMap.of(((r as $Value?)!.$reified as Map).cast<dynamic, dynamic>()),
    );
  }

  /// Wrapper for the [HashMap.fromIterable] constructor
  static $Value? $fromIterable(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $HashMap.wrap(
      HashMap.fromIterable(
        TypedInterop.exportIterable((r as $Value?), runtime),
        key:
            (s is $Value ? s : null) == null ||
                (s is $Value ? s : null) is $null
            ? null
            : (() {
                final _callbackType0 = runtime.lookupType(CoreTypes.dynamic);
                return runtime.cachedCallback(
                  (s is $Value ? s : null)! as EvalCallable,
                  "K Function(dynamic);export=false" + ";types=$_callbackType0",
                  (_callable) => (dynamic element) {
                    return TypedInterop.exportExternal(
                      _callable.call(
                        runtime,
                        null,
                        TypedInterop.boxExternal(
                          element,
                          runtime: runtime,
                          runtimeTypeId: _callbackType0,
                        ),
                        null,
                        1,
                      ),
                      runtime: runtime,
                    ) as dynamic;
                  },
                );
              })(),
        value:
            (c is $Value ? c : null) == null ||
                (c is $Value ? c : null) is $null
            ? null
            : (() {
                final _callbackType0 = runtime.lookupType(CoreTypes.dynamic);
                return runtime.cachedCallback(
                  (c is $Value ? c : null)! as EvalCallable,
                  "V Function(dynamic);export=false" + ";types=$_callbackType0",
                  (_callable) => (dynamic element) {
                    return TypedInterop.exportExternal(
                      _callable.call(
                        runtime,
                        null,
                        TypedInterop.boxExternal(
                          element,
                          runtime: runtime,
                          runtimeTypeId: _callbackType0,
                        ),
                        null,
                        1,
                      ),
                      runtime: runtime,
                    ) as dynamic;
                  },
                );
              })(),
      ),
    );
  }

  /// Wrapper for the [HashMap.fromIterables] constructor
  static $Value? $fromIterables(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $HashMap.wrap(
      HashMap.fromIterables(
        TypedInterop.exportIterable((r as $Value?), runtime),
        TypedInterop.exportIterable((s as $Value?), runtime),
      ),
    );
  }

  /// Wrapper for the [HashMap.fromEntries] constructor
  static $Value? $fromEntries(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $HashMap.wrap(
      HashMap.fromEntries(TypedInterop.exportIterable((r as $Value?), runtime)),
    );
  }

  final $Instance _superclass;

  @override
  final HashMap<K, V> $value;

  @override
  HashMap<K, V> get $reified => $value;

  /// Wrap a [HashMap] in a [$HashMap]
  $HashMap.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) {
    final data = Runtime.bridgeData[this];
    return data == null
        ? runtime.lookupType($spec)
        : runtime.importRuntimeType(data.runtime, data.$runtimeType);
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'entries':
        final _entries = $value.entries;
        return (() {
          final iterableType = runtime.internParameterizedType(
            CoreTypes.iterable,
            [
              runtime.internParameterizedType(CoreTypes.mapEntry, [
                runtime.runtimeTypeArgumentAt($getRuntimeType(runtime), 0) ??
                    runtime.lookupType(CoreTypes.dynamic),
                runtime.runtimeTypeArgumentAt($getRuntimeType(runtime), 1) ??
                    runtime.lookupType(CoreTypes.dynamic),
              ]),
            ],
          );
          return $Iterable.wrap(
            (_entries).map((e) {
              final value = $MapEntry.wrap(e);
              runtime.assertTypedTypeArgument(value, iterableType, 0);
              return value;
            }),
            runtime: runtime,
            runtimeTypeId: iterableType,
          );
        })();
      case 'keys':
        final _keys = $value.keys;
        return (() {
          final iterableType = runtime.internParameterizedType(
            CoreTypes.iterable,
            [
              runtime.runtimeTypeArgumentAt($getRuntimeType(runtime), 0) ??
                  runtime.lookupType(CoreTypes.dynamic),
            ],
          );
          return $Iterable.wrap(
            (_keys).map((e) {
              final value = (e is List || e is Map || e is Set
                  ? TypedInterop.boxExternal(e, runtime: runtime)!
                  : runtime.wrapAlways(e));
              runtime.assertTypedTypeArgument(value, iterableType, 0);
              return value;
            }),
            runtime: runtime,
            runtimeTypeId: iterableType,
          );
        })();
      case 'values':
        final _values = $value.values;
        return (() {
          final iterableType = runtime.internParameterizedType(
            CoreTypes.iterable,
            [
              runtime.runtimeTypeArgumentAt($getRuntimeType(runtime), 1) ??
                  runtime.lookupType(CoreTypes.dynamic),
            ],
          );
          return $Iterable.wrap(
            (_values).map((e) {
              final value = (e is List || e is Map || e is Set
                  ? TypedInterop.boxExternal(e, runtime: runtime)!
                  : runtime.wrapAlways(e));
              runtime.assertTypedTypeArgument(value, iterableType, 0);
              return value;
            }),
            runtime: runtime,
            runtimeTypeId: iterableType,
          );
        })();
      case 'length':
        final _length = $value.length;
        return $int(_length);
      case 'isEmpty':
        final _isEmpty = $value.isEmpty;
        return $bool(_isEmpty);
      case 'isNotEmpty':
        final _isNotEmpty = $value.isNotEmpty;
        return $bool(_isNotEmpty);
      case 'cast':
        return $Closure(__cast.func, this);

      case 'containsValue':
        return $Closure(__containsValue.func, this);

      case 'containsKey':
        return $Closure(__containsKey.func, this);

      case '[]':
        return $Closure(__operatorIndexGet.func, this);

      case '[]=':
        return $Closure(__operatorIndexSet.func, this);

      case 'map':
        return $Closure(__map.func, this);

      case 'addEntries':
        return $Closure(__addEntries.func, this);

      case 'update':
        return $Closure(__update.func, this);

      case 'updateAll':
        return $Closure(__updateAll.func, this);

      case 'removeWhere':
        return $Closure(__removeWhere.func, this);

      case 'putIfAbsent':
        return $Closure(__putIfAbsent.func, this);

      case 'addAll':
        return $Closure(__addAll.func, this);

      case 'remove':
        return $Closure(__remove.func, this);

      case 'clear':
        return $Closure(__clear.func, this);

      case 'forEach':
        return $Closure(__forEach.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __cast = $Function(_cast);
  static $Value? _cast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    final result = self.$value.cast();
    return wrapMap(
      result,
      (key, value) => MapEntry(
        (key is List || key is Map || key is Set
            ? TypedInterop.boxExternal(key, runtime: runtime)!
            : runtime.wrapAlways(key)),
        (value is List || value is Map || value is Set
            ? TypedInterop.boxExternal(value, runtime: runtime)!
            : runtime.wrapAlways(value)),
      ),
    );
  }

  static const $Function __containsValue = $Function(_containsValue);
  static $Value? _containsValue(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    final result = self.$value.containsValue(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
    );
    return $bool(result);
  }

  static const $Function __containsKey = $Function(_containsKey);
  static $Value? _containsKey(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    final result = self.$value.containsKey(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
    );
    return $bool(result);
  }

  static const $Function __operatorIndexGet = $Function(_operatorIndexGet);
  static $Value? _operatorIndexGet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    final result =
        self.$value[TypedInterop.exportExternal(
          (r as $Value?),
          runtime: runtime,
        ) as Object?];
    return result == null
        ? const $null()
        : (result is List || result is Map || result is Set
              ? TypedInterop.boxExternal(result, runtime: runtime)!
              : runtime.wrapAlways(result));
  }

  static const $Function __operatorIndexSet = $Function(_operatorIndexSet);
  static $Value? _operatorIndexSet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    self.$value[TypedInterop.exportExternal((r as $Value?), runtime: runtime)
        as dynamic] = TypedInterop.exportExternal(
      (s as $Value?),
      runtime: runtime,
    ) as dynamic;
    return null;
  }

  static const $Function __map = $Function(_map);
  static $Value? _map(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    final result = self.$value.map(
      (() {
        final _callbackType0 =
            runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 0) ??
            runtime.lookupType(CoreTypes.dynamic);
        final _callbackType1 =
            runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 1) ??
            runtime.lookupType(CoreTypes.dynamic);
        return runtime.cachedCallback(
          (r as $Value?)! as EvalCallable,
          "MapEntry<K2, V2> Function(K, V);export=false" +
              ";types=$_callbackType0,$_callbackType1",
          (_callable) => (dynamic key, dynamic value) {
            return _callable
                    .call(
                      runtime,
                      null,
                      TypedInterop.boxExternal(
                        key,
                        runtime: runtime,
                        runtimeTypeId: _callbackType0,
                      ),
                      TypedInterop.boxExternal(
                        value,
                        runtime: runtime,
                        runtimeTypeId: _callbackType1,
                      ),
                      2,
                    )
                    ?.$value
                as MapEntry<dynamic, dynamic>;
          },
        );
      })(),
    );
    return wrapMap(
      result,
      (key, value) => MapEntry(
        (key is List || key is Map || key is Set
            ? TypedInterop.boxExternal(key, runtime: runtime)!
            : runtime.wrapAlways(key)),
        (value is List || value is Map || value is Set
            ? TypedInterop.boxExternal(value, runtime: runtime)!
            : runtime.wrapAlways(value)),
      ),
    );
  }

  static const $Function __addEntries = $Function(_addEntries);
  static $Value? _addEntries(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    self.$value.addEntries(
      TypedInterop.exportIterable((r as $Value?), runtime),
    );
    return null;
  }

  static const $Function __update = $Function(_update);
  static $Value? _update(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    final result = self.$value.update(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as dynamic,
      (() {
        final _callbackType0 =
            runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 1) ??
            runtime.lookupType(CoreTypes.dynamic);
        return runtime.cachedCallback(
          (s as $Value?)! as EvalCallable,
          "V Function(V);export=false" + ";types=$_callbackType0",
          (_callable) => (dynamic value) {
            return TypedInterop.exportExternal(
              _callable.call(
                runtime,
                null,
                TypedInterop.boxExternal(
                  value,
                  runtime: runtime,
                  runtimeTypeId: _callbackType0,
                ),
                null,
                1,
              ),
              runtime: runtime,
            ) as dynamic;
          },
        );
      })(),
      ifAbsent:
          (c is List && (c as List).length > 0
                      ? (c as List)[0] as $Value?
                      : null) ==
                  null ||
              (c is List && (c as List).length > 0
                      ? (c as List)[0] as $Value?
                      : null)
                  is $null
          ? null
          : runtime.cachedCallback(
              (c is List && (c as List).length > 0
                      ? (c as List)[0] as $Value?
                      : null)!
                  as EvalCallable,
              "V Function();export=false",
              (_callable) => () {
                return TypedInterop.exportExternal(
                  _callable.call(runtime, null, null, null, 0),
                  runtime: runtime,
                ) as dynamic;
              },
            ),
    );
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __updateAll = $Function(_updateAll);
  static $Value? _updateAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    self.$value.updateAll(
      (() {
        final _callbackType0 =
            runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 0) ??
            runtime.lookupType(CoreTypes.dynamic);
        final _callbackType1 =
            runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 1) ??
            runtime.lookupType(CoreTypes.dynamic);
        return runtime.cachedCallback(
          (r as $Value?)! as EvalCallable,
          "V Function(K, V);export=false" +
              ";types=$_callbackType0,$_callbackType1",
          (_callable) => (dynamic key, dynamic value) {
            return TypedInterop.exportExternal(
              _callable.call(
                runtime,
                null,
                TypedInterop.boxExternal(
                  key,
                  runtime: runtime,
                  runtimeTypeId: _callbackType0,
                ),
                TypedInterop.boxExternal(
                  value,
                  runtime: runtime,
                  runtimeTypeId: _callbackType1,
                ),
                2,
              ),
              runtime: runtime,
            ) as dynamic;
          },
        );
      })(),
    );
    return null;
  }

  static const $Function __removeWhere = $Function(_removeWhere);
  static $Value? _removeWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    self.$value.removeWhere(
      (() {
        final _callbackType0 =
            runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 0) ??
            runtime.lookupType(CoreTypes.dynamic);
        final _callbackType1 =
            runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 1) ??
            runtime.lookupType(CoreTypes.dynamic);
        return runtime.cachedCallback(
          (r as $Value?)! as EvalCallable,
          "bool Function(K, V);export=false" +
              ";types=$_callbackType0,$_callbackType1",
          (_callable) => (dynamic key, dynamic value) {
            return _callable
                    .call(
                      runtime,
                      null,
                      TypedInterop.boxExternal(
                        key,
                        runtime: runtime,
                        runtimeTypeId: _callbackType0,
                      ),
                      TypedInterop.boxExternal(
                        value,
                        runtime: runtime,
                        runtimeTypeId: _callbackType1,
                      ),
                      2,
                    )
                    ?.$value
                as bool;
          },
        );
      })(),
    );
    return null;
  }

  static const $Function __putIfAbsent = $Function(_putIfAbsent);
  static $Value? _putIfAbsent(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    final result = self.$value.putIfAbsent(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as dynamic,
      runtime.cachedCallback(
        (s as $Value?)! as EvalCallable,
        "V Function();export=false",
        (_callable) => () {
          return TypedInterop.exportExternal(
            _callable.call(runtime, null, null, null, 0),
            runtime: runtime,
          ) as dynamic;
        },
      ),
    );
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __addAll = $Function(_addAll);
  static $Value? _addAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    self.$value.addAll(
      ((r as $Value?)!.$reified as Map).cast<dynamic, dynamic>(),
    );
    return null;
  }

  static const $Function __remove = $Function(_remove);
  static $Value? _remove(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    final result = self.$value.remove(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
    );
    return result == null
        ? const $null()
        : (result is List || result is Map || result is Set
              ? TypedInterop.boxExternal(result, runtime: runtime)!
              : runtime.wrapAlways(result));
  }

  static const $Function __clear = $Function(_clear);
  static $Value? _clear(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    self.$value.clear();
    return null;
  }

  static const $Function __forEach = $Function(_forEach);
  static $Value? _forEach(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashMap;
    self.$value.forEach(
      (() {
        final _callbackType0 =
            runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 0) ??
            runtime.lookupType(CoreTypes.dynamic);
        final _callbackType1 =
            runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 1) ??
            runtime.lookupType(CoreTypes.dynamic);
        return runtime.cachedCallback(
          (r as $Value?)! as EvalCallable,
          "void Function(K, V);export=false" +
              ";types=$_callbackType0,$_callbackType1",
          (_callable) => (dynamic key, dynamic value) {
            _callable.call(
              runtime,
              null,
              TypedInterop.boxExternal(
                key,
                runtime: runtime,
                runtimeTypeId: _callbackType0,
              ),
              TypedInterop.boxExternal(
                value,
                runtime: runtime,
                runtimeTypeId: _callbackType1,
              ),
              2,
            );
          },
        );
      })(),
    );
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
