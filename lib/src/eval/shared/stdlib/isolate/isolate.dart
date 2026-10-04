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

import 'dart:isolate';

import 'package:dart_eval/stdlib/async.dart'
    hide
        $Isolate,
        $RawReceivePort,
        $SendPort,
        $Capability,
        $RemoteError,
        $TransferableTypedData;
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../core/uri.dart';

import 'package:dart_eval/stdlib/core.dart'
    hide
        $Isolate,
        $RawReceivePort,
        $SendPort,
        $Capability,
        $RemoteError,
        $TransferableTypedData;

import './ports.dart';
import '../core/errors.dart';
import '../core/stack_trace.dart';

import 'dart:typed_data';

import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

import '../typed_data/typed_data.dart';
import 'isolate_hooks.dart' as hooks;

/// dart_eval wrapper binding for [Isolate]
class $Isolate implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:isolate',
      'Isolate.resolvePackageUri',
      $Isolate.$resolvePackageUri,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:isolate',
      'Isolate.resolvePackageUriSync',
      $Isolate.$resolvePackageUriSync,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:isolate',
      'Isolate.spawn',
      $Isolate.$spawn,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:isolate',
      'Isolate.exit',
      $Isolate.$exit,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:isolate',
      'Isolate.immediate*g',
      $Isolate.$immediate,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:isolate',
      'Isolate.beforeNextEvent*g',
      $Isolate.$beforeNextEvent,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:isolate',
      'Isolate.current*g',
      $Isolate.$current,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:isolate',
      'Isolate.packageConfig*g',
      $Isolate.$packageConfig,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:isolate',
      'Isolate.packageConfigSync*g',
      $Isolate.$packageConfigSync,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Isolate]
  static const $spec = BridgeTypeSpec('dart:isolate', 'Isolate');

  /// Compile-time type declaration of [$Isolate]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Isolate]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {},

    methods: {
      'resolvePackageUri': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.uri, []),
                nullable: true,
              ),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'packageUri',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'resolvePackageUriSync': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.uri, []),
            nullable: true,
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'packageUri',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'spawn': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(IsolateTypes.isolate, [])),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'paused',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
            ),

            BridgeParameter(
              'errorsAreFatal',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "true",
            ),

            BridgeParameter(
              'onExit',
              BridgeTypeAnnotation(
                BridgeTypeRef(IsolateTypes.sendPort, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'onError',
              BridgeTypeAnnotation(
                BridgeTypeRef(IsolateTypes.sendPort, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'debugName',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'entryPoint',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'message',
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
              'message',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'pause': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(IsolateTypes.capability, []),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'resumeCapability',
              BridgeTypeAnnotation(
                BridgeTypeRef(IsolateTypes.capability, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'resume': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'resumeCapability',
              BridgeTypeAnnotation(BridgeTypeRef(IsolateTypes.capability, [])),
              false,
            ),
          ],
        ),
      ),

      'addOnExitListener': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [
            BridgeParameter(
              'response',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'responsePort',
              BridgeTypeAnnotation(BridgeTypeRef(IsolateTypes.sendPort, [])),
              false,
            ),
          ],
        ),
      ),

      'removeOnExitListener': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'responsePort',
              BridgeTypeAnnotation(BridgeTypeRef(IsolateTypes.sendPort, [])),
              false,
            ),
          ],
        ),
      ),

      'setErrorsFatal': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'errorsAreFatal',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              false,
            ),
          ],
        ),
      ),

      'kill': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [
            BridgeParameter(
              'priority',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "beforeNextEvent",
            ),
          ],
          params: [],
        ),
      ),

      'ping': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [
            BridgeParameter(
              'response',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'priority',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "immediate",
            ),
          ],
          params: [
            BridgeParameter(
              'responsePort',
              BridgeTypeAnnotation(BridgeTypeRef(IsolateTypes.sendPort, [])),
              false,
            ),
          ],
        ),
      ),

      'addErrorListener': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'port',
              BridgeTypeAnnotation(BridgeTypeRef(IsolateTypes.sendPort, [])),
              false,
            ),
          ],
        ),
      ),

      'removeErrorListener': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'port',
              BridgeTypeAnnotation(BridgeTypeRef(IsolateTypes.sendPort, [])),
              false,
            ),
          ],
        ),
      ),

      'exit': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.never)),
          namedParams: [],
          params: [
            BridgeParameter(
              'finalMessagePort',
              BridgeTypeAnnotation(
                BridgeTypeRef(IsolateTypes.sendPort, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'message',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),

        isStatic: true,
      ),
    },
    getters: {
      'debugName': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.string, []),
            nullable: true,
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'current': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(IsolateTypes.isolate, []),
          ),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'packageConfig': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.uri, []),
                nullable: true,
              ),
            ]),
          ),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'packageConfigSync': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.uri, []),
            nullable: true,
          ),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'errors': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'isPinnedToCurrentThread': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {
      'onEvent': BridgeMethodDef(
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
                    params: [
                      BridgeParameter(
                        'null',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(IsolateTypes.isolate, []),
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
    },
    fields: {
      'immediate': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'beforeNextEvent': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'controlPort': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(IsolateTypes.sendPort, [])),
        isStatic: false,
      ),

      'pauseCapability': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(IsolateTypes.capability, []),
          nullable: true,
        ),
        isStatic: false,
      ),

      'terminateCapability': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(IsolateTypes.capability, []),
          nullable: true,
        ),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Isolate.resolvePackageUri] method
  static $Value? $resolvePackageUri(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Isolate.resolvePackageUri((r as $Value?)!.$value);
    return $Future.wrap(
      value.then((e) => e == null ? const $null() : $Uri.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.internParameterizedType(CoreTypes.uri, [], nullable: true),
      ]),
    );
  }

  /// Wrapper for the [Isolate.resolvePackageUriSync] method
  static $Value? $resolvePackageUriSync(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Isolate.resolvePackageUriSync((r as $Value?)!.$value);
    return value == null ? const $null() : $Uri.wrap(value);
  }

  /// Wrapper for the [Isolate.spawn] method
  static $Value? $spawn(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;
    final _arg5OrNull = c is List && c.length > 3 ? c[3] as $Value? : null;
    final _arg6OrNull = c is List && c.length > 4 ? c[4] as $Value? : null;

    return hooks.guestIsolateSpawn(runtime, null, [
      r as $Value?,
      s as $Value?,
      ...(c is List ? (c as List).cast<$Value?>().take(5) : const <$Value?>[]),
    ]);
  }

  /// Wrapper for the [Isolate.exit] method
  static $Value? $exit(Runtime runtime, Object? r, Object? s, Object? c) {
    return hooks.guestIsolateExit(runtime, null, [r as $Value?, s as $Value?]);
  }

  /// Wrapper for the [Isolate.immediate] getter
  static $Value? $immediate(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Isolate.immediate;
    return $int(value);
  }

  /// Wrapper for the [Isolate.beforeNextEvent] getter
  static $Value? $beforeNextEvent(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Isolate.beforeNextEvent;
    return $int(value);
  }

  /// Wrapper for the [Isolate.current] getter
  static $Value? $current(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Isolate.current;
    return $Isolate.wrap(value);
  }

  /// Wrapper for the [Isolate.packageConfig] getter
  static $Value? $packageConfig(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Isolate.packageConfig;
    return $Future.wrap(
      value.then((e) => e == null ? const $null() : $Uri.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.internParameterizedType(CoreTypes.uri, [], nullable: true),
      ]),
    );
  }

  /// Wrapper for the [Isolate.packageConfigSync] getter
  static $Value? $packageConfigSync(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Isolate.packageConfigSync;
    return value == null ? const $null() : $Uri.wrap(value);
  }

  final $Instance _superclass;

  @override
  final Isolate $value;

  @override
  Isolate get $reified => $value;

  /// Wrap a [Isolate] in a [$Isolate]
  $Isolate.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'controlPort':
        final _controlPort = $value.controlPort;
        return $SendPort.wrap(_controlPort);
      case 'pauseCapability':
        final _pauseCapability = $value.pauseCapability;
        return _pauseCapability == null
            ? const $null()
            : $Capability.wrap(_pauseCapability);
      case 'terminateCapability':
        final _terminateCapability = $value.terminateCapability;
        return _terminateCapability == null
            ? const $null()
            : $Capability.wrap(_terminateCapability);
      case 'debugName':
        final _debugName = $value.debugName;
        return _debugName == null ? const $null() : $String(_debugName);
      case 'errors':
        final _errors = $value.errors;
        return $Stream.wrap(
          _errors.map((e) => runtime.wrapAlways(e, recursive: true)),
          runtime: runtime,
          runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
            runtime.lookupType(CoreTypes.dynamic),
          ]),
        );
      case 'isPinnedToCurrentThread':
        final _isPinnedToCurrentThread = $value.isPinnedToCurrentThread;
        return $bool(_isPinnedToCurrentThread);
      case 'pause':
        return $Closure(__pause.func, this);

      case 'resume':
        return $Closure(__resume.func, this);

      case 'addOnExitListener':
        return $Closure(__addOnExitListener.func, this);

      case 'removeOnExitListener':
        return $Closure(__removeOnExitListener.func, this);

      case 'setErrorsFatal':
        return $Closure(__setErrorsFatal.func, this);

      case 'kill':
        return $Closure(__kill.func, this);

      case 'ping':
        return $Closure(__ping.func, this);

      case 'addErrorListener':
        return $Closure(__addErrorListener.func, this);

      case 'removeErrorListener':
        return $Closure(__removeErrorListener.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __pause = $Function(_pause);
  static $Value? _pause(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Isolate;
    final result = self.$value.pause((r is $Value ? r : null)?.$value);
    return $Capability.wrap(result);
  }

  static const $Function __resume = $Function(_resume);
  static $Value? _resume(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Isolate;
    self.$value.resume((r as $Value?)!.$value);
    return null;
  }

  static const $Function __addOnExitListener = $Function(_addOnExitListener);
  static $Value? _addOnExitListener(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return hooks.guestIsolateAddOnExitListener(runtime, target, r, s, c);
  }

  static const $Function __removeOnExitListener = $Function(
    _removeOnExitListener,
  );
  static $Value? _removeOnExitListener(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Isolate;
    self.$value.removeOnExitListener((r as $Value?)!.$value);
    return null;
  }

  static const $Function __setErrorsFatal = $Function(_setErrorsFatal);
  static $Value? _setErrorsFatal(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Isolate;
    self.$value.setErrorsFatal((r as $bool).$value);
    return null;
  }

  static const $Function __kill = $Function(_kill);
  static $Value? _kill(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Isolate;
    self.$value.kill(
      priority: (r is $Value ? r : null) == null
          ? Isolate.beforeNextEvent
          : (r as $int).$value,
    );
    return null;
  }

  static const $Function __ping = $Function(_ping);
  static $Value? _ping(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return hooks.guestIsolatePing(runtime, target, r, s, c);
  }

  static const $Function __addErrorListener = $Function(_addErrorListener);
  static $Value? _addErrorListener(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Isolate;
    self.$value.addErrorListener((r as $Value?)!.$value);
    return null;
  }

  static const $Function __removeErrorListener = $Function(
    _removeErrorListener,
  );
  static $Value? _removeErrorListener(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Isolate;
    self.$value.removeErrorListener((r as $Value?)!.$value);
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      case 'onEvent':
        $value.onEvent = value.$reified;
        return;
    }
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [Capability]
class $Capability implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:isolate',
      'Capability.',
      $Capability.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Capability]
  static const $spec = BridgeTypeSpec('dart:isolate', 'Capability');

  /// Compile-time type declaration of [$Capability]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Capability]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: true,
      ),
    },

    methods: {},
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Capability.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Capability.wrap(Capability());
  }

  final $Instance _superclass;

  @override
  final Capability $value;

  @override
  Capability get $reified => $value;

  /// Wrap a [Capability] in a [$Capability]
  $Capability.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [RemoteError]
class $RemoteError implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:isolate',
      'RemoteError.',
      $RemoteError.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$RemoteError]
  static const $spec = BridgeTypeSpec('dart:isolate', 'RemoteError');

  /// Compile-time type declaration of [$RemoteError]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$RemoteError]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, $implements: [BridgeTypeRef(CoreTypes.error, [])]),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'description',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),

            BridgeParameter(
              'stackDescription',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {},
    getters: {},
    setters: {},
    fields: {
      'stackTrace': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stackTrace, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [RemoteError.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $RemoteError.wrap(
      RemoteError((r as $String).$value, (s as $String).$value),
    );
  }

  final $Instance _superclass;

  @override
  final RemoteError $value;

  @override
  RemoteError get $reified => $value;

  /// Wrap a [RemoteError] in a [$RemoteError]
  $RemoteError.wrap(this.$value) : _superclass = $Error.wrap($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'stackTrace':
        final _stackTrace = $value.stackTrace;
        return $StackTrace.wrap(_stackTrace);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [TransferableTypedData]
class $TransferableTypedData implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:isolate',
      'TransferableTypedData.fromList',
      $TransferableTypedData.$fromList,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$TransferableTypedData]
  static const $spec = BridgeTypeSpec('dart:isolate', 'TransferableTypedData');

  /// Compile-time type declaration of [$TransferableTypedData]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$TransferableTypedData]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      'fromList': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'list',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(TypedDataTypes.typedData, []),
                  ),
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
      'materialize': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(TypedDataTypes.byteBuffer, []),
          ),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [TransferableTypedData.fromList] constructor
  static $Value? $fromList(Runtime runtime, Object? r, Object? s, Object? c) {
    return $TransferableTypedData.wrap(
      TransferableTypedData.fromList(
        (TypedInterop.exportExternal((r as $Value?), runtime: runtime) as List)
            .cast<TypedData>(),
      ),
    );
  }

  final $Instance _superclass;

  @override
  final TransferableTypedData $value;

  @override
  TransferableTypedData get $reified => $value;

  /// Wrap a [TransferableTypedData] in a [$TransferableTypedData]
  $TransferableTypedData.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'materialize':
        return $Closure(__materialize.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __materialize = $Function(_materialize);
  static $Value? _materialize(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $TransferableTypedData;
    final result = self.$value.materialize();
    return $ByteBuffer.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
