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

import 'stream_sink.dart';

/// dart_eval wrapper binding for [StreamController]
class $StreamController<T> implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'StreamController.',
      $StreamController.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'StreamController.broadcast',
      $StreamController.$broadcast,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$StreamController]
  static const $spec = BridgeTypeSpec('dart:async', 'StreamController');

  /// Compile-time type declaration of [$StreamController]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$StreamController]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      generics: {'T': BridgeGenericParam()},

      $implements: [
        BridgeTypeRef(AsyncTypes.streamSink, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
        ]),
        BridgeTypeRef(CoreTypes.object, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
        ]),
        BridgeTypeRef(CoreTypes.sink, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
        ]),
      ],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'onListen',
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
              'onPause',
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
              'onResume',
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
              'onCancel',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.object, [
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
                      ]),
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
              'sync',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
            ),
          ],
          params: [],
        ),
        isFactory: true,
      ),

      'broadcast': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'onListen',
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
              'onCancel',
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
              'sync',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
            ),
          ],
          params: [],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'addStream': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
            ]),
          ),
          namedParams: [
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
              'source',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.stream, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                ]),
              ),
              false,
            ),
          ],
        ),
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
      ),

      'add': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'event',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),
          ],
        ),
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
      ),
    },
    getters: {
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
      ),

      'stream': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'sink': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(AsyncTypes.streamSink, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'isClosed': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isPaused': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'hasListener': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {
      'onListen': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef.genericFunction(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
              params: [],
              namedParams: [],
            ),
          ),
          nullable: true,
        ),
        isStatic: false,
      ),

      'onPause': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef.genericFunction(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
              params: [],
              namedParams: [],
            ),
          ),
          nullable: true,
        ),
        isStatic: false,
      ),

      'onResume': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef.genericFunction(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
              params: [],
              namedParams: [],
            ),
          ),
          nullable: true,
        ),
        isStatic: false,
      ),

      'onCancel': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef.genericFunction(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
                ]),
              ),
              params: [],
              namedParams: [],
            ),
          ),
          nullable: true,
        ),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [StreamController.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;

    return $StreamController.wrap(
      StreamController(
        onListen:
            (r is $Value ? r : null) == null ||
                (r is $Value ? r : null) is $null
            ? null
            : () {
                ((r is $Value ? r : null)! as EvalCallable?)?.call(
                  runtime,
                  null,
                  null,
                  null,
                  0,
                );
              },
        onPause:
            (s is $Value ? s : null) == null ||
                (s is $Value ? s : null) is $null
            ? null
            : () {
                ((s is $Value ? s : null)! as EvalCallable?)?.call(
                  runtime,
                  null,
                  null,
                  null,
                  0,
                );
              },
        onResume: _arg2OrNull == null || _arg2OrNull is $null
            ? null
            : () {
                (_arg2OrNull! as EvalCallable?)?.call(
                  runtime,
                  null,
                  null,
                  null,
                  0,
                );
              },
        onCancel: _arg3OrNull == null || _arg3OrNull is $null
            ? null
            : () {
                return (_arg3OrNull! as EvalCallable?)
                    ?.call(runtime, null, null, null, 0)
                    ?.$value;
              },
        sync: _arg4OrNull == null ? false : (_arg4OrNull as $bool).$value,
      ),
    );
  }

  /// Wrapper for the [StreamController.broadcast] constructor
  static $Value? $broadcast(Runtime runtime, Object? r, Object? s, Object? c) {
    return $StreamController.wrap(
      StreamController.broadcast(
        onListen:
            (r is $Value ? r : null) == null ||
                (r is $Value ? r : null) is $null
            ? null
            : () {
                ((r is $Value ? r : null)! as EvalCallable?)?.call(
                  runtime,
                  null,
                  null,
                  null,
                  0,
                );
              },
        onCancel:
            (s is $Value ? s : null) == null ||
                (s is $Value ? s : null) is $null
            ? null
            : () {
                ((s is $Value ? s : null)! as EvalCallable?)?.call(
                  runtime,
                  null,
                  null,
                  null,
                  0,
                );
              },
        sync: (c is $Value ? c : null) == null ? false : (c as $bool).$value,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final StreamController<T> $value;

  @override
  StreamController get $reified => $value;

  /// Wrap a [StreamController] in a [$StreamController]
  $StreamController.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'done':
        final _done = $value.done;
        return $Future.wrap(
          _done.then((e) => runtime.wrapAlways(e, recursive: true)),
        );
      case 'stream':
        final _stream = $value.stream;
        return $Stream.wrap(
          _stream.map((e) => runtime.wrapAlways(e, recursive: true)),
        );
      case 'onListen':
        final _onListen = $value.onListen;
        return _onListen == null
            ? const $null()
            : $Function((runtime, target, r, s, c) {
                _onListen();
                return const $null();
              });
      case 'onPause':
        final _onPause = $value.onPause;
        return _onPause == null
            ? const $null()
            : $Function((runtime, target, r, s, c) {
                _onPause();
                return const $null();
              });
      case 'onResume':
        final _onResume = $value.onResume;
        return _onResume == null
            ? const $null()
            : $Function((runtime, target, r, s, c) {
                _onResume();
                return const $null();
              });
      case 'onCancel':
        final _onCancel = $value.onCancel;
        return _onCancel == null
            ? const $null()
            : $Function((runtime, target, r, s, c) {
                final funcResult = _onCancel();
                return (funcResult is Future
                    ? $Future.wrap(funcResult)
                    : const $null());
              });
      case 'sink':
        final _sink = $value.sink;
        return $StreamSink.wrap(_sink);
      case 'isClosed':
        final _isClosed = $value.isClosed;
        return $bool(_isClosed);
      case 'isPaused':
        final _isPaused = $value.isPaused;
        return $bool(_isPaused);
      case 'hasListener':
        final _hasListener = $value.hasListener;
        return $bool(_hasListener);
      case 'addStream':
        return __addStream;

      case 'close':
        return __close;

      case 'add':
        return __add;

      case 'addError':
        return __addError;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __addStream = $Function(_addStream);
  static $Value? _addStream(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamController;
    final result = self.$value.addStream(
      (r as $Value?)!.$value,
      cancelOnError: (s is $Value ? s : null)?.$value,
    );
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $StreamController;
    final result = self.$value.close();
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
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
    final self = target! as $StreamController;
    self.$value.add((r as $Value?)!.$value);
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
    final self = target! as $StreamController;
    self.$value.addError(
      (r as $Value?)!.$reified,
      (s is $Value ? s : null)?.$value,
    );
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      case 'onListen':
        $value.onListen = value.$reified;
        return;
      case 'onPause':
        $value.onPause = value.$reified;
        return;
      case 'onResume':
        $value.onResume = value.$reified;
        return;
      case 'onCancel':
        $value.onCancel = value.$reified;
        return;
    }
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
