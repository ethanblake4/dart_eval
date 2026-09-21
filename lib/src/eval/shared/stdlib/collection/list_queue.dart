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

import 'queue.dart';

/// dart_eval wrapper binding for [ListQueue]
class $ListQueue<E> implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'ListQueue.',
      $ListQueue.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'ListQueue.from',
      $ListQueue.$from,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:collection',
      'ListQueue.of',
      $ListQueue.$of,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$ListQueue]
  static const $spec = BridgeTypeSpec('dart:collection', 'ListQueue');

  /// Compile-time type declaration of [$ListQueue]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ListQueue]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      generics: {'E': BridgeGenericParam()},

      $implements: [
        BridgeTypeRef(CoreTypes.iterable, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
        ]),
        BridgeTypeRef(CoreTypes.object, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
        ]),
        BridgeTypeRef(CollectionTypes.queue, [
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
              'initialCapacity',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: false,
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
            BridgeTypeRef(CollectionTypes.queue, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'removeFirst': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
          namedParams: [],
          params: [],
        ),
      ),

      'removeLast': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
          namedParams: [],
          params: [],
        ),
      ),

      'addFirst': BridgeMethodDef(
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

      'addLast': BridgeMethodDef(
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

      'add': BridgeMethodDef(
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

      'clear': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
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
    },
    getters: {
      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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

  /// Wrapper for the [ListQueue.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $ListQueue.wrap(ListQueue((r is $Value ? r : null)?.$value));
  }

  /// Wrapper for the [ListQueue.from] constructor
  static $Value? $from(Runtime runtime, Object? r, Object? s, Object? c) {
    return $ListQueue.wrap(ListQueue.from((r as $Value?)!.$value));
  }

  /// Wrapper for the [ListQueue.of] constructor
  static $Value? $of(Runtime runtime, Object? r, Object? s, Object? c) {
    return $ListQueue.wrap(ListQueue.of((r as $Value?)!.$value));
  }

  final $Instance _superclass;

  @override
  final ListQueue<E> $value;

  @override
  ListQueue get $reified => $value;

  /// Wrap a [ListQueue] in a [$ListQueue]
  $ListQueue.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'iterator':
        final _iterator = $value.iterator;
        return $Iterator.wrap(_iterator);
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
        return runtime.wrapAlways(_first, recursive: true);
      case 'last':
        final _last = $value.last;
        return runtime.wrapAlways(_last, recursive: true);
      case 'single':
        final _single = $value.single;
        return runtime.wrapAlways(_single, recursive: true);
      case 'cast':
        return __cast;

      case 'removeFirst':
        return __removeFirst;

      case 'removeLast':
        return __removeLast;

      case 'addFirst':
        return __addFirst;

      case 'addLast':
        return __addLast;

      case 'add':
        return __add;

      case 'remove':
        return __remove;

      case 'addAll':
        return __addAll;

      case 'removeWhere':
        return __removeWhere;

      case 'retainWhere':
        return __retainWhere;

      case 'clear':
        return __clear;

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
    final self = target! as $ListQueue;
    final result = self.$value.cast();
    return $Queue.wrap(result);
  }

  static const $Function __removeFirst = $Function(_removeFirst);
  static $Value? _removeFirst(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListQueue;
    final result = self.$value.removeFirst();
    return runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __removeLast = $Function(_removeLast);
  static $Value? _removeLast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListQueue;
    final result = self.$value.removeLast();
    return runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __addFirst = $Function(_addFirst);
  static $Value? _addFirst(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListQueue;
    self.$value.addFirst((r as $Value?)!.$value);
    return null;
  }

  static const $Function __addLast = $Function(_addLast);
  static $Value? _addLast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListQueue;
    self.$value.addLast((r as $Value?)!.$value);
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
    final self = target! as $ListQueue;
    self.$value.add((r as $Value?)!.$value);
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
    final self = target! as $ListQueue;
    final result = self.$value.remove((r as $Value?)!.$reified);
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
    final self = target! as $ListQueue;
    self.$value.addAll((r as $Value?)!.$value);
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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

  static const $Function __clear = $Function(_clear);
  static $Value? _clear(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListQueue;
    self.$value.clear();
    return null;
  }

  static const $Function __followedBy = $Function(_followedBy);
  static $Value? _followedBy(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
    final result = self.$value.map((dynamic element) {
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

  static const $Function __where = $Function(_where);
  static $Value? _where(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
    final result = self.$value.takeWhile((dynamic element) {
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

  static const $Function __skip = $Function(_skip);
  static $Value? _skip(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
    final result = self.$value.skipWhile((dynamic element) {
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

  static const $Function __firstWhere = $Function(_firstWhere);
  static $Value? _firstWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
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
    final self = target! as $ListQueue;
    final result = self.$value.elementAt((r as $int).$value);
    return runtime.wrapAlways(result, recursive: true);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
