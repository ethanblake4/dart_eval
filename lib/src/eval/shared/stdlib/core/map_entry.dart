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
import 'package:dart_eval/src/eval/runtime/runtime.dart';

/// dart_eval wrapper binding for [MapEntry]
class $MapEntry<K, V> implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'MapEntry.',
      $MapEntry.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$MapEntry]
  static const $spec = BridgeTypeSpec('dart:core', 'MapEntry');

  /// Compile-time type declaration of [$MapEntry]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$MapEntry]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      generics: {'K': BridgeGenericParam(), 'V': BridgeGenericParam()},
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'key',
              BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {},
    getters: {},
    setters: {},
    fields: {
      'key': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
        isStatic: false,
      ),

      'value': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef.ref('V')),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [MapEntry.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $MapEntry.wrap(
      MapEntry(
        TypedInterop.exportExternal((r as $Value?), runtime: runtime)
            as dynamic,
        TypedInterop.exportExternal((s as $Value?), runtime: runtime)
            as dynamic,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final MapEntry<K, V> $value;

  @override
  MapEntry<K, V> get $reified => $value;

  /// Wrap a [MapEntry] in a [$MapEntry]
  $MapEntry.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) {
    final data = Runtime.bridgeData[this];
    return data == null
        ? runtime.lookupType($spec)
        : runtime.importRuntimeType(data.runtime, data.$runtimeType);
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'key':
        final _key = $value.key;
        return (_key is List || _key is Map || _key is Set
            ? TypedInterop.boxExternal(_key, runtime: runtime)!
            : runtime.wrapAlways(_key));
      case 'value':
        final _value = $value.value;
        return (_value is List || _value is Map || _value is Set
            ? TypedInterop.boxExternal(_value, runtime: runtime)!
            : runtime.wrapAlways(_value));
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
