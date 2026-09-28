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
        $ListQueue,
        $Queue,
        $HashMap,
        $HashSet,
        $LinkedHashSet,
        $DoubleLinkedQueue,
        $DoubleLinkedQueueEntry,
        $MapBase;
import 'package:dart_eval/src/eval/utils/wrap_helper.dart';

/// dart_eval wrapper binding for [MapBase]
class $MapBase<K, V> implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'MapBase.mapToString',
      $MapBase.$mapToString,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$MapBase]
  static const $spec = BridgeTypeSpec('dart:collection', 'MapBase');

  /// Compile-time type declaration of [$MapBase]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$MapBase]
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
          namedParams: [],
          params: [],
        ),
        isFactory: false,
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
              'transform',
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
      ),

      'clear': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),
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
      ),

      'mapToString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'm',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
                  ),
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
                  ),
                ]),
              ),
              false,
            ),
          ],
        ),

        isStatic: true,
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
      ),

      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isEmpty': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isNotEmpty': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [MapBase.mapToString] method
  static $Value? $mapToString(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = MapBase.mapToString(
      ((r as $Value?)!.$reified as Map).cast<Object?, Object?>(),
    );
    return $String(value);
  }

  final $Instance _superclass;

  @override
  final MapBase<K, V> $value;

  @override
  MapBase get $reified => $value;

  /// Wrap a [MapBase] in a [$MapBase]
  $MapBase.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'entries':
        final _entries = $value.entries;
        return $Iterable.wrap((_entries).map((e) => $MapEntry.wrap(e)));
      case 'keys':
        final _keys = $value.keys;
        return $Iterable.wrap(
          (_keys).map((e) => runtime.wrapAlways(e, recursive: true)),
        );
      case 'values':
        final _values = $value.values;
        return $Iterable.wrap(
          (_values).map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $MapBase;
    final result = self.$value.cast();
    return wrapMap(
      result,
      (key, value) => MapEntry(
        runtime.wrapAlways(key, recursive: true),
        runtime.wrapAlways(value, recursive: true),
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
    final self = target! as $MapBase;
    final result = self.$value.containsValue((r as $Value?)!.$reified);
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
    final self = target! as $MapBase;
    final result = self.$value.containsKey((r as $Value?)!.$reified);
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
    final self = target! as $MapBase;
    final result = self.$value[(r as $Value?)!.$reified];
    return result == null
        ? const $null()
        : runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __operatorIndexSet = $Function(_operatorIndexSet);
  static $Value? _operatorIndexSet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $MapBase;
    self.$value[(r as $Value?)!.$value] = (s as $Value?)!.$value;
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
    final self = target! as $MapBase;
    final result = self.$value.map((dynamic key, dynamic value) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(key, recursive: true),
        runtime.wrapAlways(value, recursive: true),
        2,
      )?.$value;
    });
    return wrapMap(
      result,
      (key, value) => MapEntry(
        runtime.wrapAlways(key, recursive: true),
        runtime.wrapAlways(value, recursive: true),
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
    final self = target! as $MapBase;
    self.$value.addEntries((r as $Value?)!.$value);
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
    final self = target! as $MapBase;
    final result = self.$value.update(
      (r as $Value?)!.$value,
      (dynamic value) {
        return ((s as $Value?)! as EvalCallable)(
          runtime,
          null,
          runtime.wrapAlways(value, recursive: true),
          null,
          1,
        )?.$value;
      },
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
          : () {
              return ((c is List && (c as List).length > 0
                          ? (c as List)[0] as $Value?
                          : null)!
                      as EvalCallable?)
                  ?.call(runtime, null, null, null, 0)
                  ?.$value;
            },
    );
    return runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __updateAll = $Function(_updateAll);
  static $Value? _updateAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $MapBase;
    self.$value.updateAll((dynamic key, dynamic value) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(key, recursive: true),
        runtime.wrapAlways(value, recursive: true),
        2,
      )?.$value;
    });
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
    final self = target! as $MapBase;
    self.$value.removeWhere((dynamic key, dynamic value) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(key, recursive: true),
        runtime.wrapAlways(value, recursive: true),
        2,
      )?.$value;
    });
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
    final self = target! as $MapBase;
    final result = self.$value.putIfAbsent((r as $Value?)!.$value, () {
      return ((s as $Value?)! as EvalCallable)(
        runtime,
        null,
        null,
        null,
        0,
      )?.$value;
    });
    return runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __addAll = $Function(_addAll);
  static $Value? _addAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $MapBase;
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
    final self = target! as $MapBase;
    final result = self.$value.remove((r as $Value?)!.$reified);
    return result == null
        ? const $null()
        : runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __clear = $Function(_clear);
  static $Value? _clear(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $MapBase;
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
    final self = target! as $MapBase;
    self.$value.forEach((dynamic key, dynamic value) {
      ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(key, recursive: true),
        runtime.wrapAlways(value, recursive: true),
        2,
      );
    });
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
