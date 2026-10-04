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

import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:dart_eval/stdlib/core.dart'
    hide
        $Platform,
        $SocketException,
        $HttpException,
        $OSError,
        $HttpHeaders,
        $RedirectInfo,
        $Socket;
import 'package:dart_eval/stdlib/async.dart'
    hide
        $Platform,
        $SocketException,
        $HttpException,
        $OSError,
        $HttpHeaders,
        $RedirectInfo,
        $Socket;
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../convert/encoding.dart';
import '../typed_data/typed_data.dart';

import 'package:dart_eval/stdlib/io.dart'
    hide
        $Platform,
        $SocketException,
        $HttpException,
        $OSError,
        $HttpHeaders,
        $RedirectInfo,
        $Socket;
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

import '../async/stream_subscription.dart';
import '../async/event_sink.dart';
import 'socket_hooks.dart' as hooks;

/// dart_eval wrapper binding for [Socket]
class $Socket implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Socket.connect',
      $Socket.$connect,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Socket.startConnect',
      $Socket.$startConnect,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Socket]
  static const $spec = BridgeTypeSpec('dart:io', 'Socket');

  /// Compile-time type declaration of [$Socket]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Socket]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      $implements: [
        BridgeTypeRef(CoreTypes.stream, [
          BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
        ]),
        BridgeTypeRef(IoTypes.ioSink, []),
        BridgeTypeRef(AsyncTypes.streamSink, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
        ]),
        BridgeTypeRef(AsyncTypes.eventSink, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
        ]),
        BridgeTypeRef(CoreTypes.sink, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
        ]),
        BridgeTypeRef(CoreTypes.object, [
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
        ]),
        BridgeTypeRef(CoreTypes.stringSink, []),
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
      'write': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
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

        isAbstract: true,
      ),

      'writeAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'objects',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
              ),
              false,
            ),

            BridgeParameter(
              'separator',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
              defaultValueSource: "\"\"",
            ),
          ],
        ),

        isAbstract: true,
      ),

      'writeln': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'object',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              true,
              defaultValueSource: "\"\"",
            ),
          ],
        ),

        isAbstract: true,
      ),

      'writeCharCode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'charCode',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'addStream': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'stream',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.stream, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.list, [
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                    ]),
                  ),
                ]),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'close': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
            ]),
          ),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'add': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'data',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'addError': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'error',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              false,
            ),

            BridgeParameter(
              'stackTrace',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.stackTrace, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'flush': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
            ]),
          ),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'asBroadcastStream': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
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
                            BridgeTypeAnnotation(
                              BridgeTypeRef(TypedDataTypes.uint8List, []),
                            ),
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
                            BridgeTypeAnnotation(
                              BridgeTypeRef(TypedDataTypes.uint8List, []),
                            ),
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
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
                        'event',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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

        isAbstract: true,
      ),

      'where': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
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
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
                      BridgeTypeRef(AsyncTypes.futureOr, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('E')),
                      ]),
                    ),
                    params: [
                      BridgeParameter(
                        'event',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
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
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
                  BridgeTypeAnnotation(
                    BridgeTypeRef(TypedDataTypes.uint8List, []),
                  ),
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
                  BridgeTypeAnnotation(
                    BridgeTypeRef(TypedDataTypes.uint8List, []),
                  ),
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'combine',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(TypedDataTypes.uint8List, []),
                    ),
                    params: [
                      BridgeParameter(
                        'previous',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
                        false,
                      ),

                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
              defaultValueSource: "\"\"",
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
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
                  BridgeTypeAnnotation(
                    BridgeTypeRef(TypedDataTypes.uint8List, []),
                  ),
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
                  BridgeTypeAnnotation(
                    BridgeTypeRef(TypedDataTypes.uint8List, []),
                  ),
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
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
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
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
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
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
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
                        false,
                      ),

                      BridgeParameter(
                        'next',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
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
        ),
      ),

      'firstWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(TypedDataTypes.uint8List, []),
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
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(TypedDataTypes.uint8List, []),
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
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(TypedDataTypes.uint8List, []),
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
                        BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.uint8List, []),
                        ),
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
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
                          BridgeTypeRef(AsyncTypes.eventSink, [
                            BridgeTypeAnnotation(
                              BridgeTypeRef(TypedDataTypes.uint8List, []),
                            ),
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

      'connect': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(IoTypes.socket, [])),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'sourceAddress',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              true,
            ),

            BridgeParameter(
              'sourcePort',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "0",
            ),

            BridgeParameter(
              'timeout',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.duration, []),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'host',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              false,
            ),

            BridgeParameter(
              'port',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'startConnect': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, [
                  BridgeTypeAnnotation(BridgeTypeRef(IoTypes.socket, [])),
                ]),
              ),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'sourceAddress',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              true,
            ),

            BridgeParameter(
              'sourcePort',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "0",
            ),
          ],
          params: [
            BridgeParameter(
              'host',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              false,
            ),

            BridgeParameter(
              'port',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'destroy': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'setOption': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'option',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              false,
            ),

            BridgeParameter(
              'enabled',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'getRawOption': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(TypedDataTypes.uint8List, []),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'option',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'setRawOption': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'option',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
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
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'done': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
            ]),
          ),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'port': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'remotePort': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'address': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(IoTypes.internetAddress, []),
          ),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'remoteAddress': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(IoTypes.internetAddress, []),
          ),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),
    },
    setters: {},
    fields: {
      'encoding': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Socket.connect] method
  static $Value? $connect(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;

    return hooks.socketConnect(runtime, null, [
      r as $Value?,
      s as $Value?,
      ...(c is List ? (c as List).cast<$Value?>().take(3) : const <$Value?>[]),
    ]);
  }

  /// Wrapper for the [Socket.startConnect] method
  static $Value? $startConnect(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;

    return hooks.socketStartConnect(runtime, null, [
      r as $Value?,
      s as $Value?,
      ...(c is List ? (c as List).cast<$Value?>().take(2) : const <$Value?>[]),
    ]);
  }

  final $Instance _superclass;

  @override
  final Socket $value;

  @override
  Socket get $reified => $value;

  /// Wrap a [Socket] in a [$Socket]
  $Socket.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'done':
        final _done = $value.done;
        return $Future.wrap(
          _done.then((e) => runtime.wrapAlways(e, recursive: true)),
          runtime: runtime,
          runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
            runtime.lookupType(CoreTypes.dynamic),
          ]),
        );
      case 'encoding':
        final _encoding = $value.encoding;
        return $Encoding.wrap(_encoding);
      case 'isBroadcast':
        final _isBroadcast = $value.isBroadcast;
        return $bool(_isBroadcast);
      case 'length':
        final _length = $value.length;
        return $Future.wrap(
          _length.then((e) => $int(e)),
          runtime: runtime,
          runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
            runtime.lookupType(CoreTypes.int),
          ]),
        );
      case 'isEmpty':
        final _isEmpty = $value.isEmpty;
        return $Future.wrap(
          _isEmpty.then((e) => $bool(e)),
          runtime: runtime,
          runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
            runtime.lookupType(CoreTypes.bool),
          ]),
        );
      case 'first':
        final _first = $value.first;
        return $Future.wrap(
          _first.then((e) => $Uint8List.wrap(e)),
          runtime: runtime,
          runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
            runtime.lookupType(TypedDataTypes.uint8List),
          ]),
        );
      case 'last':
        final _last = $value.last;
        return $Future.wrap(
          _last.then((e) => $Uint8List.wrap(e)),
          runtime: runtime,
          runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
            runtime.lookupType(TypedDataTypes.uint8List),
          ]),
        );
      case 'single':
        final _single = $value.single;
        return $Future.wrap(
          _single.then((e) => $Uint8List.wrap(e)),
          runtime: runtime,
          runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
            runtime.lookupType(TypedDataTypes.uint8List),
          ]),
        );
      case 'port':
        final _port = $value.port;
        return $int(_port);
      case 'remotePort':
        final _remotePort = $value.remotePort;
        return $int(_remotePort);
      case 'address':
        final _address = $value.address;
        return $InternetAddress.wrap(_address);
      case 'remoteAddress':
        final _remoteAddress = $value.remoteAddress;
        return $InternetAddress.wrap(_remoteAddress);
      case 'write':
        return $Closure(__write.func, this);

      case 'writeAll':
        return $Closure(__writeAll.func, this);

      case 'writeln':
        return $Closure(__writeln.func, this);

      case 'writeCharCode':
        return $Closure(__writeCharCode.func, this);

      case 'addStream':
        return $Closure(__addStream.func, this);

      case 'close':
        return $Closure(__close.func, this);

      case 'add':
        return $Closure(__add.func, this);

      case 'addError':
        return $Closure(__addError.func, this);

      case 'flush':
        return $Closure(__flush.func, this);

      case 'asBroadcastStream':
        return $Closure(__asBroadcastStream.func, this);

      case 'listen':
        return $Closure(__listen.func, this);

      case 'where':
        return $Closure(__where.func, this);

      case 'map':
        return $Closure(__map.func, this);

      case 'asyncMap':
        return $Closure(__asyncMap.func, this);

      case 'asyncExpand':
        return $Closure(__asyncExpand.func, this);

      case 'handleError':
        return $Closure(__handleError.func, this);

      case 'expand':
        return $Closure(__expand.func, this);

      case 'pipe':
        return $Closure(__pipe.func, this);

      case 'transform':
        return $Closure(__transform.func, this);

      case 'reduce':
        return $Closure(__reduce.func, this);

      case 'fold':
        return $Closure(__fold.func, this);

      case 'join':
        return $Closure(__join.func, this);

      case 'contains':
        return $Closure(__contains.func, this);

      case 'forEach':
        return $Closure(__forEach.func, this);

      case 'every':
        return $Closure(__every.func, this);

      case 'any':
        return $Closure(__any.func, this);

      case 'cast':
        return $Closure(__cast.func, this);

      case 'toList':
        return $Closure(__toList.func, this);

      case 'toSet':
        return $Closure(__toSet.func, this);

      case 'drain':
        return $Closure(__drain.func, this);

      case 'take':
        return $Closure(__take.func, this);

      case 'takeWhile':
        return $Closure(__takeWhile.func, this);

      case 'skip':
        return $Closure(__skip.func, this);

      case 'skipWhile':
        return $Closure(__skipWhile.func, this);

      case 'distinct':
        return $Closure(__distinct.func, this);

      case 'firstWhere':
        return $Closure(__firstWhere.func, this);

      case 'lastWhere':
        return $Closure(__lastWhere.func, this);

      case 'singleWhere':
        return $Closure(__singleWhere.func, this);

      case 'elementAt':
        return $Closure(__elementAt.func, this);

      case 'timeout':
        return $Closure(__timeout.func, this);

      case 'destroy':
        return $Closure(__destroy.func, this);

      case 'setOption':
        return $Closure(__setOption.func, this);

      case 'getRawOption':
        return $Closure(__getRawOption.func, this);

      case 'setRawOption':
        return $Closure(__setRawOption.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __write = $Function(_write);
  static $Value? _write(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    self.$value.write(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
    );
    return null;
  }

  static const $Function __writeAll = $Function(_writeAll);
  static $Value? _writeAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    self.$value.writeAll(
      TypedInterop.exportIterable((r as $Value?), runtime),
      (s is $Value ? s : null) == null ? "" : (s as $String).$value,
    );
    return null;
  }

  static const $Function __writeln = $Function(_writeln);
  static $Value? _writeln(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    self.$value.writeln(
      (r is $Value ? r : null) == null
          ? ""
          : TypedInterop.exportExternal(
              (r is $Value ? r : null),
              runtime: runtime,
            ) as Object?,
    );
    return null;
  }

  static const $Function __writeCharCode = $Function(_writeCharCode);
  static $Value? _writeCharCode(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    self.$value.writeCharCode((r as $int).$value);
    return null;
  }

  static const $Function __addStream = $Function(_addStream);
  static $Value? _addStream(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    final result = self.$value.addStream((r as $Value?)!.$value);
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(CoreTypes.dynamic),
      ]),
    );
  }

  static const $Function __close = $Function(_close);
  static $Value? _close(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    final result = self.$value.close();
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(CoreTypes.dynamic),
      ]),
    );
  }

  static const $Function __add = $Function(_add);
  static $Value? _add(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    self.$value.add(((r as $Value?)!.$reified as List).cast<int>());
    return null;
  }

  static const $Function __addError = $Function(_addError);
  static $Value? _addError(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    self.$value.addError(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object,
      (s is $Value ? s : null)?.$value,
    );
    return null;
  }

  static const $Function __flush = $Function(_flush);
  static $Value? _flush(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    final result = self.$value.flush();
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(CoreTypes.dynamic),
      ]),
    );
  }

  static const $Function __asBroadcastStream = $Function(_asBroadcastStream);
  static $Value? _asBroadcastStream(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    final result = self.$value.asBroadcastStream(
      onListen:
          (r is $Value ? r : null) == null || (r is $Value ? r : null) is $null
          ? null
          : runtime.cachedCallback(
              (r is $Value ? r : null)! as EvalCallable,
              "void Function(StreamSubscription<Uint8List>);export=false",
              (_callable) => (StreamSubscription<Uint8List> subscription) {
                _callable.call(
                  runtime,
                  null,
                  $StreamSubscription.wrap(subscription),
                  null,
                  1,
                );
              },
            ),
      onCancel:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : runtime.cachedCallback(
              (s is $Value ? s : null)! as EvalCallable,
              "void Function(StreamSubscription<Uint8List>);export=false",
              (_callable) => (StreamSubscription<Uint8List> subscription) {
                _callable.call(
                  runtime,
                  null,
                  $StreamSubscription.wrap(subscription),
                  null,
                  1,
                );
              },
            ),
    );
    return $Stream.wrap(
      result.map((e) => $Uint8List.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
        runtime.lookupType(TypedDataTypes.uint8List),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.listen(
      (r as $Value?) == null || (r as $Value?) is $null
          ? null
          : runtime.cachedCallback(
              (r as $Value?)! as EvalCallable,
              "void Function(Uint8List);export=false",
              (_callable) => (Uint8List event) {
                _callable.call(runtime, null, $Uint8List.wrap(event), null, 1);
              },
            ),
      onError:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : runtime.cachedCallback(
              (s is $Value ? s : null)! as EvalCallable,
              "Function;export=false",
              (_callable) => (a0, [a1, a2]) {
                final _a0 = runtime.wrapAlways(a0);
                _callable.call(
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
            ),
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
          : runtime.cachedCallback(
              (c is List && (c as List).length > 0
                      ? (c as List)[0] as $Value?
                      : null)!
                  as EvalCallable,
              "void Function();export=false",
              (_callable) => () {
                _callable.call(runtime, null, null, null, 0);
              },
            ),
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
    final self = target! as $Socket;
    final result = self.$value.where(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(Uint8List);export=false",
        (_callable) => (Uint8List event) {
          return _callable
              .call(runtime, null, $Uint8List.wrap(event), null, 1)
              ?.$value;
        },
      ),
    );
    return $Stream.wrap(
      result.map((e) => $Uint8List.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
        runtime.lookupType(TypedDataTypes.uint8List),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.map(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "S Function(Uint8List);export=false",
        (_callable) => (Uint8List event) {
          return TypedInterop.exportExternal(
            _callable.call(runtime, null, $Uint8List.wrap(event), null, 1),
            runtime: runtime,
          ) as dynamic;
        },
      ),
    );
    return $Stream.wrap(
      result.map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
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
    final self = target! as $Socket;
    final result = self.$value.asyncMap(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "FutureOr<E> Function(Uint8List);export=false",
        (_callable) => (Uint8List event) {
          return _callable
              .call(runtime, null, $Uint8List.wrap(event), null, 1)
              ?.$value;
        },
      ),
    );
    return $Stream.wrap(
      result.map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
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
    final self = target! as $Socket;
    final result = self.$value.asyncExpand(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "Stream<E>? Function(Uint8List);export=false",
        (_callable) => (Uint8List event) {
          return _callable
              .call(runtime, null, $Uint8List.wrap(event), null, 1)
              ?.$value;
        },
      ),
    );
    return $Stream.wrap(
      result.map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
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
    final self = target! as $Socket;
    final result = self.$value.handleError(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "Function;export=false",
        (_callable) => (a0, [a1, a2]) {
          final _a0 = runtime.wrapAlways(a0);
          _callable.call(
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
      ),
      test:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : runtime.cachedCallback(
              (s is $Value ? s : null)! as EvalCallable,
              "bool Function(dynamic);export=false",
              (_callable) => (dynamic error) {
                return _callable
                    .call(
                      runtime,
                      null,
                      runtime.wrapAlways(error, recursive: true),
                      null,
                      1,
                    )
                    ?.$value;
              },
            ),
    );
    return $Stream.wrap(
      result.map((e) => $Uint8List.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
        runtime.lookupType(TypedDataTypes.uint8List),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.expand(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "Iterable<S> Function(Uint8List);export=false",
        (_callable) => (Uint8List element) {
          return _callable
              .call(runtime, null, $Uint8List.wrap(element), null, 1)
              ?.$value;
        },
      ),
    );
    return $Stream.wrap(
      result.map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
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
    final self = target! as $Socket;
    final result = self.$value.pipe((r as $Value?)!.$value);
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(CoreTypes.dynamic),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.transform((r as $Value?)!.$value);
    return $Stream.wrap(
      result.map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
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
    final self = target! as $Socket;
    final result = self.$value.reduce(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "Uint8List Function(Uint8List, Uint8List);export=false",
        (_callable) => (Uint8List previous, Uint8List element) {
          return _callable
              .call(
                runtime,
                null,
                $Uint8List.wrap(previous),
                $Uint8List.wrap(element),
                2,
              )
              ?.$value;
        },
      ),
    );
    return $Future.wrap(
      result.then((e) => $Uint8List.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(TypedDataTypes.uint8List),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.fold(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as dynamic,
      runtime.cachedCallback(
        (s as $Value?)! as EvalCallable,
        "S Function(S, Uint8List);export=false",
        (_callable) => (dynamic previous, Uint8List element) {
          return TypedInterop.exportExternal(
            _callable.call(
              runtime,
              null,
              runtime.wrapAlways(previous, recursive: true),
              $Uint8List.wrap(element),
              2,
            ),
            runtime: runtime,
          ) as dynamic;
        },
      ),
    );
    return $Future.wrap(
      result.then(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
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
    final self = target! as $Socket;
    final result = self.$value.join(
      (r is $Value ? r : null) == null ? "" : (r as $String).$value,
    );
    return $Future.wrap(
      result.then((e) => $String(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(CoreTypes.string),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.contains(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
    );
    return $Future.wrap(
      result.then((e) => $bool(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(CoreTypes.bool),
      ]),
    );
  }

  static const $Function __forEach = $Function(_forEach);
  static $Value? _forEach(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    final result = self.$value.forEach(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "void Function(Uint8List);export=false",
        (_callable) => (Uint8List element) {
          _callable.call(runtime, null, $Uint8List.wrap(element), null, 1);
        },
      ),
    );
    return $Future.wrap(
      (result as Future<dynamic>).then(
        (e) => runtime.wrapAlways(e, recursive: true),
      ),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(CoreTypes.voidType),
      ]),
    );
  }

  static const $Function __every = $Function(_every);
  static $Value? _every(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    final result = self.$value.every(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(Uint8List);export=false",
        (_callable) => (Uint8List element) {
          return _callable
              .call(runtime, null, $Uint8List.wrap(element), null, 1)
              ?.$value;
        },
      ),
    );
    return $Future.wrap(
      result.then((e) => $bool(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(CoreTypes.bool),
      ]),
    );
  }

  static const $Function __any = $Function(_any);
  static $Value? _any(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    final result = self.$value.any(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(Uint8List);export=false",
        (_callable) => (Uint8List element) {
          return _callable
              .call(runtime, null, $Uint8List.wrap(element), null, 1)
              ?.$value;
        },
      ),
    );
    return $Future.wrap(
      result.then((e) => $bool(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(CoreTypes.bool),
      ]),
    );
  }

  static const $Function __cast = $Function(_cast);
  static $Value? _cast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    final result = self.$value.cast();
    return (() {
      final bridgeTypeArguments = runtime.bridgeCallTypeArguments;
      return $Stream.wrap(
        result.map(
          (e) => (e is List || e is Map || e is Set
              ? TypedInterop.boxExternal(e, runtime: runtime)!
              : runtime.wrapAlways(e)),
        ),
        runtime: runtime,
        runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
          (bridgeTypeArguments.length > 0
              ? bridgeTypeArguments[0]
              : runtime.lookupType(CoreTypes.dynamic)),
        ]),
      );
    })();
  }

  static const $Function __toList = $Function(_toList);
  static $Value? _toList(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    final result = self.$value.toList();
    return $Future.wrap(
      result.then(
        (e) => $List.view(
          e,
          (e) => $Uint8List.wrap(e),
          runtime: runtime,
          runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
            runtime.lookupType(TypedDataTypes.uint8List),
          ]),
        ),
      ),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.internParameterizedType(CoreTypes.list, [
          runtime.lookupType(TypedDataTypes.uint8List),
        ]),
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
    final self = target! as $Socket;
    final result = self.$value.toSet();
    return $Future.wrap(
      result.then((e) => $Set.wrap((e).map((e) => $Uint8List.wrap(e)).toSet())),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.internParameterizedType(CoreTypes.set, [
          runtime.lookupType(TypedDataTypes.uint8List),
        ]),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.drain(
      TypedInterop.exportExternal((r is $Value ? r : null), runtime: runtime)
          as dynamic,
    );
    return (() {
      final bridgeTypeArguments = runtime.bridgeCallTypeArguments;
      return $Future.wrap(
        result.then(
          (e) => (e is List || e is Map || e is Set
              ? TypedInterop.boxExternal(e, runtime: runtime)!
              : runtime.wrapAlways(e)),
        ),
        runtime: runtime,
        runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
          (bridgeTypeArguments.length > 0
              ? bridgeTypeArguments[0]
              : runtime.lookupType(CoreTypes.dynamic)),
        ]),
      );
    })();
  }

  static const $Function __take = $Function(_take);
  static $Value? _take(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    final result = self.$value.take((r as $int).$value);
    return $Stream.wrap(
      result.map((e) => $Uint8List.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
        runtime.lookupType(TypedDataTypes.uint8List),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.takeWhile(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(Uint8List);export=false",
        (_callable) => (Uint8List element) {
          return _callable
              .call(runtime, null, $Uint8List.wrap(element), null, 1)
              ?.$value;
        },
      ),
    );
    return $Stream.wrap(
      result.map((e) => $Uint8List.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
        runtime.lookupType(TypedDataTypes.uint8List),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.skip((r as $int).$value);
    return $Stream.wrap(
      result.map((e) => $Uint8List.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
        runtime.lookupType(TypedDataTypes.uint8List),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.skipWhile(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(Uint8List);export=false",
        (_callable) => (Uint8List element) {
          return _callable
              .call(runtime, null, $Uint8List.wrap(element), null, 1)
              ?.$value;
        },
      ),
    );
    return $Stream.wrap(
      result.map((e) => $Uint8List.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
        runtime.lookupType(TypedDataTypes.uint8List),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.distinct(
      (r is $Value ? r : null) == null || (r is $Value ? r : null) is $null
          ? null
          : runtime.cachedCallback(
              (r is $Value ? r : null)! as EvalCallable,
              "bool Function(Uint8List, Uint8List);export=false",
              (_callable) => (Uint8List previous, Uint8List next) {
                return _callable
                    .call(
                      runtime,
                      null,
                      $Uint8List.wrap(previous),
                      $Uint8List.wrap(next),
                      2,
                    )
                    ?.$value;
              },
            ),
    );
    return $Stream.wrap(
      result.map((e) => $Uint8List.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
        runtime.lookupType(TypedDataTypes.uint8List),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.firstWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(Uint8List);export=false",
        (_callable) => (Uint8List element) {
          return _callable
              .call(runtime, null, $Uint8List.wrap(element), null, 1)
              ?.$value;
        },
      ),
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : runtime.cachedCallback(
              (s is $Value ? s : null)! as EvalCallable,
              "Uint8List Function();export=false",
              (_callable) => () {
                return _callable.call(runtime, null, null, null, 0)?.$value;
              },
            ),
    );
    return $Future.wrap(
      result.then((e) => $Uint8List.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(TypedDataTypes.uint8List),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.lastWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(Uint8List);export=false",
        (_callable) => (Uint8List element) {
          return _callable
              .call(runtime, null, $Uint8List.wrap(element), null, 1)
              ?.$value;
        },
      ),
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : runtime.cachedCallback(
              (s is $Value ? s : null)! as EvalCallable,
              "Uint8List Function();export=false",
              (_callable) => () {
                return _callable.call(runtime, null, null, null, 0)?.$value;
              },
            ),
    );
    return $Future.wrap(
      result.then((e) => $Uint8List.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(TypedDataTypes.uint8List),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.singleWhere(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "bool Function(Uint8List);export=false",
        (_callable) => (Uint8List element) {
          return _callable
              .call(runtime, null, $Uint8List.wrap(element), null, 1)
              ?.$value;
        },
      ),
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : runtime.cachedCallback(
              (s is $Value ? s : null)! as EvalCallable,
              "Uint8List Function();export=false",
              (_callable) => () {
                return _callable.call(runtime, null, null, null, 0)?.$value;
              },
            ),
    );
    return $Future.wrap(
      result.then((e) => $Uint8List.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(TypedDataTypes.uint8List),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.elementAt((r as $int).$value);
    return $Future.wrap(
      result.then((e) => $Uint8List.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(TypedDataTypes.uint8List),
      ]),
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
    final self = target! as $Socket;
    final result = self.$value.timeout(
      (r as $Value?)!.$value,
      onTimeout:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : runtime.cachedCallback(
              (s is $Value ? s : null)! as EvalCallable,
              "void Function(EventSink<Uint8List>);export=false",
              (_callable) => (EventSink<Uint8List> sink) {
                _callable.call(runtime, null, $EventSink.wrap(sink), null, 1);
              },
            ),
    );
    return $Stream.wrap(
      result.map((e) => $Uint8List.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
        runtime.lookupType(TypedDataTypes.uint8List),
      ]),
    );
  }

  static const $Function __destroy = $Function(_destroy);
  static $Value? _destroy(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    self.$value.destroy();
    return null;
  }

  static const $Function __setOption = $Function(_setOption);
  static $Value? _setOption(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    final result = self.$value.setOption(
      (r as $Value?)!.$value,
      (s as $bool).$value,
    );
    return $bool(result);
  }

  static const $Function __getRawOption = $Function(_getRawOption);
  static $Value? _getRawOption(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    final result = self.$value.getRawOption((r as $Value?)!.$value);
    return $Uint8List.wrap(result);
  }

  static const $Function __setRawOption = $Function(_setRawOption);
  static $Value? _setRawOption(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Socket;
    self.$value.setRawOption((r as $Value?)!.$value);
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      case 'encoding':
        $value.encoding = value.$reified;
        return;
    }
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
