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
import 'dart:math';

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

import '../core/iterator.dart';

import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/utils/wrap_helper.dart';

import '../math/random.dart';

/// dart_eval bridge binding for [ListBase]
class $ListBase$bridge<E> extends ListBase<E> with $Bridge<ListBase<E>> {
  /// Forwarded constructor for [ListBase.new]
  $ListBase$bridge();

  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'ListBase.',
      $ListBase$bridge.$new,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'ListBase.listToString',
      $ListBase$bridge.$listToString,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$ListBase$bridge]
  static const $spec = BridgeTypeSpec('dart:collection', 'ListBase');

  /// Compile-time type declaration of [$ListBase$bridge]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ListBase]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,
      isMixinClass: true,

      generics: {'E': BridgeGenericParam()},

      $implements: [
        BridgeTypeRef(CoreTypes.list, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
        ]),
        BridgeTypeRef(CoreTypes.iterable, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
        ]),
        BridgeTypeRef(CoreTypes.object, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
          generics: {'R': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
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
              'f',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
              'f',
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
                        'previousValue',
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

      '[]': BridgeMethodDef(
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

        isAbstract: true,
      ),

      '[]=': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'add': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'element',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
              'iterable',
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

      'sort': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'compare',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.int, []),
                    ),
                    params: [
                      BridgeParameter(
                        'a',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                        false,
                      ),

                      BridgeParameter(
                        'b',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
      ),

      'shuffle': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
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
        ),
      ),

      'indexOf': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "0",
            ),
          ],
        ),
      ),

      'indexWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "0",
            ),
          ],
        ),
      ),

      'lastIndexWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'lastIndexOf': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
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

      'insert': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'element',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
              false,
            ),
          ],
        ),
      ),

      'insertAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'iterable',
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

      'setAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'iterable',
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

      'remove': BridgeMethodDef(
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

      'removeAt': BridgeMethodDef(
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

      'removeLast': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
          namedParams: [],
          params: [],
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

      'retainWhere': BridgeMethodDef(
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

      '+': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'sublist': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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
        ),
      ),

      'getRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'setRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'iterable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                ]),
              ),
              false,
            ),

            BridgeParameter(
              'skipCount',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "0",
            ),
          ],
        ),
      ),

      'removeRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'fillRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'fill',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E'), nullable: true),
              true,
            ),
          ],
        ),
      ),

      'replaceRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'newContents',
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

      'asMap': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'listToString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'list',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
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
      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'reversed': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

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
    setters: {
      'first': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
              false,
            ),
          ],
        ),
      ),

      'last': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
              false,
            ),
          ],
        ),
      ),

      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'newLength',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),
    },
    fields: {},
    wrap: false,
    bridge: true,
  );

  /// Proxy for the [ListBase.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $ListBase$bridge();
  }

  /// Wrapper for the [ListBase.listToString] method
  static $Value? $listToString(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = ListBase.listToString(
      ((r as $Value?)!.$reified as List).cast<Object?>(),
    );
    return $String(value);
  }

  @override
  $Value? $bridgeGet(String identifier) {
    final runtime = $runtime;
    switch (identifier) {
      case 'iterator':
        final _iterator = super.iterator;
        return $Iterator.wrap(_iterator);

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

      case 'reversed':
        final _reversed = super.reversed;
        return $Iterable.wrap(
          (_reversed).map(
            (e) => (e is List || e is Map || e is Set
                ? TypedInterop.boxExternal(e, runtime: runtime)!
                : runtime.wrapAlways(e)),
          ),
        );
      case 'cast':
        return $Function((runtime, target, r, s, c) {
          final result = super.cast();
          return $List.view(
            result,
            (e) => (e is List || e is Map || e is Set
                ? TypedInterop.boxExternal(e, runtime: runtime)!
                : runtime.wrapAlways(e)),
          );
        });
      case 'followedBy':
        return $Function((runtime, target, r, s, c) {
          final result = super.followedBy(
            TypedInterop.exportIterable((r as $Value?), runtime),
          );
          return $Iterable.wrap(
            (result).map(
              (e) => (e is List || e is Map || e is Set
                  ? TypedInterop.boxExternal(e, runtime: runtime)!
                  : runtime.wrapAlways(e)),
            ),
          );
        });
      case 'map':
        return $Function((runtime, target, r, s, c) {
          final result = super.map(
            runtime.cachedCallback(
              (r as $Value?)! as EvalCallable,
              "T Function(E);export=true",
              (_callable) => (dynamic element) {
                return TypedInterop.exportExternal(
                  _callable.call(
                    runtime,
                    null,
                    (element is List || element is Map || element is Set
                        ? TypedInterop.boxExternal(element, runtime: runtime)!
                        : runtime.wrapAlways(element)),
                    null,
                    1,
                  ),
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
          return $Iterable.wrap(
            (result).map(
              (e) => (e is List || e is Map || e is Set
                  ? TypedInterop.boxExternal(e, runtime: runtime)!
                  : runtime.wrapAlways(e)),
            ),
          );
        });
      case 'whereType':
        return $Function((runtime, target, r, s, c) {
          final result = super.whereType();
          return $Iterable.wrap(
            (result).map(
              (e) => (e is List || e is Map || e is Set
                  ? TypedInterop.boxExternal(e, runtime: runtime)!
                  : runtime.wrapAlways(e)),
            ),
          );
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
          return $Iterable.wrap(
            (result).map(
              (e) => (e is List || e is Map || e is Set
                  ? TypedInterop.boxExternal(e, runtime: runtime)!
                  : runtime.wrapAlways(e)),
            ),
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
          return $Iterable.wrap(
            (result).map(
              (e) => (e is List || e is Map || e is Set
                  ? TypedInterop.boxExternal(e, runtime: runtime)!
                  : runtime.wrapAlways(e)),
            ),
          );
        });
      case 'takeWhile':
        return $Function((runtime, target, r, s, c) {
          final result = super.takeWhile(
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
          return $Iterable.wrap(
            (result).map(
              (e) => (e is List || e is Map || e is Set
                  ? TypedInterop.boxExternal(e, runtime: runtime)!
                  : runtime.wrapAlways(e)),
            ),
          );
        });
      case 'skip':
        return $Function((runtime, target, r, s, c) {
          final result = super.skip((r as $int).$value);
          return $Iterable.wrap(
            (result).map(
              (e) => (e is List || e is Map || e is Set
                  ? TypedInterop.boxExternal(e, runtime: runtime)!
                  : runtime.wrapAlways(e)),
            ),
          );
        });
      case 'skipWhile':
        return $Function((runtime, target, r, s, c) {
          final result = super.skipWhile(
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
          return $Iterable.wrap(
            (result).map(
              (e) => (e is List || e is Map || e is Set
                  ? TypedInterop.boxExternal(e, runtime: runtime)!
                  : runtime.wrapAlways(e)),
            ),
          );
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
      case 'add':
        return $Function((runtime, target, r, s, c) {
          super.add(
            TypedInterop.exportExternal((r as $Value?), runtime: runtime)
                as dynamic,
          );
          return null;
        });
      case 'addAll':
        return $Function((runtime, target, r, s, c) {
          super.addAll(TypedInterop.exportIterable((r as $Value?), runtime));
          return null;
        });
      case 'sort':
        return $Function((runtime, target, r, s, c) {
          super.sort(
            (r is $Value ? r : null) == null ||
                    (r is $Value ? r : null) is $null
                ? null
                : runtime.cachedCallback(
                    (r is $Value ? r : null)! as EvalCallable,
                    "int Function(E, E);export=true",
                    (_callable) => (dynamic a, dynamic b) {
                      return _callable
                              .call(
                                runtime,
                                null,
                                (a is List || a is Map || a is Set
                                    ? TypedInterop.boxExternal(
                                        a,
                                        runtime: runtime,
                                      )!
                                    : runtime.wrapAlways(a)),
                                (b is List || b is Map || b is Set
                                    ? TypedInterop.boxExternal(
                                        b,
                                        runtime: runtime,
                                      )!
                                    : runtime.wrapAlways(b)),
                                2,
                              )
                              ?.$value
                          as int;
                    },
                  ),
          );
          return null;
        });
      case 'shuffle':
        return $Function((runtime, target, r, s, c) {
          super.shuffle((r is $Value ? r : null)?.$value);
          return null;
        });
      case 'indexOf':
        return $Function((runtime, target, r, s, c) {
          final result = super.indexOf(
            TypedInterop.exportExternal((r as $Value?), runtime: runtime)
                as Object?,
            (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
          );
          return $int(result);
        });
      case 'indexWhere':
        return $Function((runtime, target, r, s, c) {
          final result = super.indexWhere(
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
            (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
          );
          return $int(result);
        });
      case 'lastIndexWhere':
        return $Function((runtime, target, r, s, c) {
          final result = super.lastIndexWhere(
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
            (s is $Value ? s : null)?.$value,
          );
          return $int(result);
        });
      case 'lastIndexOf':
        return $Function((runtime, target, r, s, c) {
          final result = super.lastIndexOf(
            TypedInterop.exportExternal((r as $Value?), runtime: runtime)
                as Object?,
            (s is $Value ? s : null)?.$value,
          );
          return $int(result);
        });
      case 'clear':
        return $Function((runtime, target, r, s, c) {
          super.clear();
          return null;
        });
      case 'insert':
        return $Function((runtime, target, r, s, c) {
          super.insert(
            (r as $int).$value,
            TypedInterop.exportExternal((s as $Value?), runtime: runtime)
                as dynamic,
          );
          return null;
        });
      case 'insertAll':
        return $Function((runtime, target, r, s, c) {
          super.insertAll(
            (r as $int).$value,
            TypedInterop.exportIterable((s as $Value?), runtime),
          );
          return null;
        });
      case 'setAll':
        return $Function((runtime, target, r, s, c) {
          super.setAll(
            (r as $int).$value,
            TypedInterop.exportIterable((s as $Value?), runtime),
          );
          return null;
        });
      case 'remove':
        return $Function((runtime, target, r, s, c) {
          final result = super.remove(
            TypedInterop.exportExternal((r as $Value?), runtime: runtime)
                as Object?,
          );
          return $bool(result);
        });
      case 'removeAt':
        return $Function((runtime, target, r, s, c) {
          final result = super.removeAt((r as $int).$value);
          return (result is List || result is Map || result is Set
              ? TypedInterop.boxExternal(result, runtime: runtime)!
              : runtime.wrapAlways(result));
        });
      case 'removeLast':
        return $Function((runtime, target, r, s, c) {
          final result = super.removeLast();
          return (result is List || result is Map || result is Set
              ? TypedInterop.boxExternal(result, runtime: runtime)!
              : runtime.wrapAlways(result));
        });
      case 'removeWhere':
        return $Function((runtime, target, r, s, c) {
          super.removeWhere(
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
          return null;
        });
      case 'retainWhere':
        return $Function((runtime, target, r, s, c) {
          super.retainWhere(
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
          return null;
        });
      case '+':
        return $Function((runtime, target, r, s, c) {
          final result = (super + ((r as $Value?)!.$reified as List).cast());
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
      case 'sublist':
        return $Function((runtime, target, r, s, c) {
          final result = super.sublist(
            (r as $int).$value,
            (s is $Value ? s : null)?.$value,
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
      case 'getRange':
        return $Function((runtime, target, r, s, c) {
          final result = super.getRange((r as $int).$value, (s as $int).$value);
          return $Iterable.wrap(
            (result).map(
              (e) => (e is List || e is Map || e is Set
                  ? TypedInterop.boxExternal(e, runtime: runtime)!
                  : runtime.wrapAlways(e)),
            ),
          );
        });
      case 'setRange':
        return $Function((runtime, target, r, s, c) {
          super.setRange(
            (r as $int).$value,
            (s as $int).$value,
            TypedInterop.exportIterable(
              ((c as List<Object?>)[0] as $Value?),
              runtime,
            ),
            (c is List && (c as List).length > 1
                        ? (c as List)[1] as $Value?
                        : null) ==
                    null
                ? 0
                : ((c is List && (c as List).length > 1 ? (c as List)[1] : null)
                          as $int)
                      .$value,
          );
          return null;
        });
      case 'removeRange':
        return $Function((runtime, target, r, s, c) {
          super.removeRange((r as $int).$value, (s as $int).$value);
          return null;
        });
      case 'fillRange':
        return $Function((runtime, target, r, s, c) {
          super.fillRange(
            (r as $int).$value,
            (s as $int).$value,
            TypedInterop.exportExternal(
              (c is List && (c as List).length > 0
                  ? (c as List)[0] as $Value?
                  : null),
              runtime: runtime,
            ) as dynamic,
          );
          return null;
        });
      case 'replaceRange':
        return $Function((runtime, target, r, s, c) {
          super.replaceRange(
            (r as $int).$value,
            (s as $int).$value,
            TypedInterop.exportIterable(
              ((c as List<Object?>)[0] as $Value?),
              runtime,
            ),
          );
          return null;
        });
      case 'asMap':
        return $Function((runtime, target, r, s, c) {
          final result = super.asMap();
          return wrapMap(
            result,
            (key, value) => MapEntry(
              $int(key),
              (value is List || value is Map || value is Set
                  ? TypedInterop.boxExternal(value, runtime: runtime)!
                  : runtime.wrapAlways(value)),
            ),
          );
        });
    }
    return null;
  }

  @override
  void $bridgeSet(String identifier, $Value value) {
    switch (identifier) {
      case 'first':
        super.first = value.$reified;
        return;

      case 'last':
        super.last = value.$reified;
        return;
    }
  }

  @override
  int get length => $_get('length');

  @override
  Iterator<E> get iterator => TypedInterop.exportIterator<E>(
    $getProperty($runtime, 'iterator'),
    $runtime,
  );

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
  Iterable<E> get reversed => TypedInterop.exportIterable<E>(
    $getProperty($runtime, 'reversed'),
    $runtime,
  );
  @override
  set length(int value) {
    final runtime = $runtime;
    $_set('length', $int(value));
  }

  @override
  set first(E value) {
    final runtime = $runtime;
    $_set('first', runtime.wrapAlways(value, recursive: true));
  }

  @override
  set last(E value) {
    final runtime = $runtime;
    $_set('last', runtime.wrapAlways(value, recursive: true));
  }

  @override
  List<R> cast<R>() {
    final runtime = $runtime;
    return ($_invoke('cast', []) as List).cast();
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
  Iterable<T> map<T>(T Function(E) f) {
    final runtime = $runtime;
    final result = $_invoke('map', [
      $Function((runtime, target, r, s, c) {
        final funcResult = f(
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
  Iterable<T> expand<T>(Iterable<T> Function(E) f) {
    final runtime = $runtime;
    final result = $_invoke('expand', [
      $Function((runtime, target, r, s, c) {
        final funcResult = f(
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

  @override
  E operator [](int index) {
    final runtime = $runtime;
    return $_invoke('[]', [$int(index)]);
  }

  @override
  void operator []=(int index, E value) {
    final runtime = $runtime;
    $_invoke('[]=', [
      $int(index),
      (value is List || value is Map || value is Set
          ? TypedInterop.boxExternal(value, runtime: runtime)!
          : runtime.wrapAlways(value)),
    ]);
  }

  @override
  void add(E element) {
    final runtime = $runtime;
    $_invoke('add', [
      (element is List || element is Map || element is Set
          ? TypedInterop.boxExternal(element, runtime: runtime)!
          : runtime.wrapAlways(element)),
    ]);
  }

  @override
  void addAll(Iterable<E> iterable) {
    final runtime = $runtime;
    $_invoke('addAll', [
      $Iterable.wrap(
        (iterable).map((e) => runtime.wrapAlways(e, recursive: true)),
      ),
    ]);
  }

  @override
  void sort([int Function(E, E)? compare]) {
    final runtime = $runtime;
    $_invoke('sort', [
      compare == null
          ? const $null()
          : $Function((runtime, target, r, s, c) {
              final funcResult = compare(
                TypedInterop.exportExternal((r as $Value?), runtime: runtime)
                    as dynamic,
                TypedInterop.exportExternal((s as $Value?), runtime: runtime)
                    as dynamic,
              );
              return $int(funcResult);
            }),
    ]);
  }

  @override
  void shuffle([Random? random]) {
    final runtime = $runtime;
    $_invoke('shuffle', [
      random == null ? const $null() : $Random.wrap(random),
    ]);
  }

  @override
  int indexOf(Object? element, [int start = 0]) {
    final runtime = $runtime;
    return $_invoke('indexOf', [
      (element is List || element is Map || element is Set
          ? TypedInterop.boxExternal(element, runtime: runtime)!
          : runtime.wrapAlways(element)),
      $int(start),
    ]);
  }

  @override
  int indexWhere(bool Function(E) test, [int start = 0]) {
    final runtime = $runtime;
    return $_invoke('indexWhere', [
      $Function((runtime, target, r, s, c) {
        final funcResult = test(
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
        );
        return $bool(funcResult);
      }),
      $int(start),
    ]);
  }

  @override
  int lastIndexWhere(bool Function(E) test, [int? start]) {
    final runtime = $runtime;
    return $_invoke('lastIndexWhere', [
      $Function((runtime, target, r, s, c) {
        final funcResult = test(
          TypedInterop.exportExternal((r as $Value?), runtime: runtime)
              as dynamic,
        );
        return $bool(funcResult);
      }),
      start == null ? const $null() : $int(start),
    ]);
  }

  @override
  int lastIndexOf(Object? element, [int? start]) {
    final runtime = $runtime;
    return $_invoke('lastIndexOf', [
      (element is List || element is Map || element is Set
          ? TypedInterop.boxExternal(element, runtime: runtime)!
          : runtime.wrapAlways(element)),
      start == null ? const $null() : $int(start),
    ]);
  }

  @override
  void clear() {
    final runtime = $runtime;
    $_invoke('clear', []);
  }

  @override
  void insert(int index, E element) {
    final runtime = $runtime;
    $_invoke('insert', [
      $int(index),
      (element is List || element is Map || element is Set
          ? TypedInterop.boxExternal(element, runtime: runtime)!
          : runtime.wrapAlways(element)),
    ]);
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    final runtime = $runtime;
    $_invoke('insertAll', [
      $int(index),
      $Iterable.wrap(
        (iterable).map((e) => runtime.wrapAlways(e, recursive: true)),
      ),
    ]);
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    final runtime = $runtime;
    $_invoke('setAll', [
      $int(index),
      $Iterable.wrap(
        (iterable).map((e) => runtime.wrapAlways(e, recursive: true)),
      ),
    ]);
  }

  @override
  bool remove(Object? element) {
    final runtime = $runtime;
    return $_invoke('remove', [
      (element is List || element is Map || element is Set
          ? TypedInterop.boxExternal(element, runtime: runtime)!
          : runtime.wrapAlways(element)),
    ]);
  }

  @override
  E removeAt(int index) {
    final runtime = $runtime;
    return $_invoke('removeAt', [$int(index)]);
  }

  @override
  E removeLast() {
    final runtime = $runtime;
    return $_invoke('removeLast', []);
  }

  @override
  void removeWhere(bool Function(E) test) {
    final runtime = $runtime;
    $_invoke('removeWhere', [
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
  void retainWhere(bool Function(E) test) {
    final runtime = $runtime;
    $_invoke('retainWhere', [
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
  List<E> operator +(List<E> other) {
    final runtime = $runtime;
    return ($_invoke('+', [
      TypedInterop.boxExternal(
        other,
        runtime: runtime,
        runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
          runtime.runtimeTypeArgumentAt(
                Runtime.bridgeData[this]!.$runtimeType,
                0,
              ) ??
              runtime.lookupType(CoreTypes.dynamic),
        ]),
      )!,
    ]) as List).cast();
  }

  @override
  List<E> sublist(int start, [int? end]) {
    final runtime = $runtime;
    return ($_invoke('sublist', [
      $int(start),
      end == null ? const $null() : $int(end),
    ]) as List).cast();
  }

  @override
  Iterable<E> getRange(int start, int end) {
    final runtime = $runtime;
    final result = $_invoke('getRange', [$int(start), $int(end)]);
    return TypedInterop.exportIterable<E>(result, runtime);
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    final runtime = $runtime;
    $_invoke('setRange', [
      $int(start),
      $int(end),
      $Iterable.wrap(
        (iterable).map((e) => runtime.wrapAlways(e, recursive: true)),
      ),
      $int(skipCount),
    ]);
  }

  @override
  void removeRange(int start, int end) {
    final runtime = $runtime;
    $_invoke('removeRange', [$int(start), $int(end)]);
  }

  @override
  void fillRange(int start, int end, [E? fill]) {
    final runtime = $runtime;
    $_invoke('fillRange', [
      $int(start),
      $int(end),
      (fill is List || fill is Map || fill is Set
          ? TypedInterop.boxExternal(fill, runtime: runtime)!
          : runtime.wrapAlways(fill)),
    ]);
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    final runtime = $runtime;
    $_invoke('replaceRange', [
      $int(start),
      $int(end),
      $Iterable.wrap(
        (newContents).map((e) => runtime.wrapAlways(e, recursive: true)),
      ),
    ]);
  }

  @override
  Map<int, E> asMap() {
    final runtime = $runtime;
    return ($_invoke('asMap', []) as Map).cast();
  }
}

/// dart_eval lightweight wrapper binding for [ListBase]
class $ListBase<E> implements $Instance {
  /// Compile-time type specification of [$ListBase]
  static const $spec = BridgeTypeSpec('dart:collection', 'ListBase');

  /// Compile-time type declaration of [$ListBase]
  static const $type = BridgeTypeRef($spec);

  final $Instance _superclass;

  @override
  final ListBase<E> $value;

  @override
  ListBase<E> get $reified => $value;

  /// Wrap a [ListBase] in a [$ListBase]
  $ListBase.wrap(this.$value) : _superclass = $Object($value);

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
      case 'length':
        final _length = $value.length;
        return $int(_length);
      case 'iterator':
        final _iterator = $value.iterator;
        return $Iterator.wrap(_iterator);
      case 'isEmpty':
        final _isEmpty = $value.isEmpty;
        return $bool(_isEmpty);
      case 'isNotEmpty':
        final _isNotEmpty = $value.isNotEmpty;
        return $bool(_isNotEmpty);
      case 'first':
        final _first = $value.first;
        return (_first is List || _first is Map || _first is Set
            ? TypedInterop.boxExternal(_first, runtime: runtime)!
            : runtime.wrapAlways(_first));
      case 'last':
        final _last = $value.last;
        return (_last is List || _last is Map || _last is Set
            ? TypedInterop.boxExternal(_last, runtime: runtime)!
            : runtime.wrapAlways(_last));
      case 'single':
        final _single = $value.single;
        return (_single is List || _single is Map || _single is Set
            ? TypedInterop.boxExternal(_single, runtime: runtime)!
            : runtime.wrapAlways(_single));
      case 'reversed':
        final _reversed = $value.reversed;
        return $Iterable.wrap(
          (_reversed).map(
            (e) => (e is List || e is Map || e is Set
                ? TypedInterop.boxExternal(e, runtime: runtime)!
                : runtime.wrapAlways(e)),
          ),
        );
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

      case '[]':
        return $Closure(__operatorIndexGet.func, this);

      case '[]=':
        return $Closure(__operatorIndexSet.func, this);

      case 'add':
        return $Closure(__add.func, this);

      case 'addAll':
        return $Closure(__addAll.func, this);

      case 'sort':
        return $Closure(__sort.func, this);

      case 'shuffle':
        return $Closure(__shuffle.func, this);

      case 'indexOf':
        return $Closure(__indexOf.func, this);

      case 'indexWhere':
        return $Closure(__indexWhere.func, this);

      case 'lastIndexWhere':
        return $Closure(__lastIndexWhere.func, this);

      case 'lastIndexOf':
        return $Closure(__lastIndexOf.func, this);

      case 'clear':
        return $Closure(__clear.func, this);

      case 'insert':
        return $Closure(__insert.func, this);

      case 'insertAll':
        return $Closure(__insertAll.func, this);

      case 'setAll':
        return $Closure(__setAll.func, this);

      case 'remove':
        return $Closure(__remove.func, this);

      case 'removeAt':
        return $Closure(__removeAt.func, this);

      case 'removeLast':
        return $Closure(__removeLast.func, this);

      case 'removeWhere':
        return $Closure(__removeWhere.func, this);

      case 'retainWhere':
        return $Closure(__retainWhere.func, this);

      case '+':
        return $Closure(__operatorPlus.func, this);

      case 'sublist':
        return $Closure(__sublist.func, this);

      case 'getRange':
        return $Closure(__getRange.func, this);

      case 'setRange':
        return $Closure(__setRange.func, this);

      case 'removeRange':
        return $Closure(__removeRange.func, this);

      case 'fillRange':
        return $Closure(__fillRange.func, this);

      case 'replaceRange':
        return $Closure(__replaceRange.func, this);

      case 'asMap':
        return $Closure(__asMap.func, this);
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
    final self = target! as $ListBase;
    final result = self.$value.cast();
    return $List.view(
      result,
      (e) => (e is List || e is Map || e is Set
          ? TypedInterop.boxExternal(e, runtime: runtime)!
          : runtime.wrapAlways(e)),
    );
  }

  static const $Function __followedBy = $Function(_followedBy);
  static $Value? _followedBy(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.followedBy(
      TypedInterop.exportIterable((r as $Value?), runtime),
    );
    return $Iterable.wrap(
      (result).map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
    );
  }

  static const $Function __map = $Function(_map);
  static $Value? _map(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.map(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "T Function(E);export=false",
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
    final self = target! as $ListBase;
    final result = self.$value.where(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
    );
    return $Iterable.wrap(
      (result).map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
    );
  }

  static const $Function __whereType = $Function(_whereType);
  static $Value? _whereType(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.whereType();
    return $Iterable.wrap(
      (result).map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
    );
  }

  static const $Function __expand = $Function(_expand);
  static $Value? _expand(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.expand(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "Iterable<T> Function(E);export=false",
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
    final self = target! as $ListBase;
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
    final self = target! as $ListBase;
    self.$value.forEach(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "void Function(E);export=false",
        (_callable) => (dynamic element) {
          _callable.call(
            runtime,
            null,
            runtime.wrapAlways(element, recursive: true),
            null,
            1,
          );
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
    final self = target! as $ListBase;
    final result = self.$value.reduce(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "E Function(E, E);export=false",
        (_callable) => (dynamic previousValue, dynamic element) {
          return _callable
              .call(
                runtime,
                null,
                runtime.wrapAlways(previousValue, recursive: true),
                runtime.wrapAlways(element, recursive: true),
                2,
              )
              ?.$value;
        },
      ),
    );
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __fold = $Function(_fold);
  static $Value? _fold(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.fold(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as dynamic,
      runtime.cachedCallback(
        (s as $Value?)! as EvalCallable,
        "T Function(T, E);export=false",
        (_callable) => (dynamic previousValue, dynamic element) {
          return _callable
              .call(
                runtime,
                null,
                runtime.wrapAlways(previousValue, recursive: true),
                runtime.wrapAlways(element, recursive: true),
                2,
              )
              ?.$value;
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
    final self = target! as $ListBase;
    final result = self.$value.every(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
    final self = target! as $ListBase;
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
    final self = target! as $ListBase;
    final result = self.$value.any(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
    final self = target! as $ListBase;
    final result = self.$value.toList(
      growable: (r is $Value ? r : null) == null ? true : (r as $bool).$value,
    );
    return $List.view(
      result,
      (e) => (e is List || e is Map || e is Set
          ? TypedInterop.boxExternal(e, runtime: runtime)!
          : runtime.wrapAlways(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 0) ??
            runtime.lookupType(CoreTypes.dynamic),
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
    final self = target! as $ListBase;
    final result = self.$value.toSet();
    return $Set.wrap(
      (result)
          .map(
            (e) => (e is List || e is Map || e is Set
                ? TypedInterop.boxExternal(e, runtime: runtime)!
                : runtime.wrapAlways(e)),
          )
          .toSet(),
    );
  }

  static const $Function __take = $Function(_take);
  static $Value? _take(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.take((r as $int).$value);
    return $Iterable.wrap(
      (result).map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
    );
  }

  static const $Function __takeWhile = $Function(_takeWhile);
  static $Value? _takeWhile(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.takeWhile(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
    );
    return $Iterable.wrap(
      (result).map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
    );
  }

  static const $Function __skip = $Function(_skip);
  static $Value? _skip(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.skip((r as $int).$value);
    return $Iterable.wrap(
      (result).map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
    );
  }

  static const $Function __skipWhile = $Function(_skipWhile);
  static $Value? _skipWhile(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.skipWhile(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
    );
    return $Iterable.wrap(
      (result).map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
    );
  }

  static const $Function __firstWhere = $Function(_firstWhere);
  static $Value? _firstWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.firstWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : runtime.cachedCallback(
              (s is $Value ? s : null)! as EvalCallable,
              "E Function();export=false",
              (_callable) => () {
                return _callable.call(runtime, null, null, null, 0)?.$value;
              },
            ),
    );
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __lastWhere = $Function(_lastWhere);
  static $Value? _lastWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.lastWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : runtime.cachedCallback(
              (s is $Value ? s : null)! as EvalCallable,
              "E Function();export=false",
              (_callable) => () {
                return _callable.call(runtime, null, null, null, 0)?.$value;
              },
            ),
    );
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __singleWhere = $Function(_singleWhere);
  static $Value? _singleWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.singleWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : runtime.cachedCallback(
              (s is $Value ? s : null)! as EvalCallable,
              "E Function();export=false",
              (_callable) => () {
                return _callable.call(runtime, null, null, null, 0)?.$value;
              },
            ),
    );
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __elementAt = $Function(_elementAt);
  static $Value? _elementAt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.elementAt((r as $int).$value);
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __operatorIndexGet = $Function(_operatorIndexGet);
  static $Value? _operatorIndexGet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value[(r as $int).$value];
    return (result is List || result is Map || result is Set
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
    final self = target! as $ListBase;
    self.$value[(r as $int).$value] = TypedInterop.exportExternal(
      (s as $Value?),
      runtime: runtime,
    ) as dynamic;
    return null;
  }

  static const $Function __add = $Function(_add);
  static $Value? _add(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    self.$value.add(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as dynamic,
    );
    return null;
  }

  static const $Function __addAll = $Function(_addAll);
  static $Value? _addAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    self.$value.addAll(TypedInterop.exportIterable((r as $Value?), runtime));
    return null;
  }

  static const $Function __sort = $Function(_sort);
  static $Value? _sort(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    self.$value.sort(
      (r is $Value ? r : null) == null || (r is $Value ? r : null) is $null
          ? null
          : runtime.cachedCallback(
              (r is $Value ? r : null)! as EvalCallable,
              "int Function(E, E);export=false",
              (_callable) => (dynamic a, dynamic b) {
                return _callable
                    .call(
                      runtime,
                      null,
                      runtime.wrapAlways(a, recursive: true),
                      runtime.wrapAlways(b, recursive: true),
                      2,
                    )
                    ?.$value;
              },
            ),
    );
    return null;
  }

  static const $Function __shuffle = $Function(_shuffle);
  static $Value? _shuffle(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    self.$value.shuffle((r is $Value ? r : null)?.$value);
    return null;
  }

  static const $Function __indexOf = $Function(_indexOf);
  static $Value? _indexOf(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.indexOf(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
      (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
    );
    return $int(result);
  }

  static const $Function __indexWhere = $Function(_indexWhere);
  static $Value? _indexWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.indexWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
      (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
    );
    return $int(result);
  }

  static const $Function __lastIndexWhere = $Function(_lastIndexWhere);
  static $Value? _lastIndexWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.lastIndexWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
      (s is $Value ? s : null)?.$value,
    );
    return $int(result);
  }

  static const $Function __lastIndexOf = $Function(_lastIndexOf);
  static $Value? _lastIndexOf(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.lastIndexOf(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
      (s is $Value ? s : null)?.$value,
    );
    return $int(result);
  }

  static const $Function __clear = $Function(_clear);
  static $Value? _clear(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    self.$value.clear();
    return null;
  }

  static const $Function __insert = $Function(_insert);
  static $Value? _insert(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    self.$value.insert(
      (r as $int).$value,
      TypedInterop.exportExternal((s as $Value?), runtime: runtime) as dynamic,
    );
    return null;
  }

  static const $Function __insertAll = $Function(_insertAll);
  static $Value? _insertAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    self.$value.insertAll(
      (r as $int).$value,
      TypedInterop.exportIterable((s as $Value?), runtime),
    );
    return null;
  }

  static const $Function __setAll = $Function(_setAll);
  static $Value? _setAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    self.$value.setAll(
      (r as $int).$value,
      TypedInterop.exportIterable((s as $Value?), runtime),
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
    final self = target! as $ListBase;
    final result = self.$value.remove(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
    );
    return $bool(result);
  }

  static const $Function __removeAt = $Function(_removeAt);
  static $Value? _removeAt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.removeAt((r as $int).$value);
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __removeLast = $Function(_removeLast);
  static $Value? _removeLast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.removeLast();
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __removeWhere = $Function(_removeWhere);
  static $Value? _removeWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    self.$value.removeWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
    );
    return null;
  }

  static const $Function __retainWhere = $Function(_retainWhere);
  static $Value? _retainWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    self.$value.retainWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
    );
    return null;
  }

  static const $Function __operatorPlus = $Function(_operatorPlus);
  static $Value? _operatorPlus(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result =
        (self.$value + ((r as $Value?)!.$reified as List).cast<dynamic>());
    return $List.view(
      result,
      (e) => (e is List || e is Map || e is Set
          ? TypedInterop.boxExternal(e, runtime: runtime)!
          : runtime.wrapAlways(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 0) ??
            runtime.lookupType(CoreTypes.dynamic),
      ]),
    );
  }

  static const $Function __sublist = $Function(_sublist);
  static $Value? _sublist(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.sublist(
      (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $List.view(
      result,
      (e) => (e is List || e is Map || e is Set
          ? TypedInterop.boxExternal(e, runtime: runtime)!
          : runtime.wrapAlways(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 0) ??
            runtime.lookupType(CoreTypes.dynamic),
      ]),
    );
  }

  static const $Function __getRange = $Function(_getRange);
  static $Value? _getRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.getRange((r as $int).$value, (s as $int).$value);
    return $Iterable.wrap(
      (result).map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
    );
  }

  static const $Function __setRange = $Function(_setRange);
  static $Value? _setRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    self.$value.setRange(
      (r as $int).$value,
      (s as $int).$value,
      TypedInterop.exportIterable(
        ((c as List<Object?>)[0] as $Value?),
        runtime,
      ),
      (c is List && (c as List).length > 1
                  ? (c as List)[1] as $Value?
                  : null) ==
              null
          ? 0
          : ((c is List && (c as List).length > 1 ? (c as List)[1] : null)
                    as $int)
                .$value,
    );
    return null;
  }

  static const $Function __removeRange = $Function(_removeRange);
  static $Value? _removeRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    self.$value.removeRange((r as $int).$value, (s as $int).$value);
    return null;
  }

  static const $Function __fillRange = $Function(_fillRange);
  static $Value? _fillRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    self.$value.fillRange(
      (r as $int).$value,
      (s as $int).$value,
      TypedInterop.exportExternal(
        (c is List && (c as List).length > 0
            ? (c as List)[0] as $Value?
            : null),
        runtime: runtime,
      ) as dynamic,
    );
    return null;
  }

  static const $Function __replaceRange = $Function(_replaceRange);
  static $Value? _replaceRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    self.$value.replaceRange(
      (r as $int).$value,
      (s as $int).$value,
      TypedInterop.exportIterable(
        ((c as List<Object?>)[0] as $Value?),
        runtime,
      ),
    );
    return null;
  }

  static const $Function __asMap = $Function(_asMap);
  static $Value? _asMap(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListBase;
    final result = self.$value.asMap();
    return wrapMap(
      result,
      (key, value) => MapEntry(
        $int(key),
        (value is List || value is Map || value is Set
            ? TypedInterop.boxExternal(value, runtime: runtime)!
            : runtime.wrapAlways(value)),
      ),
    );
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      case 'first':
        $value.first = value.$reified;
        return;
      case 'last':
        $value.last = value.$reified;
        return;
      case 'length':
        $value.length = value.$reified;
        return;
    }
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
