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

import 'package:dart_eval/stdlib/core.dart'
    hide
        $Duration,
        $BigInt,
        $DateTime,
        $Iterator,
        $Comparable,
        $Sink,
        $StackTrace,
        $StringBuffer,
        $Runes,
        $RuneIterator,
        $Expando,
        $Symbol,
        $MapEntry,
        $Stopwatch,
        $pragma,
        $Error,
        $StackOverflowError,
        $OutOfMemoryError,
        $TypeError,
        $NoSuchMethodError,
        $RangeError,
        $AssertionError,
        $ArgumentError,
        $StateError,
        $UnsupportedError,
        $UnimplementedError,
        $ConcurrentModificationError,
        $Exception,
        $FormatException,
        $Uri,
        $Pattern,
        $Match,
        $RegExp,
        $RegExpMatch,
        $StringSink,
        $Enum;
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

/// dart_eval wrapper binding for [Runes]
class $Runes implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:core', 'Runes.', $Runes.$new);
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Runes]
  static const $spec = BridgeTypeSpec('dart:core', 'Runes');

  /// Compile-time type declaration of [$Runes]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Runes]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(CoreTypes.iterable, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        ]),
      ],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'string',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {
      'cast': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'R': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'followedBy': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'map': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'toElement',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                    params: [
                      BridgeParameter(
                        'e',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

      'where': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
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
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

      'whereType': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'expand': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'toElements',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.iterable, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                      ]),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

      'contains': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'element',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
            ),
          ],
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
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

      'reduce': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'combine',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.int, []),
                    ),
                    params: [
                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),

                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

      'fold': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
          namedParams: [],
          params: [
            BridgeParameter(
              'initialValue',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),

            BridgeParameter(
              'combine',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                    params: [
                      BridgeParameter(
                        'previousValue',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                        false,
                      ),

                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

      'every': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
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
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

      'join': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'separator',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
              defaultValueSource: "\"\"",
            ),
          ],
        ),
      ),

      'any': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
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
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

      'toList': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'growable',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "true",
            ),
          ],
          params: [],
        ),
      ),

      'toSet': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.set, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'take': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'count',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'takeWhile': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
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
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

      'skip': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'count',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'skipWhile': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
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
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

      'firstWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.int, []),
                    ),
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
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

      'lastWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.int, []),
                    ),
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
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

      'singleWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.int, []),
                    ),
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
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

      'elementAt': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),
    },
    getters: {
      'iterator': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.runeIterator, []),
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

      'first': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'last': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'single': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {
      'string': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Runes.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Runes.wrap(Runes((r as $String).$value));
  }

  final $Instance _superclass;

  @override
  final Runes $value;

  @override
  Runes get $reified => $value;

  /// Wrap a [Runes] in a [$Runes]
  $Runes.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'iterator':
        final _iterator = $value.iterator;
        return $RuneIterator.wrap(_iterator);
      case 'length':
        final _length = $value.length;
        return $int(_length);
      case 'isEmpty':
        final _isEmpty = $value.isEmpty;
        return $bool(_isEmpty);
      case 'isNotEmpty':
        final _isNotEmpty = $value.isNotEmpty;
        return $bool(_isNotEmpty);
      case 'first':
        final _first = $value.first;
        return $int(_first);
      case 'last':
        final _last = $value.last;
        return $int(_last);
      case 'single':
        final _single = $value.single;
        return $int(_single);
      case 'string':
        final _string = $value.string;
        return $String(_string);
      case 'cast':
        return $Closure(__cast.func, this);

      case 'followedBy':
        return $Closure(__followedBy.func, this);

      case 'map':
        return $Closure(__map.func, this);

      case 'where':
        return $Closure(__where.func, this);

      case 'whereType':
        return $Closure(__whereType.func, this);

      case 'expand':
        return $Closure(__expand.func, this);

      case 'contains':
        return $Closure(__contains.func, this);

      case 'forEach':
        return $Closure(__forEach.func, this);

      case 'reduce':
        return $Closure(__reduce.func, this);

      case 'fold':
        return $Closure(__fold.func, this);

      case 'every':
        return $Closure(__every.func, this);

      case 'join':
        return $Closure(__join.func, this);

      case 'any':
        return $Closure(__any.func, this);

      case 'toList':
        return $Closure(__toList.func, this);

      case 'toSet':
        return $Closure(__toSet.func, this);

      case 'take':
        return $Closure(__take.func, this);

      case 'takeWhile':
        return $Closure(__takeWhile.func, this);

      case 'skip':
        return $Closure(__skip.func, this);

      case 'skipWhile':
        return $Closure(__skipWhile.func, this);

      case 'firstWhere':
        return $Closure(__firstWhere.func, this);

      case 'lastWhere':
        return $Closure(__lastWhere.func, this);

      case 'singleWhere':
        return $Closure(__singleWhere.func, this);

      case 'elementAt':
        return $Closure(__elementAt.func, this);
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
    final self = target! as $Runes;
    final result = self.$value.cast();
    return (() {
      final bridgeTypeArguments = runtime.bridgeCallTypeArguments;
      return (() {
        final iterableType = runtime.internParameterizedType(
          CoreTypes.iterable,
          [
            (bridgeTypeArguments.length > 0
                ? bridgeTypeArguments[0]
                : runtime.lookupType(CoreTypes.dynamic)),
          ],
        );
        return $Iterable.wrap(
          (result).map((e) {
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
    })();
  }

  static const $Function __followedBy = $Function(_followedBy);
  static $Value? _followedBy(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.followedBy(
      TypedInterop.exportIterable((r as $Value?), runtime),
    );
    return (() {
      final iterableType = runtime.internParameterizedType(CoreTypes.iterable, [
        runtime.lookupType(CoreTypes.int),
      ]);
      return $Iterable.wrap(
        (result).map((e) {
          final value = $int(e);
          runtime.assertTypedTypeArgument(value, iterableType, 0);
          return value;
        }),
        runtime: runtime,
        runtimeTypeId: iterableType,
      );
    })();
  }

  static const $Function __map = $Function(_map);
  static $Value? _map(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.map(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "T Function(int);export=false",
        (_callable) => (int e) {
          return TypedInterop.exportExternal(
            _callable.call(runtime, null, $int(e), null, 1),
            runtime: runtime,
          ) as dynamic;
        },
      ),
    );
    return $Iterable.wrap(
      (result).map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
    );
  }

  static const $Function __where = $Function(_where);
  static $Value? _where(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.where(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(int);export=false",
        (_callable) => (int element) {
          return _callable.call(runtime, null, $int(element), null, 1)?.$value;
        },
      ),
    );
    return (() {
      final iterableType = runtime.internParameterizedType(CoreTypes.iterable, [
        runtime.lookupType(CoreTypes.int),
      ]);
      return $Iterable.wrap(
        (result).map((e) {
          final value = $int(e);
          runtime.assertTypedTypeArgument(value, iterableType, 0);
          return value;
        }),
        runtime: runtime,
        runtimeTypeId: iterableType,
      );
    })();
  }

  static const $Function __whereType = $Function(_whereType);
  static $Value? _whereType(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.whereType();
    return (() {
      final bridgeTypeArguments = runtime.bridgeCallTypeArguments;
      return (() {
        final iterableType = runtime.internParameterizedType(
          CoreTypes.iterable,
          [
            (bridgeTypeArguments.length > 0
                ? bridgeTypeArguments[0]
                : runtime.lookupType(CoreTypes.dynamic)),
          ],
        );
        return $Iterable.wrap(
          (result).map((e) {
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
    })();
  }

  static const $Function __expand = $Function(_expand);
  static $Value? _expand(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.expand(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "Iterable<T> Function(int);export=false",
        (_callable) => (int element) {
          return _callable.call(runtime, null, $int(element), null, 1)?.$value;
        },
      ),
    );
    return $Iterable.wrap(
      (result).map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
    );
  }

  static const $Function __contains = $Function(_contains);
  static $Value? _contains(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.contains(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
    );
    return $bool(result);
  }

  static const $Function __forEach = $Function(_forEach);
  static $Value? _forEach(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    self.$value.forEach(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "void Function(int);export=false",
        (_callable) => (int element) {
          _callable.call(runtime, null, $int(element), null, 1);
        },
      ),
    );
    return null;
  }

  static const $Function __reduce = $Function(_reduce);
  static $Value? _reduce(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.reduce(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "int Function(int, int);export=false",
        (_callable) => (int value, int element) {
          return _callable
              .call(runtime, null, $int(value), $int(element), 2)
              ?.$value;
        },
      ),
    );
    return $int(result);
  }

  static const $Function __fold = $Function(_fold);
  static $Value? _fold(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.fold(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as dynamic,
      runtime.cachedCallback(
        (s as $Value?)! as EvalCallable,
        "T Function(T, int);export=false",
        (_callable) => (dynamic previousValue, int element) {
          return TypedInterop.exportExternal(
            _callable.call(
              runtime,
              null,
              runtime.wrapAlways(previousValue, recursive: true),
              $int(element),
              2,
            ),
            runtime: runtime,
          ) as dynamic;
        },
      ),
    );
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __every = $Function(_every);
  static $Value? _every(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.every(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(int);export=false",
        (_callable) => (int element) {
          return _callable.call(runtime, null, $int(element), null, 1)?.$value;
        },
      ),
    );
    return $bool(result);
  }

  static const $Function __join = $Function(_join);
  static $Value? _join(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.join(
      (r is $Value ? r : null) == null ? "" : (r as $String).$value,
    );
    return $String(result);
  }

  static const $Function __any = $Function(_any);
  static $Value? _any(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.any(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(int);export=false",
        (_callable) => (int element) {
          return _callable.call(runtime, null, $int(element), null, 1)?.$value;
        },
      ),
    );
    return $bool(result);
  }

  static const $Function __toList = $Function(_toList);
  static $Value? _toList(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.toList(
      growable: (r is $Value ? r : null) == null ? true : (r as $bool).$value,
    );
    return $List.view(
      result,
      (e) => $int(e),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.lookupType(CoreTypes.int),
      ]),
    );
  }

  static const $Function __toSet = $Function(_toSet);
  static $Value? _toSet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.toSet();
    return $Set.wrap((result).map((e) => $int(e)).toSet());
  }

  static const $Function __take = $Function(_take);
  static $Value? _take(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.take((r as $int).$value);
    return (() {
      final iterableType = runtime.internParameterizedType(CoreTypes.iterable, [
        runtime.lookupType(CoreTypes.int),
      ]);
      return $Iterable.wrap(
        (result).map((e) {
          final value = $int(e);
          runtime.assertTypedTypeArgument(value, iterableType, 0);
          return value;
        }),
        runtime: runtime,
        runtimeTypeId: iterableType,
      );
    })();
  }

  static const $Function __takeWhile = $Function(_takeWhile);
  static $Value? _takeWhile(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.takeWhile(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(int);export=false",
        (_callable) => (int value) {
          return _callable.call(runtime, null, $int(value), null, 1)?.$value;
        },
      ),
    );
    return (() {
      final iterableType = runtime.internParameterizedType(CoreTypes.iterable, [
        runtime.lookupType(CoreTypes.int),
      ]);
      return $Iterable.wrap(
        (result).map((e) {
          final value = $int(e);
          runtime.assertTypedTypeArgument(value, iterableType, 0);
          return value;
        }),
        runtime: runtime,
        runtimeTypeId: iterableType,
      );
    })();
  }

  static const $Function __skip = $Function(_skip);
  static $Value? _skip(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.skip((r as $int).$value);
    return (() {
      final iterableType = runtime.internParameterizedType(CoreTypes.iterable, [
        runtime.lookupType(CoreTypes.int),
      ]);
      return $Iterable.wrap(
        (result).map((e) {
          final value = $int(e);
          runtime.assertTypedTypeArgument(value, iterableType, 0);
          return value;
        }),
        runtime: runtime,
        runtimeTypeId: iterableType,
      );
    })();
  }

  static const $Function __skipWhile = $Function(_skipWhile);
  static $Value? _skipWhile(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.skipWhile(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(int);export=false",
        (_callable) => (int value) {
          return _callable.call(runtime, null, $int(value), null, 1)?.$value;
        },
      ),
    );
    return (() {
      final iterableType = runtime.internParameterizedType(CoreTypes.iterable, [
        runtime.lookupType(CoreTypes.int),
      ]);
      return $Iterable.wrap(
        (result).map((e) {
          final value = $int(e);
          runtime.assertTypedTypeArgument(value, iterableType, 0);
          return value;
        }),
        runtime: runtime,
        runtimeTypeId: iterableType,
      );
    })();
  }

  static const $Function __firstWhere = $Function(_firstWhere);
  static $Value? _firstWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.firstWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(int);export=false",
        (_callable) => (int element) {
          return _callable.call(runtime, null, $int(element), null, 1)?.$value;
        },
      ),
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : runtime.cachedCallback(
              (s is $Value ? s : null)! as EvalCallable,
              "int Function();export=false",
              (_callable) => () {
                return _callable.call(runtime, null, null, null, 0)?.$value;
              },
            ),
    );
    return $int(result);
  }

  static const $Function __lastWhere = $Function(_lastWhere);
  static $Value? _lastWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.lastWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(int);export=false",
        (_callable) => (int element) {
          return _callable.call(runtime, null, $int(element), null, 1)?.$value;
        },
      ),
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : runtime.cachedCallback(
              (s is $Value ? s : null)! as EvalCallable,
              "int Function();export=false",
              (_callable) => () {
                return _callable.call(runtime, null, null, null, 0)?.$value;
              },
            ),
    );
    return $int(result);
  }

  static const $Function __singleWhere = $Function(_singleWhere);
  static $Value? _singleWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.singleWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(int);export=false",
        (_callable) => (int element) {
          return _callable.call(runtime, null, $int(element), null, 1)?.$value;
        },
      ),
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : runtime.cachedCallback(
              (s is $Value ? s : null)! as EvalCallable,
              "int Function();export=false",
              (_callable) => () {
                return _callable.call(runtime, null, null, null, 0)?.$value;
              },
            ),
    );
    return $int(result);
  }

  static const $Function __elementAt = $Function(_elementAt);
  static $Value? _elementAt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Runes;
    final result = self.$value.elementAt((r as $int).$value);
    return $int(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [RuneIterator]
class $RuneIterator implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'RuneIterator.',
      $RuneIterator.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'RuneIterator.at',
      $RuneIterator.$at,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$RuneIterator]
  static const $spec = BridgeTypeSpec('dart:core', 'RuneIterator');

  /// Compile-time type declaration of [$RuneIterator]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$RuneIterator]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(CoreTypes.iterator, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        ]),
      ],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'string',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),

      'at': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'string',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),

            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {
      'moveNext': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'reset': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'rawIndex',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "0",
            ),
          ],
        ),
      ),

      'movePrevious': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    getters: {
      'current': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'rawIndex': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'currentSize': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'currentAsString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {
      'rawIndex': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'rawIndex',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),
    },
    fields: {
      'string': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [RuneIterator.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $RuneIterator.wrap(RuneIterator((r as $String).$value));
  }

  /// Wrapper for the [RuneIterator.at] constructor
  static $Value? $at(Runtime runtime, Object? r, Object? s, Object? c) {
    return $RuneIterator.wrap(
      RuneIterator.at((r as $String).$value, (s as $int).$value),
    );
  }

  final $Instance _superclass;

  @override
  final RuneIterator $value;

  @override
  RuneIterator get $reified => $value;

  /// Wrap a [RuneIterator] in a [$RuneIterator]
  $RuneIterator.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'current':
        final _current = $value.current;
        return $int(_current);
      case 'string':
        final _string = $value.string;
        return $String(_string);
      case 'rawIndex':
        final _rawIndex = $value.rawIndex;
        return $int(_rawIndex);
      case 'currentSize':
        final _currentSize = $value.currentSize;
        return $int(_currentSize);
      case 'currentAsString':
        final _currentAsString = $value.currentAsString;
        return $String(_currentAsString);
      case 'moveNext':
        return $Closure(__moveNext.func, this);

      case 'reset':
        return $Closure(__reset.func, this);

      case 'movePrevious':
        return $Closure(__movePrevious.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __moveNext = $Function(_moveNext);
  static $Value? _moveNext(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $RuneIterator;
    final result = self.$value.moveNext();
    return $bool(result);
  }

  static const $Function __reset = $Function(_reset);
  static $Value? _reset(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $RuneIterator;
    self.$value.reset(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
    );
    return null;
  }

  static const $Function __movePrevious = $Function(_movePrevious);
  static $Value? _movePrevious(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $RuneIterator;
    final result = self.$value.movePrevious();
    return $bool(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      case 'rawIndex':
        $value.rawIndex = value.$reified;
        return;
    }
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
