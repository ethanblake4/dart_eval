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
        $TimeoutException,
        $Zone,
        $StreamSubscription,
        $StreamSink,
        $EventSink,
        $StreamIterator,
        $StreamTransformer,
        $StreamTransformerBase,
        $StreamView,
        $StreamController;
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import './timer.dart';

/// dart_eval wrapper binding for [Zone]
class $Zone implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'Zone.root*g',
      $Zone.$root,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'Zone.current*g',
      $Zone.$current,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Zone]
  static const $spec = BridgeTypeSpec('dart:async', 'Zone');

  /// Compile-time type declaration of [$Zone]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Zone]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {},

    methods: {
      'handleUncaughtError': BridgeMethodDef(
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
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stackTrace, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'inSameErrorZone': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'otherZone',
              BridgeTypeAnnotation(BridgeTypeRef(AsyncTypes.zone, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'fork': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(AsyncTypes.zone, [])),
          namedParams: [
            BridgeParameter(
              'specification',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'zoneValues',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
                  ),
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
                  ),
                ]),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [],
        ),

        isAbstract: true,
      ),

      'run': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'R': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
          namedParams: [],
          params: [
            BridgeParameter(
              'action',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                    params: [],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'runUnary': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'R': BridgeGenericParam(), 'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
          namedParams: [],
          params: [
            BridgeParameter(
              'action',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                    params: [
                      BridgeParameter(
                        'argument',
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

            BridgeParameter(
              'argument',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'runBinary': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {
            'R': BridgeGenericParam(),
            'T1': BridgeGenericParam(),
            'T2': BridgeGenericParam(),
          },
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
          namedParams: [],
          params: [
            BridgeParameter(
              'action',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                    params: [
                      BridgeParameter(
                        'argument1',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T1')),
                        false,
                      ),

                      BridgeParameter(
                        'argument2',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T2')),
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
              'argument1',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T1')),
              false,
            ),

            BridgeParameter(
              'argument2',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T2')),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'runGuarded': BridgeMethodDef(
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
                    params: [],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'runUnaryGuarded': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T': BridgeGenericParam()},
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
                        'argument',
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

            BridgeParameter(
              'argument',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'runBinaryGuarded': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T1': BridgeGenericParam(), 'T2': BridgeGenericParam()},
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
                        'argument1',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T1')),
                        false,
                      ),

                      BridgeParameter(
                        'argument2',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T2')),
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
              'argument1',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T1')),
              false,
            ),

            BridgeParameter(
              'argument2',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T2')),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'registerCallback': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'R': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef.genericFunction(
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                params: [],
                namedParams: [],
              ),
            ),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'callback',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                    params: [],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'registerUnaryCallback': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'R': BridgeGenericParam(), 'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef.genericFunction(
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                params: [
                  BridgeParameter(
                    'null',
                    BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                    false,
                  ),
                ],
                namedParams: [],
              ),
            ),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'callback',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                    params: [
                      BridgeParameter(
                        'arg',
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

        isAbstract: true,
      ),

      'registerBinaryCallback': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {
            'R': BridgeGenericParam(),
            'T1': BridgeGenericParam(),
            'T2': BridgeGenericParam(),
          },
          returns: BridgeTypeAnnotation(
            BridgeTypeRef.genericFunction(
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                params: [
                  BridgeParameter(
                    'null',
                    BridgeTypeAnnotation(BridgeTypeRef.ref('T1')),
                    false,
                  ),

                  BridgeParameter(
                    'null',
                    BridgeTypeAnnotation(BridgeTypeRef.ref('T2')),
                    false,
                  ),
                ],
                namedParams: [],
              ),
            ),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'callback',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                    params: [
                      BridgeParameter(
                        'arg1',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T1')),
                        false,
                      ),

                      BridgeParameter(
                        'arg2',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T2')),
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

        isAbstract: true,
      ),

      'bindCallback': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'R': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef.genericFunction(
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                params: [],
                namedParams: [],
              ),
            ),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'callback',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                    params: [],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'bindUnaryCallback': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'R': BridgeGenericParam(), 'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef.genericFunction(
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                params: [
                  BridgeParameter(
                    'null',
                    BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                    false,
                  ),
                ],
                namedParams: [],
              ),
            ),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'callback',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                    params: [
                      BridgeParameter(
                        'argument',
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

        isAbstract: true,
      ),

      'bindBinaryCallback': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {
            'R': BridgeGenericParam(),
            'T1': BridgeGenericParam(),
            'T2': BridgeGenericParam(),
          },
          returns: BridgeTypeAnnotation(
            BridgeTypeRef.genericFunction(
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                params: [
                  BridgeParameter(
                    'null',
                    BridgeTypeAnnotation(BridgeTypeRef.ref('T1')),
                    false,
                  ),

                  BridgeParameter(
                    'null',
                    BridgeTypeAnnotation(BridgeTypeRef.ref('T2')),
                    false,
                  ),
                ],
                namedParams: [],
              ),
            ),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'callback',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
                    params: [
                      BridgeParameter(
                        'argument1',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T1')),
                        false,
                      ),

                      BridgeParameter(
                        'argument2',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T2')),
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

        isAbstract: true,
      ),

      'bindCallbackGuarded': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef.genericFunction(
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType),
                ),
                params: [],
                namedParams: [],
              ),
            ),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'callback',
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
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'bindUnaryCallbackGuarded': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef.genericFunction(
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType),
                ),
                params: [
                  BridgeParameter(
                    'null',
                    BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                    false,
                  ),
                ],
                namedParams: [],
              ),
            ),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'callback',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'argument',
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

        isAbstract: true,
      ),

      'bindBinaryCallbackGuarded': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T1': BridgeGenericParam(), 'T2': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef.genericFunction(
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType),
                ),
                params: [
                  BridgeParameter(
                    'null',
                    BridgeTypeAnnotation(BridgeTypeRef.ref('T1')),
                    false,
                  ),

                  BridgeParameter(
                    'null',
                    BridgeTypeAnnotation(BridgeTypeRef.ref('T2')),
                    false,
                  ),
                ],
                namedParams: [],
              ),
            ),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'callback',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'argument1',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T1')),
                        false,
                      ),

                      BridgeParameter(
                        'argument2',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T2')),
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

        isAbstract: true,
      ),

      'errorCallback': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.object, []),
            nullable: true,
          ),
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
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'scheduleMicrotask': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'callback',
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
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'createTimer': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(AsyncTypes.timer, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'duration',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
              false,
            ),

            BridgeParameter(
              'callback',
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
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'createPeriodicTimer': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(AsyncTypes.timer, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'period',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
              false,
            ),

            BridgeParameter(
              'callback',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'timer',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(AsyncTypes.timer, []),
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

        isAbstract: true,
      ),

      'print': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'line',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '[]': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
          namedParams: [],
          params: [
            BridgeParameter(
              'key',
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
    },
    getters: {
      'current': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(AsyncTypes.zone, [])),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'parent': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(AsyncTypes.zone, []),
            nullable: true,
          ),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'errorZone': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(AsyncTypes.zone, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),
    },
    setters: {},
    fields: {
      'root': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(AsyncTypes.zone, [])),
        isStatic: true,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Zone.root] getter
  static $Value? $root(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Zone.root;
    return $Zone.wrap(value);
  }

  /// Wrapper for the [Zone.current] getter
  static $Value? $current(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Zone.current;
    return $Zone.wrap(value);
  }

  final $Instance _superclass;

  @override
  final Zone $value;

  @override
  Zone get $reified => $value;

  /// Wrap a [Zone] in a [$Zone]
  $Zone.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'parent':
        final _parent = $value.parent;
        return _parent == null ? const $null() : $Zone.wrap(_parent);
      case 'errorZone':
        final _errorZone = $value.errorZone;
        return $Zone.wrap(_errorZone);
      case 'handleUncaughtError':
        return $Closure(__handleUncaughtError.func, this);

      case 'inSameErrorZone':
        return $Closure(__inSameErrorZone.func, this);

      case 'fork':
        return $Closure(__fork.func, this);

      case 'run':
        return $Closure(__run.func, this);

      case 'runUnary':
        return $Closure(__runUnary.func, this);

      case 'runBinary':
        return $Closure(__runBinary.func, this);

      case 'runGuarded':
        return $Closure(__runGuarded.func, this);

      case 'runUnaryGuarded':
        return $Closure(__runUnaryGuarded.func, this);

      case 'runBinaryGuarded':
        return $Closure(__runBinaryGuarded.func, this);

      case 'registerCallback':
        return $Closure(__registerCallback.func, this);

      case 'registerUnaryCallback':
        return $Closure(__registerUnaryCallback.func, this);

      case 'registerBinaryCallback':
        return $Closure(__registerBinaryCallback.func, this);

      case 'bindCallback':
        return $Closure(__bindCallback.func, this);

      case 'bindUnaryCallback':
        return $Closure(__bindUnaryCallback.func, this);

      case 'bindBinaryCallback':
        return $Closure(__bindBinaryCallback.func, this);

      case 'bindCallbackGuarded':
        return $Closure(__bindCallbackGuarded.func, this);

      case 'bindUnaryCallbackGuarded':
        return $Closure(__bindUnaryCallbackGuarded.func, this);

      case 'bindBinaryCallbackGuarded':
        return $Closure(__bindBinaryCallbackGuarded.func, this);

      case 'errorCallback':
        return $Closure(__errorCallback.func, this);

      case 'scheduleMicrotask':
        return $Closure(__scheduleMicrotask.func, this);

      case 'createTimer':
        return $Closure(__createTimer.func, this);

      case 'createPeriodicTimer':
        return $Closure(__createPeriodicTimer.func, this);

      case 'print':
        return $Closure(__print.func, this);

      case '[]':
        return $Closure(__operatorIndexGet.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __handleUncaughtError = $Function(
    _handleUncaughtError,
  );
  static $Value? _handleUncaughtError(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    self.$value.handleUncaughtError(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object,
      (s as $Value?)!.$value,
    );
    return null;
  }

  static const $Function __inSameErrorZone = $Function(_inSameErrorZone);
  static $Value? _inSameErrorZone(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.inSameErrorZone((r as $Value?)!.$value);
    return $bool(result);
  }

  static const $Function __fork = $Function(_fork);
  static $Value? _fork(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.fork(
      specification: (r is $Value ? r : null)?.$value,
      zoneValues: ((s is $Value ? s : null)?.$reified as Map?)
          ?.cast<Object?, Object?>(),
    );
    return $Zone.wrap(result);
  }

  static const $Function __run = $Function(_run);
  static $Value? _run(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.run(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "R Function();export=false",
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

  static const $Function __runUnary = $Function(_runUnary);
  static $Value? _runUnary(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.runUnary(
      (() {
        final _callbackType0 = (runtime.bridgeCallTypeArguments.length > 1
            ? runtime.bridgeCallTypeArguments[1]
            : runtime.lookupType(CoreTypes.dynamic));
        return runtime.cachedCallback(
          (r as $Value?)! as EvalCallable,
          "R Function(T);export=false" + ";types=$_callbackType0",
          (_callable) => (dynamic argument) {
            return TypedInterop.exportExternal(
              _callable.call(
                runtime,
                null,
                TypedInterop.boxExternal(
                  argument,
                  runtime: runtime,
                  runtimeTypeId: _callbackType0,
                ),
                null,
                1,
              ),
              runtime: runtime,
            ) as dynamic;
          },
        );
      })(),
      TypedInterop.exportExternal((s as $Value?), runtime: runtime) as dynamic,
    );
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __runBinary = $Function(_runBinary);
  static $Value? _runBinary(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.runBinary(
      (() {
        final _callbackType0 = (runtime.bridgeCallTypeArguments.length > 1
            ? runtime.bridgeCallTypeArguments[1]
            : runtime.lookupType(CoreTypes.dynamic));
        final _callbackType1 = (runtime.bridgeCallTypeArguments.length > 2
            ? runtime.bridgeCallTypeArguments[2]
            : runtime.lookupType(CoreTypes.dynamic));
        return runtime.cachedCallback(
          (r as $Value?)! as EvalCallable,
          "R Function(T1, T2);export=false" +
              ";types=$_callbackType0,$_callbackType1",
          (_callable) => (dynamic argument1, dynamic argument2) {
            return TypedInterop.exportExternal(
              _callable.call(
                runtime,
                null,
                TypedInterop.boxExternal(
                  argument1,
                  runtime: runtime,
                  runtimeTypeId: _callbackType0,
                ),
                TypedInterop.boxExternal(
                  argument2,
                  runtime: runtime,
                  runtimeTypeId: _callbackType1,
                ),
                2,
              ),
              runtime: runtime,
            ) as dynamic;
          },
        );
      })(),
      TypedInterop.exportExternal((s as $Value?), runtime: runtime) as dynamic,
      TypedInterop.exportExternal(
        ((c as List<Object?>)[0] as $Value?),
        runtime: runtime,
      ) as dynamic,
    );
    return (result is List || result is Map || result is Set
        ? TypedInterop.boxExternal(result, runtime: runtime)!
        : runtime.wrapAlways(result));
  }

  static const $Function __runGuarded = $Function(_runGuarded);
  static $Value? _runGuarded(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    self.$value.runGuarded(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "void Function();export=false",
        (_callable) => () {
          _callable.call(runtime, null, null, null, 0);
        },
      ),
    );
    return null;
  }

  static const $Function __runUnaryGuarded = $Function(_runUnaryGuarded);
  static $Value? _runUnaryGuarded(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    self.$value.runUnaryGuarded(
      (() {
        final _callbackType0 = (runtime.bridgeCallTypeArguments.length > 0
            ? runtime.bridgeCallTypeArguments[0]
            : runtime.lookupType(CoreTypes.dynamic));
        return runtime.cachedCallback(
          (r as $Value?)! as EvalCallable,
          "void Function(T);export=false" + ";types=$_callbackType0",
          (_callable) => (dynamic argument) {
            _callable.call(
              runtime,
              null,
              TypedInterop.boxExternal(
                argument,
                runtime: runtime,
                runtimeTypeId: _callbackType0,
              ),
              null,
              1,
            );
          },
        );
      })(),
      TypedInterop.exportExternal((s as $Value?), runtime: runtime) as dynamic,
    );
    return null;
  }

  static const $Function __runBinaryGuarded = $Function(_runBinaryGuarded);
  static $Value? _runBinaryGuarded(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    self.$value.runBinaryGuarded(
      (() {
        final _callbackType0 = (runtime.bridgeCallTypeArguments.length > 0
            ? runtime.bridgeCallTypeArguments[0]
            : runtime.lookupType(CoreTypes.dynamic));
        final _callbackType1 = (runtime.bridgeCallTypeArguments.length > 1
            ? runtime.bridgeCallTypeArguments[1]
            : runtime.lookupType(CoreTypes.dynamic));
        return runtime.cachedCallback(
          (r as $Value?)! as EvalCallable,
          "void Function(T1, T2);export=false" +
              ";types=$_callbackType0,$_callbackType1",
          (_callable) => (dynamic argument1, dynamic argument2) {
            _callable.call(
              runtime,
              null,
              TypedInterop.boxExternal(
                argument1,
                runtime: runtime,
                runtimeTypeId: _callbackType0,
              ),
              TypedInterop.boxExternal(
                argument2,
                runtime: runtime,
                runtimeTypeId: _callbackType1,
              ),
              2,
            );
          },
        );
      })(),
      TypedInterop.exportExternal((s as $Value?), runtime: runtime) as dynamic,
      TypedInterop.exportExternal(
        ((c as List<Object?>)[0] as $Value?),
        runtime: runtime,
      ) as dynamic,
    );
    return null;
  }

  static const $Function __registerCallback = $Function(_registerCallback);
  static $Value? _registerCallback(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.registerCallback(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "R Function();export=false",
        (_callable) => () {
          return TypedInterop.exportExternal(
            _callable.call(runtime, null, null, null, 0),
            runtime: runtime,
          ) as dynamic;
        },
      ),
    );
    return $Function((runtime, target, r, s, c) {
      final funcResult = result();
      return (funcResult is List || funcResult is Map || funcResult is Set
          ? TypedInterop.boxExternal(funcResult, runtime: runtime)!
          : runtime.wrapAlways(funcResult));
    });
  }

  static const $Function __registerUnaryCallback = $Function(
    _registerUnaryCallback,
  );
  static $Value? _registerUnaryCallback(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.registerUnaryCallback(
      (() {
        final _callbackType0 = (runtime.bridgeCallTypeArguments.length > 1
            ? runtime.bridgeCallTypeArguments[1]
            : runtime.lookupType(CoreTypes.dynamic));
        return runtime.cachedCallback(
          (r as $Value?)! as EvalCallable,
          "R Function(T);export=false" + ";types=$_callbackType0",
          (_callable) => (dynamic arg) {
            return TypedInterop.exportExternal(
              _callable.call(
                runtime,
                null,
                TypedInterop.boxExternal(
                  arg,
                  runtime: runtime,
                  runtimeTypeId: _callbackType0,
                ),
                null,
                1,
              ),
              runtime: runtime,
            ) as dynamic;
          },
        );
      })(),
    );
    return $Function((runtime, target, r, s, c) {
      final funcResult = result(
        TypedInterop.exportExternal((r as $Value?), runtime: runtime)
            as dynamic,
      );
      return (funcResult is List || funcResult is Map || funcResult is Set
          ? TypedInterop.boxExternal(funcResult, runtime: runtime)!
          : runtime.wrapAlways(funcResult));
    });
  }

  static const $Function __registerBinaryCallback = $Function(
    _registerBinaryCallback,
  );
  static $Value? _registerBinaryCallback(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.registerBinaryCallback(
      (() {
        final _callbackType0 = (runtime.bridgeCallTypeArguments.length > 1
            ? runtime.bridgeCallTypeArguments[1]
            : runtime.lookupType(CoreTypes.dynamic));
        final _callbackType1 = (runtime.bridgeCallTypeArguments.length > 2
            ? runtime.bridgeCallTypeArguments[2]
            : runtime.lookupType(CoreTypes.dynamic));
        return runtime.cachedCallback(
          (r as $Value?)! as EvalCallable,
          "R Function(T1, T2);export=false" +
              ";types=$_callbackType0,$_callbackType1",
          (_callable) => (dynamic arg1, dynamic arg2) {
            return TypedInterop.exportExternal(
              _callable.call(
                runtime,
                null,
                TypedInterop.boxExternal(
                  arg1,
                  runtime: runtime,
                  runtimeTypeId: _callbackType0,
                ),
                TypedInterop.boxExternal(
                  arg2,
                  runtime: runtime,
                  runtimeTypeId: _callbackType1,
                ),
                2,
              ),
              runtime: runtime,
            ) as dynamic;
          },
        );
      })(),
    );
    return $Function((runtime, target, r, s, c) {
      final funcResult = result(
        TypedInterop.exportExternal((r as $Value?), runtime: runtime)
            as dynamic,
        TypedInterop.exportExternal((s as $Value?), runtime: runtime)
            as dynamic,
      );
      return (funcResult is List || funcResult is Map || funcResult is Set
          ? TypedInterop.boxExternal(funcResult, runtime: runtime)!
          : runtime.wrapAlways(funcResult));
    });
  }

  static const $Function __bindCallback = $Function(_bindCallback);
  static $Value? _bindCallback(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.bindCallback(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "R Function();export=false",
        (_callable) => () {
          return TypedInterop.exportExternal(
            _callable.call(runtime, null, null, null, 0),
            runtime: runtime,
          ) as dynamic;
        },
      ),
    );
    return $Function((runtime, target, r, s, c) {
      final funcResult = result();
      return (funcResult is List || funcResult is Map || funcResult is Set
          ? TypedInterop.boxExternal(funcResult, runtime: runtime)!
          : runtime.wrapAlways(funcResult));
    });
  }

  static const $Function __bindUnaryCallback = $Function(_bindUnaryCallback);
  static $Value? _bindUnaryCallback(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.bindUnaryCallback(
      (() {
        final _callbackType0 = (runtime.bridgeCallTypeArguments.length > 1
            ? runtime.bridgeCallTypeArguments[1]
            : runtime.lookupType(CoreTypes.dynamic));
        return runtime.cachedCallback(
          (r as $Value?)! as EvalCallable,
          "R Function(T);export=false" + ";types=$_callbackType0",
          (_callable) => (dynamic argument) {
            return TypedInterop.exportExternal(
              _callable.call(
                runtime,
                null,
                TypedInterop.boxExternal(
                  argument,
                  runtime: runtime,
                  runtimeTypeId: _callbackType0,
                ),
                null,
                1,
              ),
              runtime: runtime,
            ) as dynamic;
          },
        );
      })(),
    );
    return $Function((runtime, target, r, s, c) {
      final funcResult = result(
        TypedInterop.exportExternal((r as $Value?), runtime: runtime)
            as dynamic,
      );
      return (funcResult is List || funcResult is Map || funcResult is Set
          ? TypedInterop.boxExternal(funcResult, runtime: runtime)!
          : runtime.wrapAlways(funcResult));
    });
  }

  static const $Function __bindBinaryCallback = $Function(_bindBinaryCallback);
  static $Value? _bindBinaryCallback(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.bindBinaryCallback(
      (() {
        final _callbackType0 = (runtime.bridgeCallTypeArguments.length > 1
            ? runtime.bridgeCallTypeArguments[1]
            : runtime.lookupType(CoreTypes.dynamic));
        final _callbackType1 = (runtime.bridgeCallTypeArguments.length > 2
            ? runtime.bridgeCallTypeArguments[2]
            : runtime.lookupType(CoreTypes.dynamic));
        return runtime.cachedCallback(
          (r as $Value?)! as EvalCallable,
          "R Function(T1, T2);export=false" +
              ";types=$_callbackType0,$_callbackType1",
          (_callable) => (dynamic argument1, dynamic argument2) {
            return TypedInterop.exportExternal(
              _callable.call(
                runtime,
                null,
                TypedInterop.boxExternal(
                  argument1,
                  runtime: runtime,
                  runtimeTypeId: _callbackType0,
                ),
                TypedInterop.boxExternal(
                  argument2,
                  runtime: runtime,
                  runtimeTypeId: _callbackType1,
                ),
                2,
              ),
              runtime: runtime,
            ) as dynamic;
          },
        );
      })(),
    );
    return $Function((runtime, target, r, s, c) {
      final funcResult = result(
        TypedInterop.exportExternal((r as $Value?), runtime: runtime)
            as dynamic,
        TypedInterop.exportExternal((s as $Value?), runtime: runtime)
            as dynamic,
      );
      return (funcResult is List || funcResult is Map || funcResult is Set
          ? TypedInterop.boxExternal(funcResult, runtime: runtime)!
          : runtime.wrapAlways(funcResult));
    });
  }

  static const $Function __bindCallbackGuarded = $Function(
    _bindCallbackGuarded,
  );
  static $Value? _bindCallbackGuarded(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.bindCallbackGuarded(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "void Function();export=false",
        (_callable) => () {
          _callable.call(runtime, null, null, null, 0);
        },
      ),
    );
    return $Function((runtime, target, r, s, c) {
      result();
      return const $null();
    });
  }

  static const $Function __bindUnaryCallbackGuarded = $Function(
    _bindUnaryCallbackGuarded,
  );
  static $Value? _bindUnaryCallbackGuarded(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.bindUnaryCallbackGuarded(
      (() {
        final _callbackType0 = (runtime.bridgeCallTypeArguments.length > 0
            ? runtime.bridgeCallTypeArguments[0]
            : runtime.lookupType(CoreTypes.dynamic));
        return runtime.cachedCallback(
          (r as $Value?)! as EvalCallable,
          "void Function(T);export=false" + ";types=$_callbackType0",
          (_callable) => (dynamic argument) {
            _callable.call(
              runtime,
              null,
              TypedInterop.boxExternal(
                argument,
                runtime: runtime,
                runtimeTypeId: _callbackType0,
              ),
              null,
              1,
            );
          },
        );
      })(),
    );
    return $Function((runtime, target, r, s, c) {
      result(
        TypedInterop.exportExternal((r as $Value?), runtime: runtime)
            as dynamic,
      );
      return const $null();
    });
  }

  static const $Function __bindBinaryCallbackGuarded = $Function(
    _bindBinaryCallbackGuarded,
  );
  static $Value? _bindBinaryCallbackGuarded(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.bindBinaryCallbackGuarded(
      (() {
        final _callbackType0 = (runtime.bridgeCallTypeArguments.length > 0
            ? runtime.bridgeCallTypeArguments[0]
            : runtime.lookupType(CoreTypes.dynamic));
        final _callbackType1 = (runtime.bridgeCallTypeArguments.length > 1
            ? runtime.bridgeCallTypeArguments[1]
            : runtime.lookupType(CoreTypes.dynamic));
        return runtime.cachedCallback(
          (r as $Value?)! as EvalCallable,
          "void Function(T1, T2);export=false" +
              ";types=$_callbackType0,$_callbackType1",
          (_callable) => (dynamic argument1, dynamic argument2) {
            _callable.call(
              runtime,
              null,
              TypedInterop.boxExternal(
                argument1,
                runtime: runtime,
                runtimeTypeId: _callbackType0,
              ),
              TypedInterop.boxExternal(
                argument2,
                runtime: runtime,
                runtimeTypeId: _callbackType1,
              ),
              2,
            );
          },
        );
      })(),
    );
    return $Function((runtime, target, r, s, c) {
      result(
        TypedInterop.exportExternal((r as $Value?), runtime: runtime)
            as dynamic,
        TypedInterop.exportExternal((s as $Value?), runtime: runtime)
            as dynamic,
      );
      return const $null();
    });
  }

  static const $Function __errorCallback = $Function(_errorCallback);
  static $Value? _errorCallback(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.errorCallback(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object,
      (s as $Value?)!.$value,
    );
    return result == null ? const $null() : $Object(result);
  }

  static const $Function __scheduleMicrotask = $Function(_scheduleMicrotask);
  static $Value? _scheduleMicrotask(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    self.$value.scheduleMicrotask(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "void Function();export=false",
        (_callable) => () {
          _callable.call(runtime, null, null, null, 0);
        },
      ),
    );
    return null;
  }

  static const $Function __createTimer = $Function(_createTimer);
  static $Value? _createTimer(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.createTimer(
      (r as $Value?)!.$value,
      runtime.cachedCallback(
        (s as $Value?)! as EvalCallable,
        "void Function();export=false",
        (_callable) => () {
          _callable.call(runtime, null, null, null, 0);
        },
      ),
    );
    return $Timer.wrap(result);
  }

  static const $Function __createPeriodicTimer = $Function(
    _createPeriodicTimer,
  );
  static $Value? _createPeriodicTimer(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result = self.$value.createPeriodicTimer(
      (r as $Value?)!.$value,
      (() {
        final _callbackType0 = runtime.lookupType(AsyncTypes.timer);
        return runtime.cachedCallback(
          (s as $Value?)! as EvalCallable,
          "void Function(Timer);export=false" + ";types=$_callbackType0",
          (_callable) => (Timer timer) {
            _callable.call(
              runtime,
              null,
              TypedInterop.annotateBridgeType(
                $Timer.wrap(timer),
                runtime,
                _callbackType0,
              ),
              null,
              1,
            );
          },
        );
      })(),
    );
    return $Timer.wrap(result);
  }

  static const $Function __print = $Function(_print);
  static $Value? _print(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    self.$value.print((r as $String).$value);
    return null;
  }

  static const $Function __operatorIndexGet = $Function(_operatorIndexGet);
  static $Value? _operatorIndexGet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Zone;
    final result =
        self.$value[TypedInterop.exportExternal(
          (r as $Value?),
          runtime: runtime,
        ) as Object?];
    return runtime.wrapAlways(result, recursive: true);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
