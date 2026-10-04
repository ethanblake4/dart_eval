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
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../core/iterator.dart';

/// dart_eval bridge binding for [SetBase]
class $SetBase$bridge<E> extends SetBase<E> with $Bridge<SetBase<E>> {
  /// Forwarded constructor for [SetBase.new]
  $SetBase$bridge();

  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'SetBase.',
      $SetBase$bridge.$new,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'SetBase.setToString',
      $SetBase$bridge.$setToString,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$SetBase$bridge]
  static const $spec = BridgeTypeSpec('dart:collection', 'SetBase');

  /// Compile-time type declaration of [$SetBase$bridge]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$SetBase]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,
      isMixinClass: true,

      generics: {'E': BridgeGenericParam()},

      $implements: [
        BridgeTypeRef(CoreTypes.set, [
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
            BridgeTypeRef(CoreTypes.set, [
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
              'f',
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

        isAbstract: true,
      ),

      'forEach': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'f',
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
              'f',
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

        isAbstract: true,
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
              'n',
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
              'n',
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

      'add': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
              'elements',
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

      'lookup': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E'), nullable: true),
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

        isAbstract: true,
      ),

      'removeAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'elements',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
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
      ),

      'retainAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'elements',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
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

      'containsAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
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
      ),

      'intersection': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.set, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.set, [
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
      ),

      'union': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.set, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.set, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'difference': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.set, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.set, [
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
      ),

      'clear': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),
      ),

      'setToString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'set',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.set, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
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
    },
    setters: {},
    fields: {},
    wrap: false,
    bridge: true,
  );

  /// Proxy for the [SetBase.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $SetBase$bridge();
  }

  /// Wrapper for the [SetBase.setToString] method
  static $Value? $setToString(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = SetBase.setToString(
      ((r as $Value?)!.$reified as Set).cast<dynamic>(),
    );
    return $String(value);
  }

  @override
  $Value? $bridgeGet(String identifier) {
    final runtime = $runtime;
    switch (identifier) {
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
          final result = super.whereType();
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
      case 'addAll':
        return $Function((runtime, target, r, s, c) {
          super.addAll(TypedInterop.exportIterable((r as $Value?), runtime));
          return null;
        });
      case 'removeAll':
        return $Function((runtime, target, r, s, c) {
          super.removeAll(TypedInterop.exportIterable((r as $Value?), runtime));
          return null;
        });
      case 'retainAll':
        return $Function((runtime, target, r, s, c) {
          super.retainAll(TypedInterop.exportIterable((r as $Value?), runtime));
          return null;
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
      case 'containsAll':
        return $Function((runtime, target, r, s, c) {
          final result = super.containsAll(
            TypedInterop.exportIterable((r as $Value?), runtime),
          );
          return $bool(result);
        });
      case 'intersection':
        return $Function((runtime, target, r, s, c) {
          final result = super.intersection(
            ((r as $Value?)!.$reified as Set).cast(),
          );
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
      case 'union':
        return $Function((runtime, target, r, s, c) {
          final result = super.union(((r as $Value?)!.$reified as Set).cast());
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
      case 'difference':
        return $Function((runtime, target, r, s, c) {
          final result = super.difference(
            ((r as $Value?)!.$reified as Set).cast(),
          );
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
      case 'clear':
        return $Function((runtime, target, r, s, c) {
          super.clear();
          return null;
        });
    }
    return null;
  }

  @override
  void $bridgeSet(String identifier, $Value value) {}

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
  Set<R> cast<R>() {
    final runtime = $runtime;
    return ($_invoke('cast', []) as Set).cast();
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
  Iterable<E> where(bool Function(E) f) {
    final runtime = $runtime;
    final result = $_invoke('where', [
      $Function((runtime, target, r, s, c) {
        final funcResult = f(
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
  void forEach(void Function(E) f) {
    final runtime = $runtime;
    $_invoke('forEach', [
      $Function((runtime, target, r, s, c) {
        f(
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
  bool every(bool Function(E) f) {
    final runtime = $runtime;
    return $_invoke('every', [
      $Function((runtime, target, r, s, c) {
        final funcResult = f(
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
  Iterable<E> take(int n) {
    final runtime = $runtime;
    final result = $_invoke('take', [$int(n)]);
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
  Iterable<E> skip(int n) {
    final runtime = $runtime;
    final result = $_invoke('skip', [$int(n)]);
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
  bool add(E value) {
    final runtime = $runtime;
    return $_invoke('add', [
      (value is List || value is Map || value is Set
          ? TypedInterop.boxExternal(value, runtime: runtime)!
          : runtime.wrapAlways(value)),
    ]);
  }

  @override
  void addAll(Iterable<E> elements) {
    final runtime = $runtime;
    $_invoke('addAll', [
      $Iterable.wrap(
        (elements).map((e) => runtime.wrapAlways(e, recursive: true)),
      ),
    ]);
  }

  @override
  bool remove(Object? value) {
    final runtime = $runtime;
    return $_invoke('remove', [
      (value is List || value is Map || value is Set
          ? TypedInterop.boxExternal(value, runtime: runtime)!
          : runtime.wrapAlways(value)),
    ]);
  }

  @override
  E? lookup(Object? element) {
    final runtime = $runtime;
    return $_invoke('lookup', [
      (element is List || element is Map || element is Set
          ? TypedInterop.boxExternal(element, runtime: runtime)!
          : runtime.wrapAlways(element)),
    ]);
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    final runtime = $runtime;
    $_invoke('removeAll', [
      (() {
        final iterableType = runtime.internParameterizedType(
          CoreTypes.iterable,
          [
            runtime.internParameterizedType(
              CoreTypes.object,
              [],
              nullable: true,
            ),
          ],
        );
        return $Iterable.wrap(
          (elements).map((e) {
            final value = e == null ? const $null() : $Object(e);
            runtime.assertTypedTypeArgument(value, iterableType, 0);
            return value;
          }),
          runtime: runtime,
          runtimeTypeId: iterableType,
        );
      })(),
    ]);
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    final runtime = $runtime;
    $_invoke('retainAll', [
      (() {
        final iterableType = runtime.internParameterizedType(
          CoreTypes.iterable,
          [
            runtime.internParameterizedType(
              CoreTypes.object,
              [],
              nullable: true,
            ),
          ],
        );
        return $Iterable.wrap(
          (elements).map((e) {
            final value = e == null ? const $null() : $Object(e);
            runtime.assertTypedTypeArgument(value, iterableType, 0);
            return value;
          }),
          runtime: runtime,
          runtimeTypeId: iterableType,
        );
      })(),
    ]);
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
  bool containsAll(Iterable<Object?> other) {
    final runtime = $runtime;
    return $_invoke('containsAll', [
      (() {
        final iterableType = runtime.internParameterizedType(
          CoreTypes.iterable,
          [
            runtime.internParameterizedType(
              CoreTypes.object,
              [],
              nullable: true,
            ),
          ],
        );
        return $Iterable.wrap(
          (other).map((e) {
            final value = e == null ? const $null() : $Object(e);
            runtime.assertTypedTypeArgument(value, iterableType, 0);
            return value;
          }),
          runtime: runtime,
          runtimeTypeId: iterableType,
        );
      })(),
    ]);
  }

  @override
  Set<E> intersection(Set<Object?> other) {
    final runtime = $runtime;
    return ($_invoke('intersection', [
      TypedInterop.boxExternal(
        other,
        runtime: runtime,
        runtimeTypeId: runtime.internParameterizedType(CoreTypes.set, [
          runtime.internParameterizedType(CoreTypes.object, [], nullable: true),
        ]),
      )!,
    ]) as Set).cast();
  }

  @override
  Set<E> union(Set<E> other) {
    final runtime = $runtime;
    return ($_invoke('union', [
      TypedInterop.boxExternal(
        other,
        runtime: runtime,
        runtimeTypeId: runtime.internParameterizedType(CoreTypes.set, [
          runtime.runtimeTypeArgumentAt(
                Runtime.bridgeData[this]!.$runtimeType,
                0,
              ) ??
              runtime.lookupType(CoreTypes.dynamic),
        ]),
      )!,
    ]) as Set).cast();
  }

  @override
  Set<E> difference(Set<Object?> other) {
    final runtime = $runtime;
    return ($_invoke('difference', [
      TypedInterop.boxExternal(
        other,
        runtime: runtime,
        runtimeTypeId: runtime.internParameterizedType(CoreTypes.set, [
          runtime.internParameterizedType(CoreTypes.object, [], nullable: true),
        ]),
      )!,
    ]) as Set).cast();
  }

  @override
  void clear() {
    final runtime = $runtime;
    $_invoke('clear', []);
  }
}

/// dart_eval lightweight wrapper binding for [SetBase]
class $SetBase<E> implements $Instance {
  /// Compile-time type specification of [$SetBase]
  static const $spec = BridgeTypeSpec('dart:collection', 'SetBase');

  /// Compile-time type declaration of [$SetBase]
  static const $type = BridgeTypeRef($spec);

  final $Instance _superclass;

  @override
  final SetBase<E> $value;

  @override
  SetBase<E> get $reified => $value;

  /// Wrap a [SetBase] in a [$SetBase]
  $SetBase.wrap(this.$value) : _superclass = $Object($value);

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

      case 'add':
        return $Closure(__add.func, this);

      case 'addAll':
        return $Closure(__addAll.func, this);

      case 'remove':
        return $Closure(__remove.func, this);

      case 'lookup':
        return $Closure(__lookup.func, this);

      case 'removeAll':
        return $Closure(__removeAll.func, this);

      case 'retainAll':
        return $Closure(__retainAll.func, this);

      case 'removeWhere':
        return $Closure(__removeWhere.func, this);

      case 'retainWhere':
        return $Closure(__retainWhere.func, this);

      case 'containsAll':
        return $Closure(__containsAll.func, this);

      case 'intersection':
        return $Closure(__intersection.func, this);

      case 'union':
        return $Closure(__union.func, this);

      case 'difference':
        return $Closure(__difference.func, this);

      case 'clear':
        return $Closure(__clear.func, this);
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
    final self = target! as $SetBase;
    final result = self.$value.cast();
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

  static const $Function __followedBy = $Function(_followedBy);
  static $Value? _followedBy(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
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

  static const $Function __where = $Function(_where);
  static $Value? _where(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
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

  static const $Function __contains = $Function(_contains);
  static $Value? _contains(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
    final result = self.$value.reduce(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "E Function(E, E);export=false",
        (_callable) => (dynamic value, dynamic element) {
          return TypedInterop.exportExternal(
            _callable.call(
              runtime,
              null,
              runtime.wrapAlways(value, recursive: true),
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
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
    final result = self.$value.takeWhile(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
    final result = self.$value.skipWhile(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
    final self = target! as $SetBase;
    final result = self.$value.firstWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
    final self = target! as $SetBase;
    final result = self.$value.lastWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
    final self = target! as $SetBase;
    final result = self.$value.singleWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(E);export=false",
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
    final self = target! as $SetBase;
    final result = self.$value.elementAt((r as $int).$value);
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __add = $Function(_add);
  static $Value? _add(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $SetBase;
    final result = self.$value.add(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as dynamic,
    );
    return $bool(result);
  }

  static const $Function __addAll = $Function(_addAll);
  static $Value? _addAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
    final result = self.$value.remove(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
    );
    return $bool(result);
  }

  static const $Function __lookup = $Function(_lookup);
  static $Value? _lookup(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $SetBase;
    final result = self.$value.lookup(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
    );
    return result == null
        ? const $null()
        : (result is List || result is Map || result is Set
              ? TypedInterop.boxExternal(result, runtime: runtime)!
              : runtime.wrapAlways(result));
  }

  static const $Function __removeAll = $Function(_removeAll);
  static $Value? _removeAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $SetBase;
    self.$value.removeAll(TypedInterop.exportIterable((r as $Value?), runtime));
    return null;
  }

  static const $Function __retainAll = $Function(_retainAll);
  static $Value? _retainAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $SetBase;
    self.$value.retainAll(TypedInterop.exportIterable((r as $Value?), runtime));
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
    final self = target! as $SetBase;
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
    final self = target! as $SetBase;
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

  static const $Function __containsAll = $Function(_containsAll);
  static $Value? _containsAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $SetBase;
    final result = self.$value.containsAll(
      TypedInterop.exportIterable((r as $Value?), runtime),
    );
    return $bool(result);
  }

  static const $Function __intersection = $Function(_intersection);
  static $Value? _intersection(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $SetBase;
    final result = self.$value.intersection(
      ((r as $Value?)!.$reified as Set).cast<Object?>(),
    );
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

  static const $Function __union = $Function(_union);
  static $Value? _union(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $SetBase;
    final result = self.$value.union(
      ((r as $Value?)!.$reified as Set).cast<dynamic>(),
    );
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

  static const $Function __difference = $Function(_difference);
  static $Value? _difference(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $SetBase;
    final result = self.$value.difference(
      ((r as $Value?)!.$reified as Set).cast<Object?>(),
    );
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

  static const $Function __clear = $Function(_clear);
  static $Value? _clear(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $SetBase;
    self.$value.clear();
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
