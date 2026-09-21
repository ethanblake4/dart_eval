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

import 'dart:async';

import 'package:dart_eval/stdlib/core.dart'
    hide
        $Completer,
        $Timer,
        $Zone,
        $StreamSubscription,
        $StreamSink,
        $StreamIterator,
        $StreamTransformer,
        $StreamView,
        $StreamController;
import 'package:dart_eval/stdlib/async.dart'
    hide
        $Completer,
        $Timer,
        $Zone,
        $StreamSubscription,
        $StreamSink,
        $StreamIterator,
        $StreamTransformer,
        $StreamView,
        $StreamController;

import 'stream_subscription.dart';

/// dart_eval wrapper binding for [StreamView]
class $StreamView<T> implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'StreamView.',
      $StreamView.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$StreamView]
  static const $spec = BridgeTypeSpec('dart:async', 'StreamView');

  /// Compile-time type declaration of [$StreamView]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$StreamView]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      generics: {'T': BridgeGenericParam()},

      $implements: [
        BridgeTypeRef(CoreTypes.stream, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
              'stream',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.stream, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
      'asBroadcastStream': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'onListen',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'subscription',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(AsyncTypes.streamSubscription, [
                            BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                          ]),
                        ),
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
              'onCancel',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'subscription',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(AsyncTypes.streamSubscription, [
                            BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                          ]),
                        ),
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
      ),

      'listen': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(AsyncTypes.streamSubscription, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'onError',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'onDone',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'cancelOnError',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.bool, []),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'onData',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              false,
            ),
          ],
        ),
      ),

      'where': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
                        'event',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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

      'map': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'S': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'convert',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                    params: [
                      BridgeParameter(
                        'event',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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

      'asyncMap': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'E': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
                      BridgeTypeRef(CoreTypes.object, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                      ]),
                    ),
                    params: [
                      BridgeParameter(
                        'event',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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

      'asyncExpand': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'E': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
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
                      BridgeTypeRef(CoreTypes.stream, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                      ]),
                      nullable: true,
                    ),
                    params: [
                      BridgeParameter(
                        'event',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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

      'handleError': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [
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
                        'error',
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
              'onError',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              false,
            ),
          ],
        ),
      ),

      'expand': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'S': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
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
                      BridgeTypeRef(CoreTypes.iterable, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                      ]),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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

      'pipe': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'streamConsumer',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'transform': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'S': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'streamTransformer',
              BridgeTypeAnnotation(
                BridgeTypeRef(AsyncTypes.streamTransformer, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                  BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'reduce': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'combine',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                    params: [
                      BridgeParameter(
                        'previous',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                        false,
                      ),

                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
          generics: {'S': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'initialValue',
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
              false,
            ),

            BridgeParameter(
              'combine',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                    params: [
                      BridgeParameter(
                        'previous',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                        false,
                      ),

                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
            ]),
          ),
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

      'contains': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'needle',
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
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            ]),
          ),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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

      'any': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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

      'cast': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'R': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'toList': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                ]),
              ),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'toSet': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.set, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                ]),
              ),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'drain': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'E': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'futureValue',
              BridgeTypeAnnotation(BridgeTypeRef.ref('E'), nullable: true),
              true,
            ),
          ],
        ),
      ),

      'take': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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

      'distinct': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
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
                        'previous',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                        false,
                      ),

                      BridgeParameter(
                        'next',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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

      'firstWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
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
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
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

      'timeout': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'onTimeout',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'sink',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.object, [
                            BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                          ]),
                        ),
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
              'timeLimit',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
              false,
            ),
          ],
        ),
      ),
    },
    getters: {
      'isBroadcast': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'isEmpty': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'first': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'last': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'single': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
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

  /// Wrapper for the [StreamView.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $StreamView.wrap(StreamView((r as $Value?)!.$value));
  }

  final $Instance _superclass;

  @override
  final StreamView<T> $value;

  @override
  StreamView get $reified => $value;

  /// Wrap a [StreamView] in a [$StreamView]
  $StreamView.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'isBroadcast':
        final _isBroadcast = $value.isBroadcast;
        return $bool(_isBroadcast);
      case 'length':
        final _length = $value.length;
        return $Future.wrap(_length.then((e) => $int(e)));
      case 'isEmpty':
        final _isEmpty = $value.isEmpty;
        return $Future.wrap(_isEmpty.then((e) => $bool(e)));
      case 'first':
        final _first = $value.first;
        return $Future.wrap(
          _first.then((e) => runtime.wrapAlways(e, recursive: true)),
        );
      case 'last':
        final _last = $value.last;
        return $Future.wrap(
          _last.then((e) => runtime.wrapAlways(e, recursive: true)),
        );
      case 'single':
        final _single = $value.single;
        return $Future.wrap(
          _single.then((e) => runtime.wrapAlways(e, recursive: true)),
        );
      case 'asBroadcastStream':
        return __asBroadcastStream;

      case 'listen':
        return __listen;

      case 'where':
        return __where;

      case 'map':
        return __map;

      case 'asyncMap':
        return __asyncMap;

      case 'asyncExpand':
        return __asyncExpand;

      case 'handleError':
        return __handleError;

      case 'expand':
        return __expand;

      case 'pipe':
        return __pipe;

      case 'transform':
        return __transform;

      case 'reduce':
        return __reduce;

      case 'fold':
        return __fold;

      case 'join':
        return __join;

      case 'contains':
        return __contains;

      case 'forEach':
        return __forEach;

      case 'every':
        return __every;

      case 'any':
        return __any;

      case 'cast':
        return __cast;

      case 'toList':
        return __toList;

      case 'toSet':
        return __toSet;

      case 'drain':
        return __drain;

      case 'take':
        return __take;

      case 'takeWhile':
        return __takeWhile;

      case 'skip':
        return __skip;

      case 'skipWhile':
        return __skipWhile;

      case 'distinct':
        return __distinct;

      case 'firstWhere':
        return __firstWhere;

      case 'lastWhere':
        return __lastWhere;

      case 'singleWhere':
        return __singleWhere;

      case 'elementAt':
        return __elementAt;

      case 'timeout':
        return __timeout;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __asBroadcastStream = $Function(_asBroadcastStream);
  static $Value? _asBroadcastStream(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.asBroadcastStream(
      onListen:
          (r is $Value ? r : null) == null || (r is $Value ? r : null) is $null
          ? null
          : (StreamSubscription<dynamic> subscription) {
              ((r is $Value ? r : null)! as EvalCallable?)?.call(
                runtime,
                null,
                $StreamSubscription.wrap(subscription),
                null,
                1,
              );
            },
      onCancel:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : (StreamSubscription<dynamic> subscription) {
              ((s is $Value ? s : null)! as EvalCallable?)?.call(
                runtime,
                null,
                $StreamSubscription.wrap(subscription),
                null,
                1,
              );
            },
    );
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __listen = $Function(_listen);
  static $Value? _listen(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.listen(
      (r as $Value?) == null || (r as $Value?) is $null
          ? null
          : (dynamic value) {
              ((r as $Value?)! as EvalCallable)(
                runtime,
                null,
                runtime.wrapAlways(value, recursive: true),
                null,
                1,
              );
            },
      onError:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : (a0, [a1, a2]) {
              final _a0 = runtime.wrapAlways(a0);
              ((s is $Value ? s : null)! as EvalCallable?)?.call(
                runtime,
                null,
                _a0,
                a1 != null ? runtime.wrapAlways(a1) : null,
                a2 != null
                    ? [runtime.wrapAlways(a2)]
                    : a1 != null
                    ? 2
                    : 1,
              );
            },
      onDone:
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
              ((c is List && (c as List).length > 0
                          ? (c as List)[0] as $Value?
                          : null)!
                      as EvalCallable?)
                  ?.call(runtime, null, null, null, 0);
            },
      cancelOnError:
          (c is List && (c as List).length > 1
                  ? (c as List)[1] as $Value?
                  : null)
              ?.$value,
    );
    return $StreamSubscription.wrap(result);
  }

  static const $Function __where = $Function(_where);
  static $Value? _where(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.where((dynamic event) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(event, recursive: true),
        null,
        1,
      )?.$value;
    });
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $StreamView;
    final result = self.$value.map((dynamic event) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(event, recursive: true),
        null,
        1,
      )?.$value;
    });
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __asyncMap = $Function(_asyncMap);
  static $Value? _asyncMap(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.asyncMap((dynamic event) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(event, recursive: true),
        null,
        1,
      )?.$value;
    });
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __asyncExpand = $Function(_asyncExpand);
  static $Value? _asyncExpand(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.asyncExpand((dynamic event) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(event, recursive: true),
        null,
        1,
      )?.$value;
    });
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __handleError = $Function(_handleError);
  static $Value? _handleError(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.handleError(
      (a0, [a1, a2]) {
        final _a0 = runtime.wrapAlways(a0);
        ((r as $Value?)! as EvalCallable)(
          runtime,
          null,
          _a0,
          a1 != null ? runtime.wrapAlways(a1) : null,
          a2 != null
              ? [runtime.wrapAlways(a2)]
              : a1 != null
              ? 2
              : 1,
        );
      },
      test:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : (dynamic error) {
              return ((s is $Value ? s : null)! as EvalCallable?)
                  ?.call(
                    runtime,
                    null,
                    runtime.wrapAlways(error, recursive: true),
                    null,
                    1,
                  )
                  ?.$value;
            },
    );
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $StreamView;
    final result = self.$value.expand((dynamic element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(element, recursive: true),
        null,
        1,
      )?.$value;
    });
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __pipe = $Function(_pipe);
  static $Value? _pipe(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.pipe((r as $Value?)!.$value);
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __transform = $Function(_transform);
  static $Value? _transform(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.transform((r as $Value?)!.$value);
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __reduce = $Function(_reduce);
  static $Value? _reduce(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.reduce((dynamic previous, dynamic element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(previous, recursive: true),
        runtime.wrapAlways(element, recursive: true),
        2,
      )?.$value;
    });
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __fold = $Function(_fold);
  static $Value? _fold(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.fold((r as $Value?)!.$value, (
      dynamic previous,
      dynamic element,
    ) {
      return ((s as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(previous, recursive: true),
        runtime.wrapAlways(element, recursive: true),
        2,
      )?.$value;
    });
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __join = $Function(_join);
  static $Value? _join(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.join(
      (r is $Value ? r : null) == null ? "" : (r as $String).$value,
    );
    return $Future.wrap(result.then((e) => $String(e)));
  }

  static const $Function __contains = $Function(_contains);
  static $Value? _contains(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.contains((r as $Value?)!.$reified);
    return $Future.wrap(result.then((e) => $bool(e)));
  }

  static const $Function __forEach = $Function(_forEach);
  static $Value? _forEach(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.forEach((dynamic element) {
      ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(element, recursive: true),
        null,
        1,
      );
    });
    return $Future.wrap(result.then((e) => null));
  }

  static const $Function __every = $Function(_every);
  static $Value? _every(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.every((dynamic element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(element, recursive: true),
        null,
        1,
      )?.$value;
    });
    return $Future.wrap(result.then((e) => $bool(e)));
  }

  static const $Function __any = $Function(_any);
  static $Value? _any(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.any((dynamic element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(element, recursive: true),
        null,
        1,
      )?.$value;
    });
    return $Future.wrap(result.then((e) => $bool(e)));
  }

  static const $Function __cast = $Function(_cast);
  static $Value? _cast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.cast();
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __toList = $Function(_toList);
  static $Value? _toList(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.toList();
    return $Future.wrap(
      result.then(
        (e) => $List.view(e, (e) => runtime.wrapAlways(e, recursive: true)),
      ),
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
    final self = target! as $StreamView;
    final result = self.$value.toSet();
    return $Future.wrap(
      result.then(
        (e) => $Set.wrap(
          (e).map((e) => runtime.wrapAlways(e, recursive: true)).toSet(),
        ),
      ),
    );
  }

  static const $Function __drain = $Function(_drain);
  static $Value? _drain(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.drain((r is $Value ? r : null)?.$value);
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $StreamView;
    final result = self.$value.take((r as $int).$value);
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $StreamView;
    final result = self.$value.takeWhile((dynamic element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(element, recursive: true),
        null,
        1,
      )?.$value;
    });
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $StreamView;
    final result = self.$value.skip((r as $int).$value);
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $StreamView;
    final result = self.$value.skipWhile((dynamic element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(element, recursive: true),
        null,
        1,
      )?.$value;
    });
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __distinct = $Function(_distinct);
  static $Value? _distinct(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.distinct(
      (r is $Value ? r : null) == null || (r is $Value ? r : null) is $null
          ? null
          : (dynamic previous, dynamic next) {
              return ((r is $Value ? r : null)! as EvalCallable?)
                  ?.call(
                    runtime,
                    null,
                    runtime.wrapAlways(previous, recursive: true),
                    runtime.wrapAlways(next, recursive: true),
                    2,
                  )
                  ?.$value;
            },
    );
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $StreamView;
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
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __lastWhere = $Function(_lastWhere);
  static $Value? _lastWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
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
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __singleWhere = $Function(_singleWhere);
  static $Value? _singleWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
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
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __elementAt = $Function(_elementAt);
  static $Value? _elementAt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.elementAt((r as $int).$value);
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __timeout = $Function(_timeout);
  static $Value? _timeout(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamView;
    final result = self.$value.timeout(
      (r as $Value?)!.$value,
      onTimeout:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : (EventSink<dynamic> sink) {
              ((s is $Value ? s : null)! as EvalCallable?)?.call(
                runtime,
                null,
                $Object(sink),
                null,
                1,
              );
            },
    );
    return $Stream.wrap(
      result.map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
