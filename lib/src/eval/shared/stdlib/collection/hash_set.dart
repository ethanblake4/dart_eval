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
        $DoubleLinkedQueueEntry;

/// dart_eval wrapper binding for [HashSet]
class $HashSet<E> implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'HashSet.',
      $HashSet.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'HashSet.identity',
      $HashSet.$identity,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'HashSet.from',
      $HashSet.$from,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'HashSet.of',
      $HashSet.$of,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$HashSet]
  static const $spec = BridgeTypeSpec('dart:collection', 'HashSet');

  /// Compile-time type declaration of [$HashSet]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$HashSet]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                        false,
                      ),

                      BridgeParameter(
                        'null',
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
              'elements',
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

      'of': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
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
        isFactory: true,
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
      ),

      'lookup': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E'), nullable: true),
          namedParams: [],
          params: [
            BridgeParameter(
              'object',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
            ),
          ],
        ),
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
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [HashSet.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $HashSet.wrap(
      HashSet(
        equals:
            (r is $Value ? r : null) == null ||
                (r is $Value ? r : null) is $null
            ? null
            : (dynamic arg0, dynamic arg1) {
                return ((r is $Value ? r : null)! as EvalCallable?)
                    ?.call(
                      runtime,
                      null,
                      runtime.wrapAlways(arg0, recursive: true),
                      runtime.wrapAlways(arg1, recursive: true),
                      2,
                    )
                    ?.$value;
              },
        hashCode:
            (s is $Value ? s : null) == null ||
                (s is $Value ? s : null) is $null
            ? null
            : (dynamic arg0) {
                return ((s is $Value ? s : null)! as EvalCallable?)
                    ?.call(
                      runtime,
                      null,
                      runtime.wrapAlways(arg0, recursive: true),
                      null,
                      1,
                    )
                    ?.$value;
              },
        isValidKey:
            (c is $Value ? c : null) == null ||
                (c is $Value ? c : null) is $null
            ? null
            : (dynamic arg0) {
                return ((c is $Value ? c : null)! as EvalCallable?)
                    ?.call(
                      runtime,
                      null,
                      runtime.wrapAlways(arg0, recursive: true),
                      null,
                      1,
                    )
                    ?.$value;
              },
      ),
    );
  }

  /// Wrapper for the [HashSet.identity] constructor
  static $Value? $identity(Runtime runtime, Object? r, Object? s, Object? c) {
    return $HashSet.wrap(HashSet.identity());
  }

  /// Wrapper for the [HashSet.from] constructor
  static $Value? $from(Runtime runtime, Object? r, Object? s, Object? c) {
    return $HashSet.wrap(HashSet.from((r as $Value?)!.$value));
  }

  /// Wrapper for the [HashSet.of] constructor
  static $Value? $of(Runtime runtime, Object? r, Object? s, Object? c) {
    return $HashSet.wrap(HashSet.of((r as $Value?)!.$value));
  }

  final $Instance _superclass;

  @override
  final HashSet<E> $value;

  @override
  HashSet get $reified => $value;

  /// Wrap a [HashSet] in a [$HashSet]
  $HashSet.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

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
        return runtime.wrapAlways(_first, recursive: true);
      case 'last':
        final _last = $value.last;
        return runtime.wrapAlways(_last, recursive: true);
      case 'single':
        final _single = $value.single;
        return runtime.wrapAlways(_single, recursive: true);
      case 'cast':
        return __cast;

      case 'followedBy':
        return __followedBy;

      case 'map':
        return __map;

      case 'where':
        return __where;

      case 'whereType':
        return __whereType;

      case 'expand':
        return __expand;

      case 'contains':
        return __contains;

      case 'forEach':
        return __forEach;

      case 'reduce':
        return __reduce;

      case 'fold':
        return __fold;

      case 'every':
        return __every;

      case 'join':
        return __join;

      case 'any':
        return __any;

      case 'toList':
        return __toList;

      case 'toSet':
        return __toSet;

      case 'take':
        return __take;

      case 'takeWhile':
        return __takeWhile;

      case 'skip':
        return __skip;

      case 'skipWhile':
        return __skipWhile;

      case 'firstWhere':
        return __firstWhere;

      case 'lastWhere':
        return __lastWhere;

      case 'singleWhere':
        return __singleWhere;

      case 'elementAt':
        return __elementAt;

      case 'add':
        return __add;

      case 'addAll':
        return __addAll;

      case 'remove':
        return __remove;

      case 'lookup':
        return __lookup;

      case 'removeAll':
        return __removeAll;

      case 'retainAll':
        return __retainAll;

      case 'removeWhere':
        return __removeWhere;

      case 'retainWhere':
        return __retainWhere;

      case 'containsAll':
        return __containsAll;

      case 'intersection':
        return __intersection;

      case 'union':
        return __union;

      case 'difference':
        return __difference;

      case 'clear':
        return __clear;
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
    final self = target! as $HashSet;
    final result = self.$value.cast();
    return $Set.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)).toSet(),
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
    final self = target! as $HashSet;
    final result = self.$value.followedBy((r as $Value?)!.$value);
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $HashSet;
    final result = self.$value.map((dynamic e) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(e, recursive: true),
        null,
        1,
      )?.$value;
    });
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $HashSet;
    final result = self.$value.where((dynamic element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(element, recursive: true),
        null,
        1,
      )?.$value;
    });
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $HashSet;
    final result = self.$value.whereType();
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $HashSet;
    final result = self.$value.expand((dynamic element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(element, recursive: true),
        null,
        1,
      )?.$value;
    });
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $HashSet;
    final result = self.$value.contains((r as $Value?)!.$reified);
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
    final self = target! as $HashSet;
    self.$value.forEach((dynamic element) {
      ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(element, recursive: true),
        null,
        1,
      );
    });
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
    final self = target! as $HashSet;
    final result = self.$value.reduce((dynamic value, dynamic element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(value, recursive: true),
        runtime.wrapAlways(element, recursive: true),
        2,
      )?.$value;
    });
    return runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __fold = $Function(_fold);
  static $Value? _fold(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashSet;
    final result = self.$value.fold((r as $Value?)!.$value, (
      dynamic previousValue,
      dynamic element,
    ) {
      return ((s as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(previousValue, recursive: true),
        runtime.wrapAlways(element, recursive: true),
        2,
      )?.$value;
    });
    return runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __every = $Function(_every);
  static $Value? _every(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashSet;
    final result = self.$value.every((dynamic element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(element, recursive: true),
        null,
        1,
      )?.$value;
    });
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
    final self = target! as $HashSet;
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
    final self = target! as $HashSet;
    final result = self.$value.any((dynamic element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(element, recursive: true),
        null,
        1,
      )?.$value;
    });
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
    final self = target! as $HashSet;
    final result = self.$value.toList(
      growable: (r is $Value ? r : null) == null ? true : (r as $bool).$value,
    );
    return $List.view(result, (e) => runtime.wrapAlways(e, recursive: true));
  }

  static const $Function __toSet = $Function(_toSet);
  static $Value? _toSet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashSet;
    final result = self.$value.toSet();
    return $Set.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)).toSet(),
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
    final self = target! as $HashSet;
    final result = self.$value.take((r as $int).$value);
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $HashSet;
    final result = self.$value.takeWhile((dynamic value) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(value, recursive: true),
        null,
        1,
      )?.$value;
    });
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $HashSet;
    final result = self.$value.skip((r as $int).$value);
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $HashSet;
    final result = self.$value.skipWhile((dynamic value) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(value, recursive: true),
        null,
        1,
      )?.$value;
    });
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $HashSet;
    final result = self.$value.firstWhere(
      (dynamic element) {
        return ((r as $Value?)! as EvalCallable)(
          runtime,
          null,
          runtime.wrapAlways(element, recursive: true),
          null,
          1,
        )?.$value;
      },
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : () {
              return ((s is $Value ? s : null)! as EvalCallable?)
                  ?.call(runtime, null, null, null, 0)
                  ?.$value;
            },
    );
    return runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __lastWhere = $Function(_lastWhere);
  static $Value? _lastWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashSet;
    final result = self.$value.lastWhere(
      (dynamic element) {
        return ((r as $Value?)! as EvalCallable)(
          runtime,
          null,
          runtime.wrapAlways(element, recursive: true),
          null,
          1,
        )?.$value;
      },
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : () {
              return ((s is $Value ? s : null)! as EvalCallable?)
                  ?.call(runtime, null, null, null, 0)
                  ?.$value;
            },
    );
    return runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __singleWhere = $Function(_singleWhere);
  static $Value? _singleWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashSet;
    final result = self.$value.singleWhere(
      (dynamic element) {
        return ((r as $Value?)! as EvalCallable)(
          runtime,
          null,
          runtime.wrapAlways(element, recursive: true),
          null,
          1,
        )?.$value;
      },
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : () {
              return ((s is $Value ? s : null)! as EvalCallable?)
                  ?.call(runtime, null, null, null, 0)
                  ?.$value;
            },
    );
    return runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __elementAt = $Function(_elementAt);
  static $Value? _elementAt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashSet;
    final result = self.$value.elementAt((r as $int).$value);
    return runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __add = $Function(_add);
  static $Value? _add(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashSet;
    final result = self.$value.add((r as $Value?)!.$value);
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
    final self = target! as $HashSet;
    self.$value.addAll((r as $Value?)!.$value);
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
    final self = target! as $HashSet;
    final result = self.$value.remove((r as $Value?)!.$reified);
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
    final self = target! as $HashSet;
    final result = self.$value.lookup((r as $Value?)!.$reified);
    return result == null
        ? const $null()
        : runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __removeAll = $Function(_removeAll);
  static $Value? _removeAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HashSet;
    self.$value.removeAll((r as $Value?)!.$value);
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
    final self = target! as $HashSet;
    self.$value.retainAll((r as $Value?)!.$value);
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
    final self = target! as $HashSet;
    self.$value.removeWhere((dynamic element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(element, recursive: true),
        null,
        1,
      )?.$value;
    });
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
    final self = target! as $HashSet;
    self.$value.retainWhere((dynamic element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(element, recursive: true),
        null,
        1,
      )?.$value;
    });
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
    final self = target! as $HashSet;
    final result = self.$value.containsAll((r as $Value?)!.$value);
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
    final self = target! as $HashSet;
    final result = self.$value.intersection(
      ((r as $Value?)!.$reified as Set).cast<Object?>(),
    );
    return $Set.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)).toSet(),
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
    final self = target! as $HashSet;
    final result = self.$value.union(
      ((r as $Value?)!.$reified as Set).cast<dynamic>(),
    );
    return $Set.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)).toSet(),
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
    final self = target! as $HashSet;
    final result = self.$value.difference(
      ((r as $Value?)!.$reified as Set).cast<Object?>(),
    );
    return $Set.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)).toSet(),
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
    final self = target! as $HashSet;
    self.$value.clear();
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
