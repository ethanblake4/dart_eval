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

import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart'
    hide
        $Duration,
        $BigInt,
        $DateTime,
        $Iterator,
        $Comparable,
        $Sink,
        $StackTrace,
        $StringBuffer,
        $Runes,
        $RuneIterator,
        $Expando,
        $Symbol,
        $MapEntry,
        $Stopwatch,
        $pragma,
        $Error,
        $StackOverflowError,
        $OutOfMemoryError,
        $TypeError,
        $NoSuchMethodError,
        $RangeError,
        $AssertionError,
        $ArgumentError,
        $StateError,
        $UnsupportedError,
        $UnimplementedError,
        $ConcurrentModificationError,
        $Exception,
        $FormatException,
        $Uri,
        $Pattern,
        $Match,
        $RegExp,
        $RegExpMatch,
        $StringSink,
        $Enum;

/// dart_eval function wrapper binding for [identityHashCode]
class $identityHashCodeFn {
  const $identityHashCodeFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:core',
      'identityHashCode',
      $identityHashCodeFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:core',
    'identityHashCode',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
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
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = identityHashCode(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
    );
    return $int(result);
  }
}
