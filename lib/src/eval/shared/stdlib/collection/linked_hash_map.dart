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

import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart'
    hide
        $LinkedHashMap,
        $UnmodifiableListView,
        $ListQueue,
        $Queue,
        $HashMap,
        $SplayTreeMap,
        $HashSet,
        $LinkedHashSet,
        $DoubleLinkedQueue,
        $DoubleLinkedQueueEntry,
        $ListBase,
        $MapBase,
        $SetBase;
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../core/map_entry.dart';

import 'package:dart_eval/src/eval/utils/wrap_helper.dart';

/// dart_eval wrapper binding for [LinkedHashMap]
class $LinkedHashMap<K, V> implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'LinkedHashMap.',
      $LinkedHashMap.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'LinkedHashMap.identity',
      $LinkedHashMap.$identity,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'LinkedHashMap.from',
      $LinkedHashMap.$from,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'LinkedHashMap.of',
      $LinkedHashMap.$of,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'LinkedHashMap.fromIterable',
      $LinkedHashMap.$fromIterable,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'LinkedHashMap.fromIterables',
      $LinkedHashMap.$fromIterables,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'LinkedHashMap.fromEntries',
      $LinkedHashMap.$fromEntries,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$LinkedHashMap]
  static const $spec = BridgeTypeSpec('dart:collection', 'LinkedHashMap');

  /// Compile-time type declaration of [$LinkedHashMap]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$LinkedHashMap]
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

  /// Wrapper for the [LinkedHashMap.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $LinkedHashMap.wrap(
      LinkedHashMap(
        equals:
            (r is $Value ? r : null) == null ||
                (r is $Value ? r : null) is $null
            ? null
            : runtime.cachedCallback(
                (r is $Value ? r : null)! as EvalCallable,
                "bool Function(K, K);export=false",
                (_callable) => (dynamic arg0, dynamic arg1) {
                  return _callable
                      .call(
                        runtime,
                        null,
                        runtime.wrapAlways(arg0, recursive: true),
                        runtime.wrapAlways(arg1, recursive: true),
                        2,
                      )
                      ?.$value;
                },
              ),
        hashCode:
            (s is $Value ? s : null) == null ||
                (s is $Value ? s : null) is $null
            ? null
            : runtime.cachedCallback(
                (s is $Value ? s : null)! as EvalCallable,
                "int Function(K);export=false",
                (_callable) => (dynamic arg0) {
                  return _callable
                      .call(
                        runtime,
                        null,
                        runtime.wrapAlways(arg0, recursive: true),
                        null,
                        1,
                      )
                      ?.$value;
                },
              ),
        isValidKey:
            (c is $Value ? c : null) == null ||
                (c is $Value ? c : null) is $null
            ? null
            : runtime.cachedCallback(
                (c is $Value ? c : null)! as EvalCallable,
                "bool Function(dynamic);export=false",
                (_callable) => (dynamic arg0) {
                  return _callable
                      .call(
                        runtime,
                        null,
                        runtime.wrapAlways(arg0, recursive: true),
                        null,
                        1,
                      )
                      ?.$value;
                },
              ),
      ),
    );
  }

  /// Wrapper for the [LinkedHashMap.identity] constructor
  static $Value? $identity(Runtime runtime, Object? r, Object? s, Object? c) {
    return $LinkedHashMap.wrap(LinkedHashMap.identity());
  }

  /// Wrapper for the [LinkedHashMap.from] constructor
  static $Value? $from(Runtime runtime, Object? r, Object? s, Object? c) {
    return $LinkedHashMap.wrap(
      LinkedHashMap.from(
        ((r as $Value?)!.$reified as Map).cast<dynamic, dynamic>(),
      ),
    );
  }

  /// Wrapper for the [LinkedHashMap.of] constructor
  static $Value? $of(Runtime runtime, Object? r, Object? s, Object? c) {
    return $LinkedHashMap.wrap(
      LinkedHashMap.of(
        ((r as $Value?)!.$reified as Map).cast<dynamic, dynamic>(),
      ),
    );
  }

  /// Wrapper for the [LinkedHashMap.fromIterable] constructor
  static $Value? $fromIterable(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $LinkedHashMap.wrap(
      LinkedHashMap.fromIterable(
        TypedInterop.exportIterable((r as $Value?), runtime),
        key:
            (s is $Value ? s : null) == null ||
                (s is $Value ? s : null) is $null
            ? null
            : runtime.cachedCallback(
                (s is $Value ? s : null)! as EvalCallable,
                "K Function(dynamic);export=false",
                (_callable) => (dynamic element) {
                  return _callable
                      .call(
                        runtime,
                        null,
                        runtime.wrapAlways(element, recursive: true),
                        null,
                        1,
                      )
                      ?.$value;
                },
              ),
        value:
            (c is $Value ? c : null) == null ||
                (c is $Value ? c : null) is $null
            ? null
            : runtime.cachedCallback(
                (c is $Value ? c : null)! as EvalCallable,
                "V Function(dynamic);export=false",
                (_callable) => (dynamic element) {
                  return _callable
                      .call(
                        runtime,
                        null,
                        runtime.wrapAlways(element, recursive: true),
                        null,
                        1,
                      )
                      ?.$value;
                },
              ),
      ),
    );
  }

  /// Wrapper for the [LinkedHashMap.fromIterables] constructor
  static $Value? $fromIterables(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $LinkedHashMap.wrap(
      LinkedHashMap.fromIterables(
        TypedInterop.exportIterable((r as $Value?), runtime),
        TypedInterop.exportIterable((s as $Value?), runtime),
      ),
    );
  }

  /// Wrapper for the [LinkedHashMap.fromEntries] constructor
  static $Value? $fromEntries(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $LinkedHashMap.wrap(
      LinkedHashMap.fromEntries(
        TypedInterop.exportIterable((r as $Value?), runtime),
      ),
    );
  }

  final $Instance _superclass;

  @override
  final LinkedHashMap<K, V> $value;

  @override
  LinkedHashMap<K, V> get $reified => $value;

  /// Wrap a [LinkedHashMap] in a [$LinkedHashMap]
  $LinkedHashMap.wrap(this.$value) : _superclass = $Object($value);

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
        return $Iterable.wrap((_entries).map((e) => $MapEntry.wrap(e)));
      case 'keys':
        final _keys = $value.keys;
        return $Iterable.wrap(
          (_keys).map(
            (e) => (e is List || e is Map || e is Set
                ? TypedInterop.boxExternal(e, runtime: runtime)!
                : runtime.wrapAlways(e)),
          ),
        );
      case 'values':
        final _values = $value.values;
        return $Iterable.wrap(
          (_values).map(
            (e) => (e is List || e is Map || e is Set
                ? TypedInterop.boxExternal(e, runtime: runtime)!
                : runtime.wrapAlways(e)),
          ),
        );
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
    final self = target! as $LinkedHashMap;
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
    final self = target! as $LinkedHashMap;
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
    final self = target! as $LinkedHashMap;
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
    final self = target! as $LinkedHashMap;
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
    final self = target! as $LinkedHashMap;
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
    final self = target! as $LinkedHashMap;
    final result = self.$value.map(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "MapEntry<K2, V2> Function(K, V);export=false",
        (_callable) => (dynamic key, dynamic value) {
          return _callable
              .call(
                runtime,
                null,
                runtime.wrapAlways(key, recursive: true),
                runtime.wrapAlways(value, recursive: true),
                2,
              )
              ?.$value;
        },
      ),
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
    final self = target! as $LinkedHashMap;
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
    final self = target! as $LinkedHashMap;
    final result = self.$value.update(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as dynamic,
      runtime.cachedCallback(
        (s as $Value?)! as EvalCallable,
        "V Function(V);export=false",
        (_callable) => (dynamic value) {
          return _callable
              .call(
                runtime,
                null,
                runtime.wrapAlways(value, recursive: true),
                null,
                1,
              )
              ?.$value;
        },
      ),
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
                return _callable.call(runtime, null, null, null, 0)?.$value;
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
    final self = target! as $LinkedHashMap;
    self.$value.updateAll(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "V Function(K, V);export=false",
        (_callable) => (dynamic key, dynamic value) {
          return _callable
              .call(
                runtime,
                null,
                runtime.wrapAlways(key, recursive: true),
                runtime.wrapAlways(value, recursive: true),
                2,
              )
              ?.$value;
        },
      ),
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
    final self = target! as $LinkedHashMap;
    self.$value.removeWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(K, V);export=false",
        (_callable) => (dynamic key, dynamic value) {
          return _callable
              .call(
                runtime,
                null,
                runtime.wrapAlways(key, recursive: true),
                runtime.wrapAlways(value, recursive: true),
                2,
              )
              ?.$value;
        },
      ),
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
    final self = target! as $LinkedHashMap;
    final result = self.$value.putIfAbsent(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as dynamic,
      runtime.cachedCallback(
        (s as $Value?)! as EvalCallable,
        "V Function();export=false",
        (_callable) => () {
          return _callable.call(runtime, null, null, null, 0)?.$value;
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
    final self = target! as $LinkedHashMap;
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
    final self = target! as $LinkedHashMap;
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
    final self = target! as $LinkedHashMap;
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
    final self = target! as $LinkedHashMap;
    self.$value.forEach(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "void Function(K, V);export=false",
        (_callable) => (dynamic key, dynamic value) {
          _callable.call(
            runtime,
            null,
            runtime.wrapAlways(key, recursive: true),
            runtime.wrapAlways(value, recursive: true),
            2,
          );
        },
      ),
    );
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
