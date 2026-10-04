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

import 'package:dart_eval/stdlib/core.dart'
    hide
        $Isolate,
        $RawReceivePort,
        $SendPort,
        $Capability,
        $RemoteError,
        $TransferableTypedData;

import './isolate.dart';
import 'isolate_hooks.dart' as hooks;

/// dart_eval wrapper binding for [RawReceivePort]
class $RawReceivePort implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:isolate',
      'RawReceivePort.',
      $RawReceivePort.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$RawReceivePort]
  static const $spec = BridgeTypeSpec('dart:isolate', 'RawReceivePort');

  /// Compile-time type declaration of [$RawReceivePort]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$RawReceivePort]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'handler',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'debugName',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
              defaultValueSource: "''",
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'close': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),
    },
    getters: {
      'sendPort': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(IsolateTypes.sendPort, []),
          ),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),
    },
    setters: {
      'handler': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'newHandler',
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
    fields: {
      'keepIsolateAlive': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [RawReceivePort.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return hooks.guestRawReceivePort(runtime, null, [
      r as $Value?,
      s as $Value?,
    ]);
  }

  final $Instance _superclass;

  @override
  final RawReceivePort $value;

  @override
  RawReceivePort get $reified => $value;

  /// Wrap a [RawReceivePort] in a [$RawReceivePort]
  $RawReceivePort.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'sendPort':
        final _sendPort = $value.sendPort;
        return $SendPort.wrap(_sendPort);
      case 'keepIsolateAlive':
        final _keepIsolateAlive = $value.keepIsolateAlive;
        return $bool(_keepIsolateAlive);
      case 'close':
        return $Closure(__close.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __close = $Function(_close);
  static $Value? _close(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $RawReceivePort;
    self.$value.close();
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      case 'handler':
        hooks.guestRawReceivePortHandler(runtime, this, value);
        return;
      case 'keepIsolateAlive':
        $value.keepIsolateAlive = value.$reified;
        return;
    }
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [SendPort]
class $SendPort implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {}

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$SendPort]
  static const $spec = BridgeTypeSpec('dart:isolate', 'SendPort');

  /// Compile-time type declaration of [$SendPort]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$SendPort]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      $implements: [BridgeTypeRef(IsolateTypes.capability, [])],
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
      'send': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'message',
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
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  final $Instance _superclass;

  @override
  final SendPort $value;

  @override
  SendPort get $reified => $value;

  /// Wrap a [SendPort] in a [$SendPort]
  $SendPort.wrap(this.$value) : _superclass = $Capability.wrap($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'send':
        return $Closure(__send.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __send = $Function(_send);
  static $Value? _send(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return hooks.guestSendPortSend(runtime, target, r, s, c);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
