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
        $Symbol,
        $MapEntry,
        $Stopwatch,
        $Error,
        $TypeError,
        $NoSuchMethodError,
        $RangeError,
        $AssertionError,
        $ArgumentError,
        $StateError,
        $UnsupportedError,
        $UnimplementedError,
        $Invocation,
        $Exception,
        $FormatException,
        $Uri,
        $Pattern,
        $Match,
        $RegExp,
        $RegExpMatch,
        $StringSink;

/// dart_eval wrapper binding for [StringBuffer]
class $StringBuffer implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'StringBuffer.',
      $StringBuffer.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$StringBuffer]
  static const $spec = BridgeTypeSpec('dart:core', 'StringBuffer');

  /// Compile-time type declaration of [$StringBuffer]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$StringBuffer]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [BridgeTypeRef(CoreTypes.stringSink, [])],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'content',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {
      'write': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
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
      ),

      'writeAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'objects',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
              ),
              false,
            ),

            BridgeParameter(
              'separator',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
            ),
          ],
        ),
      ),

      'writeln': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'obj',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'writeCharCode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'charCode',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'clear': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),
      ),
    },
    getters: {
      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isEmpty': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isNotEmpty': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [StringBuffer.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $StringBuffer.wrap(
      StringBuffer(
        (r is $Value ? r : null) == null
            ? ""
            : (r is $Value ? r : null)?.$reified,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final StringBuffer $value;

  @override
  StringBuffer get $reified => $value;

  /// Wrap a [StringBuffer] in a [$StringBuffer]
  $StringBuffer.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'length':
        final _length = $value.length;
        return $int(_length);
      case 'isEmpty':
        final _isEmpty = $value.isEmpty;
        return $bool(_isEmpty);
      case 'isNotEmpty':
        final _isNotEmpty = $value.isNotEmpty;
        return $bool(_isNotEmpty);
      case 'write':
        return __write;

      case 'writeAll':
        return __writeAll;

      case 'writeln':
        return __writeln;

      case 'writeCharCode':
        return __writeCharCode;

      case 'clear':
        return __clear;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __write = $Function(_write);
  static $Value? _write(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringBuffer;
    self.$value.write((r as $Value?)!.$reified);
    return null;
  }

  static const $Function __writeAll = $Function(_writeAll);
  static $Value? _writeAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringBuffer;
    self.$value.writeAll(
      (r as $Value?)!.$value,
      (s is $Value ? s : null) == null ? "" : (s as $String).$value,
    );
    return null;
  }

  static const $Function __writeln = $Function(_writeln);
  static $Value? _writeln(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringBuffer;
    self.$value.writeln(
      (r is $Value ? r : null) == null
          ? ""
          : (r is $Value ? r : null)?.$reified,
    );
    return null;
  }

  static const $Function __writeCharCode = $Function(_writeCharCode);
  static $Value? _writeCharCode(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringBuffer;
    self.$value.writeCharCode((r as $int).$value);
    return null;
  }

  static const $Function __clear = $Function(_clear);
  static $Value? _clear(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringBuffer;
    self.$value.clear();
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
