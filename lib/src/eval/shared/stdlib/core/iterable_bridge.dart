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
        $DateTime,
        $Iterator,
        $Comparable,
        $Sink,
        $StackTrace,
        $StringBuffer,
        $Symbol,
        $MapEntry,
        $Stopwatch,
        $Error,
        $TypeError,
        $NoSuchMethodError,
        $RangeError,
        $AssertionError,
        $ArgumentError,
        $StateError,
        $UnsupportedError,
        $UnimplementedError,
        $Invocation,
        $Exception,
        $FormatException,
        $Uri,
        $Pattern,
        $Match,
        $RegExp,
        $RegExpMatch,
        $StringSink;
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

/// dart_eval bridge binding for [Iterable]
class $Iterable$bridge<E> extends Iterable<E> with $Bridge<Iterable<E>> {
  /// Forwarded constructor for [Iterable.new]
  $Iterable$bridge();

  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Iterable.',
      $Iterable$bridge.$new,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Iterable.generate',
      $Iterable$bridge.$generate,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Iterable.withIterator',
      $Iterable$bridge.$withIterator,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Iterable.empty',
      $Iterable$bridge.$empty,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Iterable.castFrom',
      $Iterable$bridge.$castFrom,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Iterable.iterableToShortString',
      $Iterable$bridge.$iterableToShortString,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Iterable.iterableToFullString',
      $Iterable$bridge.$iterableToFullString,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Iterable$bridge]
  static const $spec = BridgeTypeSpec('dart:core', 'Iterable');

  /// Compile-time type declaration of [$Iterable$bridge]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Iterable]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      generics: {'E': BridgeGenericParam()},
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

      'generate': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'count',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'generator',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                    params: [
                      BridgeParameter(
                        'index',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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
        ),
        isFactory: true,
      ),

      'withIterator': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'iteratorFactory',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.iterator, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                      ]),
                    ),
                    params: [],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'empty': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'castFrom': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'S': BridgeGenericParam(), 'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                ]),
              ),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

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
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
          namedParams: [],
          params: [
            BridgeParameter(
              'combine',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                    params: [
                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                        false,
                      ),

                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'growable',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
            ),
          ],
          params: [],
        ),
      ),

      'toSet': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.set, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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

      'iterableToShortString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
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

            BridgeParameter(
              'leftDelimiter',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
            ),

            BridgeParameter(
              'rightDelimiter',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
            ),
          ],
        ),

        isStatic: true,
      ),

      'iterableToFullString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
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

            BridgeParameter(
              'leftDelimiter',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
            ),

            BridgeParameter(
              'rightDelimiter',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
            ),
          ],
        ),

        isStatic: true,
      ),
    },
    getters: {
      'iterator': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterator, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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

      'first': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
          namedParams: [],
          params: [],
        ),
      ),

      'last': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
          namedParams: [],
          params: [],
        ),
      ),

      'single': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: false,
    bridge: true,
  );

  /// Proxy for the [Iterable.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Iterable$bridge();
  }

  /// Wrapper for the [Iterable.generate] constructor
  static $Value? $generate(Runtime runtime, Object? r, Object? s, Object? c) {
    final result = Iterable.generate(
      (r as $int).$value,
      (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : (int index) {
              return TypedInterop.exportExternal(
                ((s is $Value ? s : null)! as EvalCallable?)?.call(
                  runtime,
                  null,
                  $int(index),
                  null,
                  1,
                ),
                runtime: runtime,
              ) as dynamic;
            },
    );
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  /// Wrapper for the [Iterable.withIterator] constructor
  static $Value? $withIterator(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = Iterable.withIterator(() {
      return TypedInterop.exportIterator(
        ((r as $Value?)! as EvalCallable)(runtime, null, null, null, 0),
        runtime,
      );
    });
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  /// Wrapper for the [Iterable.empty] constructor
  static $Value? $empty(Runtime runtime, Object? r, Object? s, Object? c) {
    final result = Iterable.empty();
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  /// Wrapper for the [Iterable.castFrom] method
  static $Value? $castFrom(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Iterable.castFrom((r as $Value?)!.$value);
    return $Iterable.wrap(
      (value).map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  /// Wrapper for the [Iterable.iterableToShortString] method
  static $Value? $iterableToShortString(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Iterable.iterableToShortString(
      (r as $Value?)!.$value,
      (s is $Value ? s : null) == null ? '(' : (s as $String).$value,
      (c is $Value ? c : null) == null ? ')' : (c as $String).$value,
    );
    return $String(value);
  }

  /// Wrapper for the [Iterable.iterableToFullString] method
  static $Value? $iterableToFullString(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Iterable.iterableToFullString(
      (r as $Value?)!.$value,
      (s is $Value ? s : null) == null ? '(' : (s as $String).$value,
      (c is $Value ? c : null) == null ? ')' : (c as $String).$value,
    );
    return $String(value);
  }

  @override
  $Value? $bridgeGet(String identifier) {
    final runtime = $runtime;
    switch (identifier) {
      case 'length':
        final _length = super.length;
        return $int(_length);

      case 'isEmpty':
        final _isEmpty = super.isEmpty;
        return $bool(_isEmpty);

      case 'isNotEmpty':
        final _isNotEmpty = super.isNotEmpty;
        return $bool(_isNotEmpty);

      case 'first':
        final _first = super.first;
        return runtime.wrapAlways(_first, recursive: true);

      case 'last':
        final _last = super.last;
        return runtime.wrapAlways(_last, recursive: true);

      case 'single':
        final _single = super.single;
        return runtime.wrapAlways(_single, recursive: true);
      case 'cast':
        return $Function((runtime, target, r, s, c) {
          final result = super.cast();
          return $Iterable.wrap(
            (result).map((e) => runtime.wrapAlways(e, recursive: true)),
          );
        });
      case 'followedBy':
        return $Function((runtime, target, r, s, c) {
          final result = super.followedBy(
            TypedInterop.exportIterable((r as $Value?), runtime),
          );
          return $Iterable.wrap(
            (result).map((e) => runtime.wrapAlways(e, recursive: true)),
          );
        });
      case 'map':
        return $Function((runtime, target, r, s, c) {
          final result = super.map((dynamic e) {
            return TypedInterop.exportExternal(
              ((r as $Value?)! as EvalCallable)(
                runtime,
                null,
                runtime.wrapAlways(e, recursive: true),
                null,
                1,
              ),
              runtime: runtime,
            ) as dynamic;
          });
          return $Iterable.wrap(
            (result).map((e) => runtime.wrapAlways(e, recursive: true)),
          );
        });
      case 'where':
        return $Function((runtime, target, r, s, c) {
          final result = super.where((dynamic element) {
            return ((r as $Value?)! as EvalCallable)(
                  runtime,
                  null,
                  runtime.wrapAlways(element, recursive: true),
                  null,
                  1,
                )?.$value
                as bool;
          });
          return $Iterable.wrap(
            (result).map((e) => runtime.wrapAlways(e, recursive: true)),
          );
        });
      case 'whereType':
        return $Function((runtime, target, r, s, c) {
          final result = super.whereType();
          return $Iterable.wrap(
            (result).map((e) => runtime.wrapAlways(e, recursive: true)),
          );
        });
      case 'expand':
        return $Function((runtime, target, r, s, c) {
          final result = super.expand((dynamic element) {
            return TypedInterop.exportIterable(
              ((r as $Value?)! as EvalCallable)(
                runtime,
                null,
                runtime.wrapAlways(element, recursive: true),
                null,
                1,
              ),
              runtime,
            );
          });
          return $Iterable.wrap(
            (result).map((e) => runtime.wrapAlways(e, recursive: true)),
          );
        });
      case 'contains':
        return $Function((runtime, target, r, s, c) {
          final result = super.contains(
            TypedInterop.exportExternal((r as $Value?), runtime: runtime)
                as Object?,
          );
          return $bool(result);
        });
      case 'forEach':
        return $Function((runtime, target, r, s, c) {
          super.forEach((dynamic element) {
            ((r as $Value?)! as EvalCallable)(
              runtime,
              null,
              runtime.wrapAlways(element, recursive: true),
              null,
              1,
            );
          });
          return null;
        });
      case 'reduce':
        return $Function((runtime, target, r, s, c) {
          final result = super.reduce((dynamic value, dynamic element) {
            return TypedInterop.exportExternal(
              ((r as $Value?)! as EvalCallable)(
                runtime,
                null,
                runtime.wrapAlways(value, recursive: true),
                runtime.wrapAlways(element, recursive: true),
                2,
              ),
              runtime: runtime,
            ) as dynamic;
          });
          return runtime.wrapAlways(result, recursive: true);
        });
      case 'fold':
        return $Function((runtime, target, r, s, c) {
          final result = super.fold(
            TypedInterop.exportExternal((r as $Value?), runtime: runtime)
                as dynamic,
            (dynamic previousValue, dynamic element) {
              return TypedInterop.exportExternal(
                ((s as $Value?)! as EvalCallable)(
                  runtime,
                  null,
                  runtime.wrapAlways(previousValue, recursive: true),
                  runtime.wrapAlways(element, recursive: true),
                  2,
                ),
                runtime: runtime,
              ) as dynamic;
            },
          );
          return runtime.wrapAlways(result, recursive: true);
        });
      case 'every':
        return $Function((runtime, target, r, s, c) {
          final result = super.every((dynamic element) {
            return ((r as $Value?)! as EvalCallable)(
                  runtime,
                  null,
                  runtime.wrapAlways(element, recursive: true),
                  null,
                  1,
                )?.$value
                as bool;
          });
          return $bool(result);
        });
      case 'join':
        return $Function((runtime, target, r, s, c) {
          final result = super.join(
            (r is $Value ? r : null) == null ? "" : (r as $String).$value,
          );
          return $String(result);
        });
      case 'any':
        return $Function((runtime, target, r, s, c) {
          final result = super.any((dynamic element) {
            return ((r as $Value?)! as EvalCallable)(
                  runtime,
                  null,
                  runtime.wrapAlways(element, recursive: true),
                  null,
                  1,
                )?.$value
                as bool;
          });
          return $bool(result);
        });
      case 'toList':
        return $Function((runtime, target, r, s, c) {
          final result = super.toList(
            growable: (r is $Value ? r : null) == null
                ? true
                : (r as $bool).$value,
          );
          return $List.view(
            result,
            (e) => runtime.wrapAlways(e, recursive: true),
          );
        });
      case 'toSet':
        return $Function((runtime, target, r, s, c) {
          final result = super.toSet();
          return $Set.wrap(
            (result).map((e) => runtime.wrapAlways(e, recursive: true)).toSet(),
          );
        });
      case 'take':
        return $Function((runtime, target, r, s, c) {
          final result = super.take((r as $int).$value);
          return $Iterable.wrap(
            (result).map((e) => runtime.wrapAlways(e, recursive: true)),
          );
        });
      case 'takeWhile':
        return $Function((runtime, target, r, s, c) {
          final result = super.takeWhile((dynamic value) {
            return ((r as $Value?)! as EvalCallable)(
                  runtime,
                  null,
                  runtime.wrapAlways(value, recursive: true),
                  null,
                  1,
                )?.$value
                as bool;
          });
          return $Iterable.wrap(
            (result).map((e) => runtime.wrapAlways(e, recursive: true)),
          );
        });
      case 'skip':
        return $Function((runtime, target, r, s, c) {
          final result = super.skip((r as $int).$value);
          return $Iterable.wrap(
            (result).map((e) => runtime.wrapAlways(e, recursive: true)),
          );
        });
      case 'skipWhile':
        return $Function((runtime, target, r, s, c) {
          final result = super.skipWhile((dynamic value) {
            return ((r as $Value?)! as EvalCallable)(
                  runtime,
                  null,
                  runtime.wrapAlways(value, recursive: true),
                  null,
                  1,
                )?.$value
                as bool;
          });
          return $Iterable.wrap(
            (result).map((e) => runtime.wrapAlways(e, recursive: true)),
          );
        });
      case 'firstWhere':
        return $Function((runtime, target, r, s, c) {
          final result = super.firstWhere(
            (dynamic element) {
              return ((r as $Value?)! as EvalCallable)(
                    runtime,
                    null,
                    runtime.wrapAlways(element, recursive: true),
                    null,
                    1,
                  )?.$value
                  as bool;
            },
            orElse:
                (s is $Value ? s : null) == null ||
                    (s is $Value ? s : null) is $null
                ? null
                : () {
                    return TypedInterop.exportExternal(
                      ((s is $Value ? s : null)! as EvalCallable?)?.call(
                        runtime,
                        null,
                        null,
                        null,
                        0,
                      ),
                      runtime: runtime,
                    ) as dynamic;
                  },
          );
          return runtime.wrapAlways(result, recursive: true);
        });
      case 'lastWhere':
        return $Function((runtime, target, r, s, c) {
          final result = super.lastWhere(
            (dynamic element) {
              return ((r as $Value?)! as EvalCallable)(
                    runtime,
                    null,
                    runtime.wrapAlways(element, recursive: true),
                    null,
                    1,
                  )?.$value
                  as bool;
            },
            orElse:
                (s is $Value ? s : null) == null ||
                    (s is $Value ? s : null) is $null
                ? null
                : () {
                    return TypedInterop.exportExternal(
                      ((s is $Value ? s : null)! as EvalCallable?)?.call(
                        runtime,
                        null,
                        null,
                        null,
                        0,
                      ),
                      runtime: runtime,
                    ) as dynamic;
                  },
          );
          return runtime.wrapAlways(result, recursive: true);
        });
      case 'singleWhere':
        return $Function((runtime, target, r, s, c) {
          final result = super.singleWhere(
            (dynamic element) {
              return ((r as $Value?)! as EvalCallable)(
                    runtime,
                    null,
                    runtime.wrapAlways(element, recursive: true),
                    null,
                    1,
                  )?.$value
                  as bool;
            },
            orElse:
                (s is $Value ? s : null) == null ||
                    (s is $Value ? s : null) is $null
                ? null
                : () {
                    return TypedInterop.exportExternal(
                      ((s is $Value ? s : null)! as EvalCallable?)?.call(
                        runtime,
                        null,
                        null,
                        null,
                        0,
                      ),
                      runtime: runtime,
                    ) as dynamic;
                  },
          );
          return runtime.wrapAlways(result, recursive: true);
        });
      case 'elementAt':
        return $Function((runtime, target, r, s, c) {
          final result = super.elementAt((r as $int).$value);
          return runtime.wrapAlways(result, recursive: true);
        });
    }
    return null;
  }

  @override
  void $bridgeSet(String identifier, $Value value) {}

  @override
  Iterator<E> get iterator => TypedInterop.exportIterator<E>(
    $getProperty($runtime, 'iterator'),
    $runtime,
  );

  @override
  int get length => $_get('length');

  @override
  bool get isEmpty => $_get('isEmpty');

  @override
  bool get isNotEmpty => $_get('isNotEmpty');

  @override
  E get first => $_get('first');

  @override
  E get last => $_get('last');

  @override
  E get single => $_get('single');

  @override
  Iterable<R> cast<R>() {
    final runtime = $runtime;
    return $_invoke('cast', []);
  }

  @override
  Iterable<E> followedBy(Iterable<E> other) {
    final runtime = $runtime;
    return $_invoke('followedBy', [
      $Iterable.wrap(
        (other).map((e) => runtime.wrapAlways(e, recursive: true)),
      ),
    ]);
  }

  @override
  Iterable<T> map<T>(T Function(E) toElement) {
    final runtime = $runtime;
    return $_invoke('map', [
      $Function((runtime, target, r, s, c) {
        final funcResult = toElement((r as $Value?)!.$value);
        return runtime.wrapAlways(funcResult, recursive: true);
      }),
    ]);
  }

  @override
  Iterable<E> where(bool Function(E) test) {
    final runtime = $runtime;
    return $_invoke('where', [
      $Function((runtime, target, r, s, c) {
        final funcResult = test((r as $Value?)!.$value);
        return $bool(funcResult);
      }),
    ]);
  }

  @override
  Iterable<T> whereType<T>() {
    final runtime = $runtime;
    return $_invoke('whereType', []);
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E) toElements) {
    final runtime = $runtime;
    return $_invoke('expand', [
      $Function((runtime, target, r, s, c) {
        final funcResult = toElements((r as $Value?)!.$value);
        return $Iterable.wrap(
          (funcResult).map((e) => runtime.wrapAlways(e, recursive: true)),
        );
      }),
    ]);
  }

  @override
  bool contains(Object? element) {
    final runtime = $runtime;
    return $_invoke('contains', [
      element == null ? const $null() : $Object(element),
    ]);
  }

  @override
  void forEach(void Function(E) action) {
    final runtime = $runtime;
    $_invoke('forEach', [
      $Function((runtime, target, r, s, c) {
        action((r as $Value?)!.$value);
        return const $null();
      }),
    ]);
  }

  @override
  E reduce(E Function(E, E) combine) {
    final runtime = $runtime;
    return $_invoke('reduce', [
      $Function((runtime, target, r, s, c) {
        final funcResult = combine(
          (r as $Value?)!.$value,
          (s as $Value?)!.$value,
        );
        return runtime.wrapAlways(funcResult, recursive: true);
      }),
    ]);
  }

  @override
  T fold<T>(T initialValue, T Function(T, E) combine) {
    final runtime = $runtime;
    return $_invoke('fold', [
      runtime.wrapAlways(initialValue, recursive: true),
      $Function((runtime, target, r, s, c) {
        final funcResult = combine(
          (r as $Value?)!.$value,
          (s as $Value?)!.$value,
        );
        return runtime.wrapAlways(funcResult, recursive: true);
      }),
    ]);
  }

  @override
  bool every(bool Function(E) test) {
    final runtime = $runtime;
    return $_invoke('every', [
      $Function((runtime, target, r, s, c) {
        final funcResult = test((r as $Value?)!.$value);
        return $bool(funcResult);
      }),
    ]);
  }

  @override
  String join([String separator = ""]) {
    final runtime = $runtime;
    return $_invoke('join', [$String(separator)]);
  }

  @override
  bool any(bool Function(E) test) {
    final runtime = $runtime;
    return $_invoke('any', [
      $Function((runtime, target, r, s, c) {
        final funcResult = test((r as $Value?)!.$value);
        return $bool(funcResult);
      }),
    ]);
  }

  @override
  List<E> toList({bool growable = true}) {
    final runtime = $runtime;
    return ($_invoke('toList', [$bool(growable)]) as List).cast();
  }

  @override
  Set<E> toSet() {
    final runtime = $runtime;
    return ($_invoke('toSet', []) as Set).cast();
  }

  @override
  Iterable<E> take(int count) {
    final runtime = $runtime;
    return $_invoke('take', [$int(count)]);
  }

  @override
  Iterable<E> takeWhile(bool Function(E) test) {
    final runtime = $runtime;
    return $_invoke('takeWhile', [
      $Function((runtime, target, r, s, c) {
        final funcResult = test((r as $Value?)!.$value);
        return $bool(funcResult);
      }),
    ]);
  }

  @override
  Iterable<E> skip(int count) {
    final runtime = $runtime;
    return $_invoke('skip', [$int(count)]);
  }

  @override
  Iterable<E> skipWhile(bool Function(E) test) {
    final runtime = $runtime;
    return $_invoke('skipWhile', [
      $Function((runtime, target, r, s, c) {
        final funcResult = test((r as $Value?)!.$value);
        return $bool(funcResult);
      }),
    ]);
  }

  @override
  E firstWhere(bool Function(E) test, {E Function()? orElse}) {
    final runtime = $runtime;
    return $_invoke('firstWhere', [
      $Function((runtime, target, r, s, c) {
        final funcResult = test((r as $Value?)!.$value);
        return $bool(funcResult);
      }),
      orElse == null
          ? const $null()
          : $Function((runtime, target, r, s, c) {
              final funcResult = orElse();
              return runtime.wrapAlways(funcResult, recursive: true);
            }),
    ]);
  }

  @override
  E lastWhere(bool Function(E) test, {E Function()? orElse}) {
    final runtime = $runtime;
    return $_invoke('lastWhere', [
      $Function((runtime, target, r, s, c) {
        final funcResult = test((r as $Value?)!.$value);
        return $bool(funcResult);
      }),
      orElse == null
          ? const $null()
          : $Function((runtime, target, r, s, c) {
              final funcResult = orElse();
              return runtime.wrapAlways(funcResult, recursive: true);
            }),
    ]);
  }

  @override
  E singleWhere(bool Function(E) test, {E Function()? orElse}) {
    final runtime = $runtime;
    return $_invoke('singleWhere', [
      $Function((runtime, target, r, s, c) {
        final funcResult = test((r as $Value?)!.$value);
        return $bool(funcResult);
      }),
      orElse == null
          ? const $null()
          : $Function((runtime, target, r, s, c) {
              final funcResult = orElse();
              return runtime.wrapAlways(funcResult, recursive: true);
            }),
    ]);
  }

  @override
  E elementAt(int index) {
    final runtime = $runtime;
    return $_invoke('elementAt', [$int(index)]);
  }
}
