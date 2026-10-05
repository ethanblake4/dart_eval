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

import 'dart:developer';

import 'package:dart_eval/stdlib/core.dart' hide $Flow, $Timeline;
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

/// dart_eval function wrapper binding for [log]
class $logFn {
  const $logFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:developer',
      'log',
      $logFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:developer',
    'log',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
      namedParams: [
        BridgeParameter(
          'time',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.dateTime, []),
            nullable: true,
          ),
          true,
        ),

        BridgeParameter(
          'sequenceNumber',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.int, []),
            nullable: true,
          ),
          true,
        ),

        BridgeParameter(
          'level',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          true,
          defaultValueSource: "0",
        ),

        BridgeParameter(
          'name',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          true,
          defaultValueSource: "''",
        ),

        BridgeParameter(
          'zone',
          BridgeTypeAnnotation(
            BridgeTypeRef(AsyncTypes.zone, []),
            nullable: true,
          ),
          true,
        ),

        BridgeParameter(
          'error',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.object, []),
            nullable: true,
          ),
          true,
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
      params: [
        BridgeParameter(
          'message',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;
    final _arg5OrNull = c is List && c.length > 3 ? c[3] as $Value? : null;
    final _arg6OrNull = c is List && c.length > 4 ? c[4] as $Value? : null;
    final _arg7OrNull = c is List && c.length > 5 ? c[5] as $Value? : null;

    log(
      (r as $String).$value,
      time: (s is $Value ? s : null)?.$value,
      sequenceNumber: _arg2OrNull?.$value,
      level: _arg3OrNull == null ? 0 : (_arg3OrNull as $int).$value,
      name: _arg4OrNull == null ? '' : (_arg4OrNull as $String).$value,
      zone: _arg5OrNull?.$value,
      error:
          TypedInterop.exportExternal(_arg6OrNull, runtime: runtime) as Object?,
      stackTrace: _arg7OrNull?.$value,
    );
    return null;
  }
}

/// dart_eval function wrapper binding for [postEvent]
class $postEventFn {
  const $postEventFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:developer',
      'postEvent',
      $postEventFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:developer',
    'postEvent',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
      namedParams: [
        BridgeParameter(
          'stream',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          true,
          defaultValueSource: "'Extension'",
        ),
      ],
      params: [
        BridgeParameter(
          'eventKind',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          false,
        ),

        BridgeParameter(
          'eventData',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
            ]),
          ),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    postEvent(
      (r as $String).$value,
      ((s as $Value?)!.$reified as Map).cast<dynamic, dynamic>(),
      stream: (c is $Value ? c : null) == null
          ? 'Extension'
          : (c as $String).$value,
    );
    return null;
  }
}
