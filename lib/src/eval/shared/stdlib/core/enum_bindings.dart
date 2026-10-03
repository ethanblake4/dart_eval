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

import 'package:dart_eval/stdlib/core.dart'
    hide
        $Duration,
        $DateTime,
        $Iterator,
        $Comparable,
        $Sink,
        $StackTrace,
        $StringBuffer,
        $Expando,
        $Symbol,
        $MapEntry,
        $Stopwatch,
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
        $Exception,
        $FormatException,
        $Uri,
        $Pattern,
        $Match,
        $RegExp,
        $RegExpMatch,
        $StringSink,
        $Enum;

import 'enum_hooks.dart' as hooks;

/// dart_eval wrapper binding for [Enum]
class $Enum implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Enum.compareByIndex',
      $Enum.$compareByIndex,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Enum.compareByName',
      $Enum.$compareByName,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Enum]
  static const $spec = BridgeTypeSpec('dart:core', 'Enum');

  /// Compile-time type declaration of [$Enum]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Enum]
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
      'compareByIndex': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {
            'T': BridgeGenericParam(
              $extends: BridgeTypeRef(CoreTypes.enumType, []),
            ),
          },
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'value1',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),

            BridgeParameter(
              'value2',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'compareByName': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {
            'T': BridgeGenericParam(
              $extends: BridgeTypeRef(CoreTypes.enumType, []),
            ),
          },
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'value1',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),

            BridgeParameter(
              'value2',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),
    },
    getters: {
      'index': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'name': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
        ),
      ),
      '_name': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Enum.compareByIndex] method
  static $Value? $compareByIndex(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return hooks.enumCompareByIndex(runtime, null, [
      r as $Value?,
      s as $Value?,
    ]);
  }

  /// Wrapper for the [Enum.compareByName] method
  static $Value? $compareByName(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return hooks.enumCompareByName(runtime, null, [r as $Value?, s as $Value?]);
  }

  final $Instance _superclass;

  @override
  final Enum $value;

  @override
  Enum get $reified => $value;

  /// Wrap a [Enum] in a [$Enum]
  $Enum.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'index':
        final _index = $value.index;
        return $int(_index);
      case 'name':
        return $String($value.name);
      case '_name':
        return $String($value.name);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
