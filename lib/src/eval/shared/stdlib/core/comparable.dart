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
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

/// dart_eval wrapper binding for [Comparable]
class $Comparable<T> implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Comparable.compare',
      $Comparable.$compare,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Comparable]
  static const $spec = BridgeTypeSpec('dart:core', 'Comparable');

  /// Compile-time type declaration of [$Comparable]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Comparable]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      generics: {'T': BridgeGenericParam()},
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
      'compareTo': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'compare': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'a',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.comparable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
              ),
              false,
            ),

            BridgeParameter(
              'b',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.comparable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
              ),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Comparable.compare] method
  static $Value? $compare(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Comparable.compare(
      (r as $Value?)!.$value,
      (s as $Value?)!.$value,
    );
    return $int(value);
  }

  final $Instance _superclass;

  @override
  final Comparable<T> $value;

  @override
  Comparable<T> get $reified => $value;

  /// Wrap a [Comparable] in a [$Comparable]
  $Comparable.wrap(this.$value) : _superclass = $Object($value);

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
      case 'compareTo':
        return $Closure(__compareTo.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __compareTo = $Function(_compareTo);
  static $Value? _compareTo(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Comparable;
    final result = self.$value.compareTo(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as dynamic,
    );
    return $int(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
