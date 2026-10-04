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
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import 'collection.dart' as hooks;

/// dart_eval bridge binding for [Iterable]
class $Iterable$bridge<E> extends Iterable<E> with $Bridge<Iterable<E>> {
  /// Forwarded constructor for [Iterable.new]
  $Iterable$bridge();

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
      isMixinClass: true,

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
              defaultValueSource: "'('",
            ),

            BridgeParameter(
              'rightDelimiter',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
              defaultValueSource: "')'",
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
              defaultValueSource: "'('",
            ),

            BridgeParameter(
              'rightDelimiter',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
              defaultValueSource: "')'",
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

        isAbstract: true,
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
          : runtime.cachedCallback(
              (s is $Value ? s : null)! as EvalCallable,
              "E Function(int);export=true",
              (_callable) => (int index) {
                return TypedInterop.exportExternal(
                  _callable.call(runtime, null, $int(index), null, 1),
                  runtime: runtime,
                ) as dynamic;
              },
            ),
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
    final result = Iterable.withIterator(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "Iterator<E> Function();export=true",
        (_callable) => () {
          return TypedInterop.exportIterator(
            _callable.call(runtime, null, null, null, 0),
            runtime,
          );
        },
      ),
    );
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
    final value = Iterable.castFrom(
      TypedInterop.exportIterable((r as $Value?), runtime),
    );
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
      TypedInterop.exportIterable((r as $Value?), runtime),
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
      TypedInterop.exportIterable((r as $Value?), runtime),
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
        return (_first is List || _first is Map || _first is Set
            ? TypedInterop.boxExternal(_first, runtime: runtime)!
            : runtime.wrapAlways(_first));

      case 'last':
        final _last = super.last;
        return (_last is List || _last is Map || _last is Set
            ? TypedInterop.boxExternal(_last, runtime: runtime)!
            : runtime.wrapAlways(_last));

      case 'single':
        final _single = super.single;
        return (_single is List || _single is Map || _single is Set
            ? TypedInterop.boxExternal(_single, runtime: runtime)!
            : runtime.wrapAlways(_single));
      case 'cast':
        return $Function((runtime, target, r, s, c) {
          final result = super.cast();
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
        });
      case 'followedBy':
        return $Function((runtime, target, r, s, c) {
          final result = super.followedBy(
            TypedInterop.exportIterable((r as $Value?), runtime),
          );
          return (() {
            final iterableType = runtime.internParameterizedType(
              CoreTypes.iterable,
              [
                runtime.runtimeTypeArgumentAt(
                      Runtime.bridgeData[this]!.$runtimeType,
                      0,
                    ) ??
                    runtime.lookupType(CoreTypes.dynamic),
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
        });
      case 'map':
        return $Function((runtime, target, r, s, c) {
          final result = super.map(
            runtime.cachedCallback(
              (r as $Value?)! as EvalCallable,
              "T Function(E);export=true",
              (_callable) => (dynamic e) {
                return TypedInterop.exportExternal(
                  _callable.call(
                    runtime,
                    null,
                    (e is List || e is Map || e is Set
                        ? TypedInterop.boxExternal(e, runtime: runtime)!
                        : runtime.wrapAlways(e)),
                    null,
                    1,
                  ),
                  runtime: runtime,
                ) as dynamic;
              },
            ),
          );
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
        });
      case 'where':
        return $Function((runtime, target, r, s, c) {
          final result = super.where(
            runtime.cachedCallback(
              (r as $Value?)! as EvalCallable,
              "bool Function(E);export=true",
              (_callable) => (dynamic element) {
                return _callable
                        .call(
                          runtime,
                          null,
                          (element is List || element is Map || element is Set
                              ? TypedInterop.boxExternal(
                                  element,
                                  runtime: runtime,
                                )!
                              : runtime.wrapAlways(element)),
                          null,
                          1,
                        )
                        ?.$value
                    as bool;
              },
            ),
          );
          return (() {
            final iterableType = runtime.internParameterizedType(
              CoreTypes.iterable,
              [
                runtime.runtimeTypeArgumentAt(
                      Runtime.bridgeData[this]!.$runtimeType,
                      0,
                    ) ??
                    runtime.lookupType(CoreTypes.dynamic),
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
        });
      case 'whereType':
        return $Function((runtime, target, r, s, c) {
          return hooks.iterableWhereType(runtime, this, r, s, c);
        });
      case 'expand':
        return $Function((runtime, target, r, s, c) {
          final result = super.expand(
            runtime.cachedCallback(
              (r as $Value?)! as EvalCallable,
              "Iterable<T> Function(E);export=true",
              (_callable) => (dynamic element) {
                return TypedInterop.exportIterable(
                  _callable.call(
                    runtime,
                    null,
                    (element is List || element is Map || element is Set
                        ? TypedInterop.boxExternal(element, runtime: runtime)!
                        : runtime.wrapAlways(element)),
                    null,
                    1,
                  ),
                  runtime,
                );
              },
            ),
          );
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
          super.forEach(
            runtime.cachedCallback(
              (r as $Value?)! as EvalCallable,
              "void Function(E);export=true",
              (_callable) => (dynamic element) {
                _callable.call(
                  runtime,
                  null,
                  (element is List || element is Map || element is Set
                      ? TypedInterop.boxExternal(element, runtime: runtime)!
                      : runtime.wrapAlways(element)),
                  null,
                  1,
                );
              },
            ),
          );
          return null;
        });
      case 'reduce':
        return $Function((runtime, target, r, s, c) {
          final result = super.reduce(
            runtime.cachedCallback(
              (r as $Value?)! as EvalCallable,
              "E Function(E, E);export=true",
              (_callable) => (dynamic value, dynamic element) {
                return TypedInterop.exportExternal(
                  _callable.call(
                    runtime,
                    null,
                    (value is List || value is Map || value is Set
                        ? TypedInterop.boxExternal(value, runtime: runtime)!
                        : runtime.wrapAlways(value)),
                    (element is List || element is Map || element is Set
                        ? TypedInterop.boxExternal(element, runtime: runtime)!
                        : runtime.wrapAlways(element)),
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
        });
      case 'fold':
        return $Function((runtime, target, r, s, c) {
          final result = super.fold(
            TypedInterop.exportExternal((r as $Value?), runtime: runtime)
                as dynamic,
            runtime.cachedCallback(
              (s as $Value?)! as EvalCallable,
              "T Function(T, E);export=true",
              (_callable) => (dynamic previousValue, dynamic element) {
                return TypedInterop.exportExternal(
                  _callable.call(
                    runtime,
                    null,
                    (previousValue is List ||
                            previousValue is Map ||
                            previousValue is Set
                        ? TypedInterop.boxExternal(
                            previousValue,
                            runtime: runtime,
                          )!
                        : runtime.wrapAlways(previousValue)),
                    (element is List || element is Map || element is Set
                        ? TypedInterop.boxExternal(element, runtime: runtime)!
                        : runtime.wrapAlways(element)),
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
        });
      case 'every':
        return $Function((runtime, target, r, s, c) {
          final result = super.every(
            runtime.cachedCallback(
              (r as $Value?)! as EvalCallable,
              "bool Function(E);export=true",
              (_callable) => (dynamic element) {
                return _callable
                        .call(
                          runtime,
                          null,
                          (element is List || element is Map || element is Set
                              ? TypedInterop.boxExternal(
                                  element,
                                  runtime: runtime,
                                )!
                              : runtime.wrapAlways(element)),
                          null,
                          1,
                        )
                        ?.$value
                    as bool;
              },
            ),
          );
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
          final result = super.any(
            runtime.cachedCallback(
              (r as $Value?)! as EvalCallable,
              "bool Function(E);export=true",
              (_callable) => (dynamic element) {
                return _callable
                        .call(
                          runtime,
                          null,
                          (element is List || element is Map || element is Set
                              ? TypedInterop.boxExternal(
                                  element,
                                  runtime: runtime,
                                )!
                              : runtime.wrapAlways(element)),
                          null,
                          1,
                        )
                        ?.$value
                    as bool;
              },
            ),
          );
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
            (e) => (e is List || e is Map || e is Set
                ? TypedInterop.boxExternal(e, runtime: runtime)!
                : runtime.wrapAlways(e)),
            runtime: runtime,
            runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
              runtime.runtimeTypeArgumentAt(
                    Runtime.bridgeData[this]!.$runtimeType,
                    0,
                  ) ??
                  runtime.lookupType(CoreTypes.dynamic),
            ]),
          );
        });
      case 'toSet':
        return $Function((runtime, target, r, s, c) {
          final result = super.toSet();
          return $Set.wrap(
            (result)
                .map(
                  (e) => (e is List || e is Map || e is Set
                      ? TypedInterop.boxExternal(e, runtime: runtime)!
                      : runtime.wrapAlways(e)),
                )
                .toSet(),
          );
        });
      case 'take':
        return $Function((runtime, target, r, s, c) {
          final result = super.take((r as $int).$value);
          return (() {
            final iterableType = runtime.internParameterizedType(
              CoreTypes.iterable,
              [
                runtime.runtimeTypeArgumentAt(
                      Runtime.bridgeData[this]!.$runtimeType,
                      0,
                    ) ??
                    runtime.lookupType(CoreTypes.dynamic),
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
        });
      case 'takeWhile':
        return $Function((runtime, target, r, s, c) {
          final result = super.takeWhile(
            runtime.cachedCallback(
              (r as $Value?)! as EvalCallable,
              "bool Function(E);export=true",
              (_callable) => (dynamic value) {
                return _callable
                        .call(
                          runtime,
                          null,
                          (value is List || value is Map || value is Set
                              ? TypedInterop.boxExternal(
                                  value,
                                  runtime: runtime,
                                )!
                              : runtime.wrapAlways(value)),
                          null,
                          1,
                        )
                        ?.$value
                    as bool;
              },
            ),
          );
          return (() {
            final iterableType = runtime.internParameterizedType(
              CoreTypes.iterable,
              [
                runtime.runtimeTypeArgumentAt(
                      Runtime.bridgeData[this]!.$runtimeType,
                      0,
                    ) ??
                    runtime.lookupType(CoreTypes.dynamic),
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
        });
      case 'skip':
        return $Function((runtime, target, r, s, c) {
          final result = super.skip((r as $int).$value);
          return (() {
            final iterableType = runtime.internParameterizedType(
              CoreTypes.iterable,
              [
                runtime.runtimeTypeArgumentAt(
                      Runtime.bridgeData[this]!.$runtimeType,
                      0,
                    ) ??
                    runtime.lookupType(CoreTypes.dynamic),
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
        });
      case 'skipWhile':
        return $Function((runtime, target, r, s, c) {
          final result = super.skipWhile(
            runtime.cachedCallback(
              (r as $Value?)! as EvalCallable,
              "bool Function(E);export=true",
              (_callable) => (dynamic value) {
                return _callable
                        .call(
                          runtime,
                          null,
                          (value is List || value is Map || value is Set
                              ? TypedInterop.boxExternal(
                                  value,
                                  runtime: runtime,
                                )!
                              : runtime.wrapAlways(value)),
                          null,
                          1,
                        )
                        ?.$value
                    as bool;
              },
            ),
          );
          return (() {
            final iterableType = runtime.internParameterizedType(
              CoreTypes.iterable,
              [
                runtime.runtimeTypeArgumentAt(
                      Runtime.bridgeData[this]!.$runtimeType,
                      0,
                    ) ??
                    runtime.lookupType(CoreTypes.dynamic),
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
        });
      case 'firstWhere':
        return $Function((runtime, target, r, s, c) {
          final result = super.firstWhere(
            runtime.cachedCallback(
              (r as $Value?)! as EvalCallable,
              "bool Function(E);export=true",
              (_callable) => (dynamic element) {
                return _callable
                        .call(
                          runtime,
                          null,
                          (element is List || element is Map || element is Set
                              ? TypedInterop.boxExternal(
                                  element,
                                  runtime: runtime,
                                )!
                              : runtime.wrapAlways(element)),
                          null,
                          1,
                        )
                        ?.$value
                    as bool;
              },
            ),
            orElse:
                (s is $Value ? s : null) == null ||
                    (s is $Value ? s : null) is $null
                ? null
                : runtime.cachedCallback(
                    (s is $Value ? s : null)! as EvalCallable,
                    "E Function();export=true",
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
        });
      case 'lastWhere':
        return $Function((runtime, target, r, s, c) {
          final result = super.lastWhere(
            runtime.cachedCallback(
              (r as $Value?)! as EvalCallable,
              "bool Function(E);export=true",
              (_callable) => (dynamic element) {
                return _callable
                        .call(
                          runtime,
                          null,
                          (element is List || element is Map || element is Set
                              ? TypedInterop.boxExternal(
                                  element,
                                  runtime: runtime,
                                )!
                              : runtime.wrapAlways(element)),
                          null,
                          1,
                        )
                        ?.$value
                    as bool;
              },
            ),
            orElse:
                (s is $Value ? s : null) == null ||
                    (s is $Value ? s : null) is $null
                ? null
                : runtime.cachedCallback(
                    (s is $Value ? s : null)! as EvalCallable,
                    "E Function();export=true",
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
        });
      case 'singleWhere':
        return $Function((runtime, target, r, s, c) {
          final result = super.singleWhere(
            runtime.cachedCallback(
              (r as $Value?)! as EvalCallable,
              "bool Function(E);export=true",
              (_callable) => (dynamic element) {
                return _callable
                        .call(
                          runtime,
                          null,
                          (element is List || element is Map || element is Set
                              ? TypedInterop.boxExternal(
                                  element,
                                  runtime: runtime,
                                )!
                              : runtime.wrapAlways(element)),
                          null,
                          1,
                        )
                        ?.$value
                    as bool;
              },
            ),
            orElse:
                (s is $Value ? s : null) == null ||
                    (s is $Value ? s : null) is $null
                ? null
                : runtime.cachedCallback(
                    (s is $Value ? s : null)! as EvalCallable,
                    "E Function();export=true",
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
        });
      case 'elementAt':
        return $Function((runtime, target, r, s, c) {
          final result = super.elementAt((r as $int).$value);
          return (result is List || result is Map || result is Set
              ? TypedInterop.boxExternal(result, runtime: runtime)!
              : runtime.wrapAlways(result));
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
    final result = $_invoke('cast', []);
    return TypedInterop.exportIterable<R>(result, runtime);
  }

  @override
  Iterable<E> followedBy(Iterable<E> other) {
    final runtime = $runtime;
    final result = $_invoke('followedBy', [
      $Iterable.wrap(
        (other).map((e) => runtime.wrapAlways(e, recursive: true)),
      ),
    ]);
    return TypedInterop.exportIterable<E>(result, runtime);
  }

  @override
  Iterable<T> map<T>(T Function(E) toElement) {
    final runtime = $runtime;
    final result = $_invoke('map', [
      $Function((runtime, target, r, s, c) {
        final funcResult = toElement(
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
        );
        return runtime.wrapAlways(funcResult, recursive: true);
      }),
    ]);
    return TypedInterop.exportIterable<T>(result, runtime);
  }

  @override
  Iterable<E> where(bool Function(E) test) {
    final runtime = $runtime;
    final result = $_invoke('where', [
      $Function((runtime, target, r, s, c) {
        final funcResult = test(
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
        );
        return $bool(funcResult);
      }),
    ]);
    return TypedInterop.exportIterable<E>(result, runtime);
  }

  @override
  Iterable<T> whereType<T>() {
    final runtime = $runtime;
    final result = $_invoke('whereType', []);
    return TypedInterop.exportIterable<T>(result, runtime);
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E) toElements) {
    final runtime = $runtime;
    final result = $_invoke('expand', [
      $Function((runtime, target, r, s, c) {
        final funcResult = toElements(
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
        );
        return $Iterable.wrap(
          (funcResult).map((e) => runtime.wrapAlways(e, recursive: true)),
        );
      }),
    ]);
    return TypedInterop.exportIterable<T>(result, runtime);
  }

  @override
  bool contains(Object? element) {
    final runtime = $runtime;
    return $_invoke('contains', [
      (element is List || element is Map || element is Set
          ? TypedInterop.boxExternal(element, runtime: runtime)!
          : runtime.wrapAlways(element)),
    ]);
  }

  @override
  void forEach(void Function(E) action) {
    final runtime = $runtime;
    $_invoke('forEach', [
      $Function((runtime, target, r, s, c) {
        action(
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
        );
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
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
          TypedInterop.exportExternal((s as $Value?), runtime: runtime)
              as dynamic,
        );
        return runtime.wrapAlways(funcResult, recursive: true);
      }),
    ]);
  }

  @override
  T fold<T>(T initialValue, T Function(T, E) combine) {
    final runtime = $runtime;
    return $_invoke('fold', [
      (initialValue is List || initialValue is Map || initialValue is Set
          ? TypedInterop.boxExternal(initialValue, runtime: runtime)!
          : runtime.wrapAlways(initialValue)),
      $Function((runtime, target, r, s, c) {
        final funcResult = combine(
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
          TypedInterop.exportExternal((s as $Value?), runtime: runtime)
              as dynamic,
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
        final funcResult = test(
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
        );
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
        final funcResult = test(
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
        );
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
    final result = $_invoke('take', [$int(count)]);
    return TypedInterop.exportIterable<E>(result, runtime);
  }

  @override
  Iterable<E> takeWhile(bool Function(E) test) {
    final runtime = $runtime;
    final result = $_invoke('takeWhile', [
      $Function((runtime, target, r, s, c) {
        final funcResult = test(
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
        );
        return $bool(funcResult);
      }),
    ]);
    return TypedInterop.exportIterable<E>(result, runtime);
  }

  @override
  Iterable<E> skip(int count) {
    final runtime = $runtime;
    final result = $_invoke('skip', [$int(count)]);
    return TypedInterop.exportIterable<E>(result, runtime);
  }

  @override
  Iterable<E> skipWhile(bool Function(E) test) {
    final runtime = $runtime;
    final result = $_invoke('skipWhile', [
      $Function((runtime, target, r, s, c) {
        final funcResult = test(
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
        );
        return $bool(funcResult);
      }),
    ]);
    return TypedInterop.exportIterable<E>(result, runtime);
  }

  @override
  E firstWhere(bool Function(E) test, {E Function()? orElse}) {
    final runtime = $runtime;
    return $_invoke('firstWhere', [
      $Function((runtime, target, r, s, c) {
        final funcResult = test(
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
        );
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
        final funcResult = test(
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
        );
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
        final funcResult = test(
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
        );
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
