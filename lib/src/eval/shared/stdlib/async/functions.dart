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
        $EventSink,
        $StreamIterator,
        $StreamTransformer,
        $StreamTransformerBase,
        $StreamView,
        $StreamController;

import '../core/stack_trace.dart';

/// dart_eval function wrapper binding for [unawaited]
class $unawaitedFn {
  const $unawaitedFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:async',
      'unawaited',
      $unawaitedFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:async',
    'unawaited',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
      namedParams: [],
      params: [
        BridgeParameter(
          'future',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            ]),
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
    unawaited((r as $Value?)!.$value);
    return null;
  }
}

/// dart_eval function wrapper binding for [runZoned]
class $runZonedFn {
  const $runZonedFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:async',
      'runZoned',
      $runZonedFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:async',
    'runZoned',
    BridgeFunctionDef(
      generics: {'R': BridgeGenericParam()},
      returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
      namedParams: [
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

        BridgeParameter(
          'zoneSpecification',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.object, []),
            nullable: true,
          ),
          true,
        ),

        BridgeParameter(
          'onError',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.object, []),
            nullable: true,
          ),
          true,
        ),
      ],
      params: [
        BridgeParameter(
          'body',
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
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;

    final result = runZoned(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "R Function();export=false",
        (_callable) => () {
          return _callable.call(runtime, null, null, null, 0)?.$value;
        },
      ),
      zoneValues: ((s is $Value ? s : null)?.$reified as Map?)
          ?.cast<Object?, Object?>(),
      zoneSpecification: _arg2OrNull?.$value,
      onError: _arg3OrNull == null || _arg3OrNull is $null
          ? null
          : runtime.cachedCallback(
              _arg3OrNull! as EvalCallable,
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
    );
    return runtime.wrapAlways(result, recursive: true);
  }
}

/// dart_eval function wrapper binding for [runZonedGuarded]
class $runZonedGuardedFn {
  const $runZonedGuardedFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:async',
      'runZonedGuarded',
      $runZonedGuardedFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:async',
    'runZonedGuarded',
    BridgeFunctionDef(
      generics: {'R': BridgeGenericParam()},
      returns: BridgeTypeAnnotation(BridgeTypeRef.ref('R'), nullable: true),
      namedParams: [
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

        BridgeParameter(
          'zoneSpecification',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.object, []),
            nullable: true,
          ),
          true,
        ),
      ],
      params: [
        BridgeParameter(
          'body',
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

        BridgeParameter(
          'onError',
          BridgeTypeAnnotation(
            BridgeTypeRef.genericFunction(
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType),
                ),
                params: [
                  BridgeParameter(
                    'error',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
                    false,
                  ),

                  BridgeParameter(
                    'stack',
                    BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.stackTrace, []),
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
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;

    final result = runZonedGuarded(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "R Function();export=false",
        (_callable) => () {
          return _callable.call(runtime, null, null, null, 0)?.$value;
        },
      ),
      runtime.cachedCallback(
        (s as $Value?)! as EvalCallable,
        "void Function(Object, StackTrace);export=false",
        (_callable) => (Object error, StackTrace stack) {
          _callable.call(
            runtime,
            null,
            $Object(error),
            $StackTrace.wrap(stack),
            2,
          );
        },
      ),
      zoneValues: (_arg2OrNull?.$reified as Map?)?.cast<Object?, Object?>(),
      zoneSpecification: _arg3OrNull?.$value,
    );
    return result == null
        ? const $null()
        : runtime.wrapAlways(result, recursive: true);
  }
}
