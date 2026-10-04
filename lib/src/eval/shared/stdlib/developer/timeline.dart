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

import 'timeline_hooks.dart' as hooks;

/// dart_eval wrapper binding for [Flow]
class $Flow implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:developer',
      'Flow.begin',
      $Flow.$begin,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:developer',
      'Flow.step',
      $Flow.$step,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:developer',
      'Flow.end',
      $Flow.$end,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Flow]
  static const $spec = BridgeTypeSpec('dart:developer', 'Flow');

  /// Compile-time type declaration of [$Flow]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Flow]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {},

    methods: {
      'begin': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(DeveloperTypes.flow, [])),
          namedParams: [
            BridgeParameter(
              'id',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [],
        ),

        isStatic: true,
      ),

      'step': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(DeveloperTypes.flow, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'id',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'end': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(DeveloperTypes.flow, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'id',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),
    },
    getters: {},
    setters: {},
    fields: {
      'id': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Flow.begin] method
  static $Value? $begin(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Flow.begin(id: (r is $Value ? r : null)?.$value);
    return $Flow.wrap(value);
  }

  /// Wrapper for the [Flow.step] method
  static $Value? $step(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Flow.step((r as $int).$value);
    return $Flow.wrap(value);
  }

  /// Wrapper for the [Flow.end] method
  static $Value? $end(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Flow.end((r as $int).$value);
    return $Flow.wrap(value);
  }

  final $Instance _superclass;

  @override
  final Flow $value;

  @override
  Flow get $reified => $value;

  /// Wrap a [Flow] in a [$Flow]
  $Flow.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'id':
        final _id = $value.id;
        return $int(_id);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [Timeline]
class $Timeline implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:developer',
      'Timeline.startSync',
      $Timeline.$startSync,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:developer',
      'Timeline.finishSync',
      $Timeline.$finishSync,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:developer',
      'Timeline.instantSync',
      $Timeline.$instantSync,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:developer',
      'Timeline.timeSync',
      $Timeline.$timeSync,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:developer',
      'Timeline.now*g',
      $Timeline.$now,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Timeline]
  static const $spec = BridgeTypeSpec('dart:developer', 'Timeline');

  /// Compile-time type declaration of [$Timeline]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Timeline]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
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
      'startSync': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [
            BridgeParameter(
              'arguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'flow',
              BridgeTypeAnnotation(
                BridgeTypeRef(DeveloperTypes.flow, []),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'finishSync': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'instantSync': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [
            BridgeParameter(
              'arguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'timeSync': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
          namedParams: [
            BridgeParameter(
              'arguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'flow',
              BridgeTypeAnnotation(
                BridgeTypeRef(DeveloperTypes.flow, []),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),

            BridgeParameter(
              'function',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                    params: [],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),
    },
    getters: {
      'now': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Timeline.startSync] method
  static $Value? $startSync(Runtime runtime, Object? r, Object? s, Object? c) {
    Timeline.startSync(
      (r as $String).$value,
      arguments: ((s is $Value ? s : null)?.$reified as Map?)
          ?.cast<dynamic, dynamic>(),
      flow: (c is $Value ? c : null)?.$value,
    );
    return null;
  }

  /// Wrapper for the [Timeline.finishSync] method
  static $Value? $finishSync(Runtime runtime, Object? r, Object? s, Object? c) {
    Timeline.finishSync();
    return null;
  }

  /// Wrapper for the [Timeline.instantSync] method
  static $Value? $instantSync(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    Timeline.instantSync(
      (r as $String).$value,
      arguments: ((s is $Value ? s : null)?.$reified as Map?)
          ?.cast<dynamic, dynamic>(),
    );
    return null;
  }

  /// Wrapper for the [Timeline.timeSync] method
  static $Value? $timeSync(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;

    return hooks.guestTimelineTimeSync(runtime, null, [
      r as $Value?,
      s as $Value?,
      ...(c is List ? (c as List).cast<$Value?>().take(2) : const <$Value?>[]),
    ]);
  }

  /// Wrapper for the [Timeline.now] getter
  static $Value? $now(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Timeline.now;
    return $int(value);
  }

  final $Instance _superclass;

  @override
  final Timeline $value;

  @override
  Timeline get $reified => $value;

  /// Wrap a [Timeline] in a [$Timeline]
  $Timeline.wrap(this.$value) : _superclass = $Object($value);

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
