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
        $SplayTreeSet,
        $HashSet,
        $LinkedHashSet,
        $DoubleLinkedQueue,
        $DoubleLinkedQueueEntry,
        $ListBase,
        $MapBase,
        $SetBase;
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../core/iterator.dart';

import 'package:dart_eval/src/eval/utils/wrap_helper.dart';

/// dart_eval wrapper binding for [UnmodifiableListView]
class $UnmodifiableListView<E> implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'UnmodifiableListView.',
      $UnmodifiableListView.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$UnmodifiableListView]
  static const $spec = BridgeTypeSpec(
    'dart:collection',
    'UnmodifiableListView',
  );

  /// Compile-time type declaration of [$UnmodifiableListView]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$UnmodifiableListView]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      generics: {'E': BridgeGenericParam()},

      $implements: [
        BridgeTypeRef(CollectionTypes.listBase, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
        ]),
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
          params: [
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                ]),
              ),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {
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

      'clear': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
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

        isAbstract: true,
      ),

      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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
              'element',
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
              'element',
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
      ),
    },
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [UnmodifiableListView.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $UnmodifiableListView.wrap(
      UnmodifiableListView(
        TypedInterop.exportIterable((r as $Value?), runtime),
      ),
    );
  }

  final $Instance _superclass;

  @override
  final UnmodifiableListView<E> $value;

  @override
  UnmodifiableListView<E> get $reified => $value;

  /// Wrap a [UnmodifiableListView] in a [$UnmodifiableListView]
  $UnmodifiableListView.wrap(this.$value) : _superclass = $Object($value);

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
        return (() {
          final iterableType = runtime.internParameterizedType(
            CoreTypes.iterable,
            [
              runtime.runtimeTypeArgumentAt($getRuntimeType(runtime), 0) ??
                  runtime.lookupType(CoreTypes.dynamic),
            ],
          );
          return $Iterable.wrap(
            (_reversed).map((e) {
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
      case '[]=':
        return $Closure(__operatorIndexSet.func, this);

      case 'setAll':
        return $Closure(__setAll.func, this);

      case 'add':
        return $Closure(__add.func, this);

      case 'insert':
        return $Closure(__insert.func, this);

      case 'insertAll':
        return $Closure(__insertAll.func, this);

      case 'addAll':
        return $Closure(__addAll.func, this);

      case 'remove':
        return $Closure(__remove.func, this);

      case 'removeWhere':
        return $Closure(__removeWhere.func, this);

      case 'retainWhere':
        return $Closure(__retainWhere.func, this);

      case 'sort':
        return $Closure(__sort.func, this);

      case 'shuffle':
        return $Closure(__shuffle.func, this);

      case 'clear':
        return $Closure(__clear.func, this);

      case 'removeAt':
        return $Closure(__removeAt.func, this);

      case 'removeLast':
        return $Closure(__removeLast.func, this);

      case 'setRange':
        return $Closure(__setRange.func, this);

      case 'removeRange':
        return $Closure(__removeRange.func, this);

      case 'replaceRange':
        return $Closure(__replaceRange.func, this);

      case 'fillRange':
        return $Closure(__fillRange.func, this);

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

      case 'indexOf':
        return $Closure(__indexOf.func, this);

      case 'indexWhere':
        return $Closure(__indexWhere.func, this);

      case 'lastIndexWhere':
        return $Closure(__lastIndexWhere.func, this);

      case 'lastIndexOf':
        return $Closure(__lastIndexOf.func, this);

      case '+':
        return $Closure(__operatorPlus.func, this);

      case 'sublist':
        return $Closure(__sublist.func, this);

      case 'getRange':
        return $Closure(__getRange.func, this);

      case 'asMap':
        return $Closure(__asMap.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __operatorIndexSet = $Function(_operatorIndexSet);
  static $Value? _operatorIndexSet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
    self.$value[(r as $int).$value] = TypedInterop.exportExternal(
      (s as $Value?),
      runtime: runtime,
    ) as dynamic;
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
    final self = target! as $UnmodifiableListView;
    self.$value.setAll(
      (r as $int).$value,
      TypedInterop.exportIterable((s as $Value?), runtime),
    );
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
    final self = target! as $UnmodifiableListView;
    self.$value.add(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as dynamic,
    );
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
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
    self.$value.insertAll(
      (r as $int).$value,
      TypedInterop.exportIterable((s as $Value?), runtime),
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
    final self = target! as $UnmodifiableListView;
    self.$value.addAll(TypedInterop.exportIterable((r as $Value?), runtime));
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
    final self = target! as $UnmodifiableListView;
    final result = self.$value.remove(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
    );
    return $bool(result);
  }

  static const $Function __removeWhere = $Function(_removeWhere);
  static $Value? _removeWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
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

  static const $Function __sort = $Function(_sort);
  static $Value? _sort(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
    self.$value.shuffle((r is $Value ? r : null)?.$value);
    return null;
  }

  static const $Function __clear = $Function(_clear);
  static $Value? _clear(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
    self.$value.clear();
    return null;
  }

  static const $Function __removeAt = $Function(_removeAt);
  static $Value? _removeAt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
    final result = self.$value.removeLast();
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __setRange = $Function(_setRange);
  static $Value? _setRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
    self.$value.removeRange((r as $int).$value, (s as $int).$value);
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
    final self = target! as $UnmodifiableListView;
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

  static const $Function __fillRange = $Function(_fillRange);
  static $Value? _fillRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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

  static const $Function __cast = $Function(_cast);
  static $Value? _cast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
    final result = self.$value.cast();
    return (() {
      final bridgeTypeArguments = runtime.bridgeCallTypeArguments;
      return $List.view(
        result,
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
        runtime: runtime,
        runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
          (bridgeTypeArguments.length > 0
              ? bridgeTypeArguments[0]
              : runtime.lookupType(CoreTypes.dynamic)),
        ]),
      );
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
    final self = target! as $UnmodifiableListView;
    final result = self.$value.followedBy(
      TypedInterop.exportIterable((r as $Value?), runtime),
    );
    return (() {
      final iterableType = runtime.internParameterizedType(CoreTypes.iterable, [
        runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 0) ??
            runtime.lookupType(CoreTypes.dynamic),
      ]);
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
  }

  static const $Function __map = $Function(_map);
  static $Value? _map(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
    final result = self.$value.map(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "T Function(E);export=false",
        (_callable) => (dynamic element) {
          return TypedInterop.exportExternal(
            _callable.call(
              runtime,
              null,
              runtime.wrapAlways(element, recursive: true),
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
  }

  static const $Function __where = $Function(_where);
  static $Value? _where(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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
    return (() {
      final iterableType = runtime.internParameterizedType(CoreTypes.iterable, [
        runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 0) ??
            runtime.lookupType(CoreTypes.dynamic),
      ]);
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
  }

  static const $Function __whereType = $Function(_whereType);
  static $Value? _whereType(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
    final result = self.$value.reduce(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "E Function(E, E);export=false",
        (_callable) => (dynamic previousValue, dynamic element) {
          return TypedInterop.exportExternal(
            _callable.call(
              runtime,
              null,
              runtime.wrapAlways(previousValue, recursive: true),
              runtime.wrapAlways(element, recursive: true),
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

  static const $Function __fold = $Function(_fold);
  static $Value? _fold(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
    final result = self.$value.fold(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as dynamic,
      runtime.cachedCallback(
        (s as $Value?)! as EvalCallable,
        "T Function(T, E);export=false",
        (_callable) => (dynamic previousValue, dynamic element) {
          return TypedInterop.exportExternal(
            _callable.call(
              runtime,
              null,
              runtime.wrapAlways(previousValue, recursive: true),
              runtime.wrapAlways(element, recursive: true),
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
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
    final result = self.$value.take((r as $int).$value);
    return (() {
      final iterableType = runtime.internParameterizedType(CoreTypes.iterable, [
        runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 0) ??
            runtime.lookupType(CoreTypes.dynamic),
      ]);
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
  }

  static const $Function __takeWhile = $Function(_takeWhile);
  static $Value? _takeWhile(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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
    return (() {
      final iterableType = runtime.internParameterizedType(CoreTypes.iterable, [
        runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 0) ??
            runtime.lookupType(CoreTypes.dynamic),
      ]);
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
  }

  static const $Function __skip = $Function(_skip);
  static $Value? _skip(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
    final result = self.$value.skip((r as $int).$value);
    return (() {
      final iterableType = runtime.internParameterizedType(CoreTypes.iterable, [
        runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 0) ??
            runtime.lookupType(CoreTypes.dynamic),
      ]);
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
  }

  static const $Function __skipWhile = $Function(_skipWhile);
  static $Value? _skipWhile(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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
    return (() {
      final iterableType = runtime.internParameterizedType(CoreTypes.iterable, [
        runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 0) ??
            runtime.lookupType(CoreTypes.dynamic),
      ]);
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
  }

  static const $Function __firstWhere = $Function(_firstWhere);
  static $Value? _firstWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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

  static const $Function __lastWhere = $Function(_lastWhere);
  static $Value? _lastWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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

  static const $Function __singleWhere = $Function(_singleWhere);
  static $Value? _singleWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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

  static const $Function __elementAt = $Function(_elementAt);
  static $Value? _elementAt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
    final result = self.$value[(r as $int).$value];
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __indexOf = $Function(_indexOf);
  static $Value? _indexOf(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
    final result = self.$value.lastIndexOf(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
      (s is $Value ? s : null)?.$value,
    );
    return $int(result);
  }

  static const $Function __operatorPlus = $Function(_operatorPlus);
  static $Value? _operatorPlus(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
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
    final self = target! as $UnmodifiableListView;
    final result = self.$value.getRange((r as $int).$value, (s as $int).$value);
    return (() {
      final iterableType = runtime.internParameterizedType(CoreTypes.iterable, [
        runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 0) ??
            runtime.lookupType(CoreTypes.dynamic),
      ]);
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
  }

  static const $Function __asMap = $Function(_asMap);
  static $Value? _asMap(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $UnmodifiableListView;
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
      case 'length':
        $value.length = value.$reified;
        return;
      case 'first':
        $value.first = value.$reified;
        return;
      case 'last':
        $value.last = value.$reified;
        return;
    }
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
