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
import 'stack_trace.dart';
import 'symbol.dart';
import 'package:dart_eval/src/eval/utils/wrap_helper.dart';

/// dart_eval wrapper binding for [Error]
class $Error implements Error, $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:core', 'Error.', $Error.$new);

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Error.safeToString',
      $Error.$safeToString,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Error.throwWithStackTrace',
      $Error.$throwWithStackTrace,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Error]
  static const $spec = BridgeTypeSpec('dart:core', 'Error');

  /// Compile-time type declaration of [$Error]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Error]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type),
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
      'safeToString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
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

        isStatic: true,
      ),

      'throwWithStackTrace': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.never)),
          namedParams: [],
          params: [
            BridgeParameter(
              'error',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              false,
            ),

            BridgeParameter(
              'stackTrace',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stackTrace, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),
    },
    getters: {
      'stackTrace': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stackTrace, []),
            nullable: true,
          ),
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

  /// Wrapper for the [Error.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Error.wrap(Error());
  }

  /// Wrapper for the [Error.safeToString] method
  static $Value? $safeToString(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Error.safeToString((r as $Value?)!.$reified);
    return $String(value);
  }

  /// Wrapper for the [Error.throwWithStackTrace] method
  static $Value? $throwWithStackTrace(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Error.throwWithStackTrace(
      (r as $Value?)!.$reified,
      (s as $Value?)!.$value,
    );
    return const $null();
  }

  final $Instance _superclass;

  @override
  final Error $value;

  @override
  Error get $reified => $value;

  /// Wrap a [Error] in a [$Error]
  $Error.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'stackTrace':
        final _stackTrace = $value.stackTrace;
        return _stackTrace == null
            ? const $null()
            : $StackTrace.wrap(_stackTrace);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  StackTrace? get stackTrace => $value.stackTrace;
}

/// dart_eval wrapper binding for [AssertionError]
class $AssertionError implements AssertionError, $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'AssertionError.',
      $AssertionError.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$AssertionError]
  static const $spec = BridgeTypeSpec('dart:core', 'AssertionError');

  /// Compile-time type declaration of [$AssertionError]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$AssertionError]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, $implements: [BridgeTypeRef(CoreTypes.error, [])]),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
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
        isFactory: false,
      ),
    },

    methods: {},
    getters: {
      'stackTrace': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stackTrace, []),
            nullable: true,
          ),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {
      'message': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.object, []),
          nullable: true,
        ),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [AssertionError.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $AssertionError.wrap(
      AssertionError((r is $Value ? r : null)?.$reified),
    );
  }

  final $Instance _superclass;

  @override
  final AssertionError $value;

  @override
  AssertionError get $reified => $value;

  /// Wrap a [AssertionError] in a [$AssertionError]
  $AssertionError.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'stackTrace':
        final _stackTrace = $value.stackTrace;
        return _stackTrace == null
            ? const $null()
            : $StackTrace.wrap(_stackTrace);
      case 'message':
        final _message = $value.message;
        return _message == null ? const $null() : $Object(_message);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  Object? get message => $value.message;

  @override
  StackTrace? get stackTrace => $value.stackTrace;

  @override
  String toString() => $value.toString();
}

/// dart_eval wrapper binding for [TypeError]
class $TypeError implements TypeError, $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'TypeError.',
      $TypeError.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$TypeError]
  static const $spec = BridgeTypeSpec('dart:core', 'TypeError');

  /// Compile-time type declaration of [$TypeError]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$TypeError]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, $implements: [BridgeTypeRef(CoreTypes.error, [])]),
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

    methods: {},
    getters: {
      'stackTrace': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stackTrace, []),
            nullable: true,
          ),
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

  /// Wrapper for the [TypeError.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $TypeError.wrap(TypeError());
  }

  final $Instance _superclass;

  @override
  final TypeError $value;

  @override
  TypeError get $reified => $value;

  /// Wrap a [TypeError] in a [$TypeError]
  $TypeError.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'stackTrace':
        final _stackTrace = $value.stackTrace;
        return _stackTrace == null
            ? const $null()
            : $StackTrace.wrap(_stackTrace);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  StackTrace? get stackTrace => $value.stackTrace;
}

/// dart_eval wrapper binding for [ArgumentError]
class $ArgumentError implements ArgumentError, $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'ArgumentError.',
      $ArgumentError.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'ArgumentError.value',
      $ArgumentError.$_value,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'ArgumentError.notNull',
      $ArgumentError.$notNull,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'ArgumentError.checkNotNull',
      $ArgumentError.$checkNotNull,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$ArgumentError]
  static const $spec = BridgeTypeSpec('dart:core', 'ArgumentError');

  /// Compile-time type declaration of [$ArgumentError]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ArgumentError]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, $implements: [BridgeTypeRef(CoreTypes.error, [])]),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'message',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              true,
            ),

            BridgeParameter(
              'name',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: false,
      ),

      'value': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              false,
            ),

            BridgeParameter(
              'name',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'message',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              true,
            ),
          ],
        ),
        isFactory: false,
      ),

      'notNull': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {
      'checkNotNull': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
          namedParams: [],
          params: [
            BridgeParameter(
              'argument',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T'), nullable: true),
              false,
            ),

            BridgeParameter(
              'name',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
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
      'stackTrace': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stackTrace, []),
            nullable: true,
          ),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {
      'invalidValue': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
        isStatic: false,
      ),

      'name': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.string, []),
          nullable: true,
        ),
        isStatic: false,
      ),

      'message': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [ArgumentError.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $ArgumentError.wrap(
      ArgumentError(
        (r is $Value ? r : null)?.$reified,
        (s is $Value ? s : null)?.$value,
      ),
    );
  }

  /// Wrapper for the [ArgumentError.value] constructor
  static $Value? $_value(Runtime runtime, Object? r, Object? s, Object? c) {
    return $ArgumentError.wrap(
      ArgumentError.value(
        (r as $Value?)!.$reified,
        (s is $Value ? s : null)?.$value,
        (c is $Value ? c : null)?.$reified,
      ),
    );
  }

  /// Wrapper for the [ArgumentError.notNull] constructor
  static $Value? $notNull(Runtime runtime, Object? r, Object? s, Object? c) {
    return $ArgumentError.wrap(
      ArgumentError.notNull((r is $Value ? r : null)?.$value),
    );
  }

  /// Wrapper for the [ArgumentError.checkNotNull] method
  static $Value? $checkNotNull(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = ArgumentError.checkNotNull(
      (r as $Value?)!.$value,
      (s is $Value ? s : null)?.$value,
    );
    return runtime.wrapAlways(value, recursive: true);
  }

  final $Instance _superclass;

  @override
  final ArgumentError $value;

  @override
  ArgumentError get $reified => $value;

  /// Wrap a [ArgumentError] in a [$ArgumentError]
  $ArgumentError.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'stackTrace':
        final _stackTrace = $value.stackTrace;
        return _stackTrace == null
            ? const $null()
            : $StackTrace.wrap(_stackTrace);
      case 'invalidValue':
        final _invalidValue = $value.invalidValue;
        return runtime.wrapAlways(_invalidValue, recursive: true);
      case 'name':
        final _name = $value.name;
        return _name == null ? const $null() : $String(_name);
      case 'message':
        final _message = $value.message;
        return runtime.wrapAlways(_message, recursive: true);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  dynamic get invalidValue => $value.invalidValue;

  @override
  String? get name => $value.name;

  @override
  dynamic get message => $value.message;

  @override
  StackTrace? get stackTrace => $value.stackTrace;

  @override
  String toString() => $value.toString();
}

/// dart_eval wrapper binding for [RangeError]
class $RangeError implements RangeError, $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'RangeError.',
      $RangeError.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'RangeError.value',
      $RangeError.$_value,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'RangeError.range',
      $RangeError.$range,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'RangeError.index',
      $RangeError.$index,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'RangeError.checkValueInInterval',
      $RangeError.$checkValueInInterval,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'RangeError.checkValidIndex',
      $RangeError.$checkValidIndex,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'RangeError.checkValidRange',
      $RangeError.$checkValidRange,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'RangeError.checkNotNegative',
      $RangeError.$checkNotNegative,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$RangeError]
  static const $spec = BridgeTypeSpec('dart:core', 'RangeError');

  /// Compile-time type declaration of [$RangeError]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$RangeError]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(CoreTypes.argumentError, []),
        BridgeTypeRef(CoreTypes.error, []),
      ],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'message',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),

      'value': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
              false,
            ),

            BridgeParameter(
              'name',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'message',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: false,
      ),

      'range': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'invalidValue',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
              false,
            ),

            BridgeParameter(
              'minValue',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              false,
            ),

            BridgeParameter(
              'maxValue',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              false,
            ),

            BridgeParameter(
              'name',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'message',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: false,
      ),

      'index': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'indexable',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              false,
            ),

            BridgeParameter(
              'name',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'message',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'checkValueInInterval': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'minValue',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'maxValue',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'name',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'message',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),

        isStatic: true,
      ),

      'checkValidIndex': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'indexable',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              false,
            ),

            BridgeParameter(
              'name',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'message',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),

        isStatic: true,
      ),

      'checkValidRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              false,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'startName',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'endName',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'message',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),

        isStatic: true,
      ),

      'checkNotNegative': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'name',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'message',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
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
      'invalidValue': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.num, []),
            nullable: true,
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'stackTrace': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stackTrace, []),
            nullable: true,
          ),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {
      'name': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.string, []),
          nullable: true,
        ),
        isStatic: false,
      ),

      'message': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
        isStatic: false,
      ),

      'start': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, []), nullable: true),
        isStatic: false,
      ),

      'end': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, []), nullable: true),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [RangeError.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $RangeError.wrap(RangeError((r as $Value?)!.$reified));
  }

  /// Wrapper for the [RangeError.value] constructor
  static $Value? $_value(Runtime runtime, Object? r, Object? s, Object? c) {
    return $RangeError.wrap(
      RangeError.value(
        (r as $num).$value,
        (s is $Value ? s : null)?.$value,
        (c is $Value ? c : null)?.$value,
      ),
    );
  }

  /// Wrapper for the [RangeError.range] constructor
  static $Value? $range(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2 = (c as List<Object?>)[0] as $Value?;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;

    return $RangeError.wrap(
      RangeError.range(
        (r as $num).$value,
        (s as $Value?)!.$value,
        _arg2!.$value,
        _arg3OrNull?.$value,
        _arg4OrNull?.$value,
      ),
    );
  }

  /// Wrapper for the [RangeError.index] constructor
  static $Value? $index(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;

    return $RangeError.wrap(
      RangeError.index(
        (r as $int).$value,
        (s as $Value?)!.$reified,
        _arg2OrNull?.$value,
        _arg3OrNull?.$value,
        _arg4OrNull?.$value,
      ),
    );
  }

  /// Wrapper for the [RangeError.checkValueInInterval] method
  static $Value? $checkValueInInterval(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final _arg2 = (c as List<Object?>)[0] as $Value?;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;

    final value = RangeError.checkValueInInterval(
      (r as $int).$value,
      (s as $int).$value,
      (_arg2 as $int).$value,
      _arg3OrNull?.$value,
      _arg4OrNull?.$value,
    );
    return $int(value);
  }

  /// Wrapper for the [RangeError.checkValidIndex] method
  static $Value? $checkValidIndex(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;

    final value = RangeError.checkValidIndex(
      (r as $int).$value,
      (s as $Value?)!.$reified,
      _arg2OrNull?.$value,
      _arg3OrNull?.$value,
      _arg4OrNull?.$value,
    );
    return $int(value);
  }

  /// Wrapper for the [RangeError.checkValidRange] method
  static $Value? $checkValidRange(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final _arg2 = (c as List<Object?>)[0] as $Value?;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;
    final _arg5OrNull = c is List && c.length > 3 ? c[3] as $Value? : null;

    final value = RangeError.checkValidRange(
      (r as $int).$value,
      (s as $Value?)!.$value,
      (_arg2 as $int).$value,
      _arg3OrNull?.$value,
      _arg4OrNull?.$value,
      _arg5OrNull?.$value,
    );
    return $int(value);
  }

  /// Wrapper for the [RangeError.checkNotNegative] method
  static $Value? $checkNotNegative(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = RangeError.checkNotNegative(
      (r as $int).$value,
      (s is $Value ? s : null)?.$value,
      (c is $Value ? c : null)?.$value,
    );
    return $int(value);
  }

  final $Instance _superclass;

  @override
  final RangeError $value;

  @override
  RangeError get $reified => $value;

  /// Wrap a [RangeError] in a [$RangeError]
  $RangeError.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'stackTrace':
        final _stackTrace = $value.stackTrace;
        return _stackTrace == null
            ? const $null()
            : $StackTrace.wrap(_stackTrace);
      case 'invalidValue':
        final _invalidValue = $value.invalidValue;
        return _invalidValue == null ? const $null() : $num(_invalidValue);
      case 'name':
        final _name = $value.name;
        return _name == null ? const $null() : $String(_name);
      case 'message':
        final _message = $value.message;
        return runtime.wrapAlways(_message, recursive: true);
      case 'start':
        final _start = $value.start;
        return _start == null ? const $null() : $num(_start);
      case 'end':
        final _end = $value.end;
        return _end == null ? const $null() : $num(_end);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  num? get start => $value.start;

  @override
  num? get end => $value.end;

  @override
  num? get invalidValue => $value.invalidValue;

  @override
  String? get name => $value.name;

  @override
  dynamic get message => $value.message;

  @override
  StackTrace? get stackTrace => $value.stackTrace;

  @override
  String toString() => $value.toString();
}

/// dart_eval wrapper binding for [NoSuchMethodError]
class $NoSuchMethodError implements NoSuchMethodError, $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'NoSuchMethodError.withInvocation',
      $NoSuchMethodError.$withInvocation,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$NoSuchMethodError]
  static const $spec = BridgeTypeSpec('dart:core', 'NoSuchMethodError');

  /// Compile-time type declaration of [$NoSuchMethodError]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$NoSuchMethodError]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, $implements: [BridgeTypeRef(CoreTypes.error, [])]),
    constructors: {
      'withInvocation': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'receiver',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
            ),

            BridgeParameter(
              'invocation',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.invocation, [])),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {},
    getters: {
      'stackTrace': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stackTrace, []),
            nullable: true,
          ),
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

  /// Wrapper for the [NoSuchMethodError.withInvocation] constructor
  static $Value? $withInvocation(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $NoSuchMethodError.wrap(
      NoSuchMethodError.withInvocation(
        (r as $Value?)!.$reified,
        (s as $Value?)!.$value,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final NoSuchMethodError $value;

  @override
  NoSuchMethodError get $reified => $value;

  /// Wrap a [NoSuchMethodError] in a [$NoSuchMethodError]
  $NoSuchMethodError.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'stackTrace':
        final _stackTrace = $value.stackTrace;
        return _stackTrace == null
            ? const $null()
            : $StackTrace.wrap(_stackTrace);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  StackTrace? get stackTrace => $value.stackTrace;

  @override
  String toString() => $value.toString();
}

/// dart_eval wrapper binding for [UnsupportedError]
class $UnsupportedError implements UnsupportedError, $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'UnsupportedError.',
      $UnsupportedError.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$UnsupportedError]
  static const $spec = BridgeTypeSpec('dart:core', 'UnsupportedError');

  /// Compile-time type declaration of [$UnsupportedError]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$UnsupportedError]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, $implements: [BridgeTypeRef(CoreTypes.error, [])]),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'message',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {},
    getters: {
      'stackTrace': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stackTrace, []),
            nullable: true,
          ),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {
      'message': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.string, []),
          nullable: true,
        ),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [UnsupportedError.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $UnsupportedError.wrap(UnsupportedError((r as $String).$value));
  }

  final $Instance _superclass;

  @override
  final UnsupportedError $value;

  @override
  UnsupportedError get $reified => $value;

  /// Wrap a [UnsupportedError] in a [$UnsupportedError]
  $UnsupportedError.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'stackTrace':
        final _stackTrace = $value.stackTrace;
        return _stackTrace == null
            ? const $null()
            : $StackTrace.wrap(_stackTrace);
      case 'message':
        final _message = $value.message;
        return _message == null ? const $null() : $String(_message);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  String? get message => $value.message;

  @override
  StackTrace? get stackTrace => $value.stackTrace;

  @override
  String toString() => $value.toString();
}

/// dart_eval wrapper binding for [UnimplementedError]
class $UnimplementedError implements UnimplementedError, $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'UnimplementedError.',
      $UnimplementedError.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$UnimplementedError]
  static const $spec = BridgeTypeSpec('dart:core', 'UnimplementedError');

  /// Compile-time type declaration of [$UnimplementedError]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$UnimplementedError]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(CoreTypes.error, []),
        BridgeTypeRef(CoreTypes.unsupportedError, []),
      ],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'message',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {},
    getters: {
      'stackTrace': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stackTrace, []),
            nullable: true,
          ),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {
      'message': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.string, []),
          nullable: true,
        ),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [UnimplementedError.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $UnimplementedError.wrap(
      UnimplementedError((r is $Value ? r : null)?.$value),
    );
  }

  final $Instance _superclass;

  @override
  final UnimplementedError $value;

  @override
  UnimplementedError get $reified => $value;

  /// Wrap a [UnimplementedError] in a [$UnimplementedError]
  $UnimplementedError.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'message':
        final _message = $value.message;
        return _message == null ? const $null() : $String(_message);
      case 'stackTrace':
        final _stackTrace = $value.stackTrace;
        return _stackTrace == null
            ? const $null()
            : $StackTrace.wrap(_stackTrace);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  String? get message => $value.message;

  @override
  StackTrace? get stackTrace => $value.stackTrace;

  @override
  String toString() => $value.toString();
}

/// dart_eval wrapper binding for [StateError]
class $StateError implements StateError, $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'StateError.',
      $StateError.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$StateError]
  static const $spec = BridgeTypeSpec('dart:core', 'StateError');

  /// Compile-time type declaration of [$StateError]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$StateError]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, $implements: [BridgeTypeRef(CoreTypes.error, [])]),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'message',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {},
    getters: {
      'stackTrace': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stackTrace, []),
            nullable: true,
          ),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {
      'message': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [StateError.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $StateError.wrap(StateError((r as $String).$value));
  }

  final $Instance _superclass;

  @override
  final StateError $value;

  @override
  StateError get $reified => $value;

  /// Wrap a [StateError] in a [$StateError]
  $StateError.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'stackTrace':
        final _stackTrace = $value.stackTrace;
        return _stackTrace == null
            ? const $null()
            : $StackTrace.wrap(_stackTrace);
      case 'message':
        final _message = $value.message;
        return $String(_message);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  String get message => $value.message;

  @override
  StackTrace? get stackTrace => $value.stackTrace;

  @override
  String toString() => $value.toString();
}

/// dart_eval wrapper binding for [Invocation]
class $Invocation implements Invocation, $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Invocation.method',
      $Invocation.$method,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Invocation.genericMethod',
      $Invocation.$genericMethod,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Invocation.getter',
      $Invocation.$getter,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Invocation.setter',
      $Invocation.$setter,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Invocation]
  static const $spec = BridgeTypeSpec('dart:core', 'Invocation');

  /// Compile-time type declaration of [$Invocation]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Invocation]
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

      'method': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'memberName',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
              false,
            ),

            BridgeParameter(
              'positionalArguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
                  ),
                ]),
                nullable: true,
              ),
              false,
            ),

            BridgeParameter(
              'namedArguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
                  ),
                ]),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),

      'genericMethod': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'memberName',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
              false,
            ),

            BridgeParameter(
              'typeArguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.type, [])),
                ]),
                nullable: true,
              ),
              false,
            ),

            BridgeParameter(
              'positionalArguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
                  ),
                ]),
                nullable: true,
              ),
              false,
            ),

            BridgeParameter(
              'namedArguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
                  ),
                ]),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),

      'getter': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'setter': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'memberName',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
              false,
            ),

            BridgeParameter(
              'argument',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {},
    getters: {
      'memberName': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'typeArguments': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.type, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'positionalArguments': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'namedArguments': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'isMethod': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isGetter': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isSetter': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isAccessor': BridgeMethodDef(
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

  /// Wrapper for the [Invocation.method] constructor
  static $Value? $method(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Invocation.wrap(
      Invocation.method(
        (r as $Value?)!.$value,
        (s as $Value?)!.$value,
        ((c is $Value ? c : null)?.$reified as Map?)?.cast<Symbol, Object?>(),
      ),
    );
  }

  /// Wrapper for the [Invocation.genericMethod] constructor
  static $Value? $genericMethod(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final _arg2 = (c as List<Object?>)[0] as $Value?;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;

    return $Invocation.wrap(
      Invocation.genericMethod(
        (r as $Value?)!.$value,
        (s as $Value?)!.$value,
        _arg2!.$value,
        (_arg3OrNull?.$reified as Map?)?.cast<Symbol, Object?>(),
      ),
    );
  }

  /// Wrapper for the [Invocation.getter] constructor
  static $Value? $getter(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Invocation.wrap(Invocation.getter((r as $Value?)!.$value));
  }

  /// Wrapper for the [Invocation.setter] constructor
  static $Value? $setter(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Invocation.wrap(
      Invocation.setter((r as $Value?)!.$value, (s as $Value?)!.$reified),
    );
  }

  final $Instance _superclass;

  @override
  final Invocation $value;

  @override
  Invocation get $reified => $value;

  /// Wrap a [Invocation] in a [$Invocation]
  $Invocation.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'memberName':
        final _memberName = $value.memberName;
        return $Symbol.wrap(_memberName);
      case 'typeArguments':
        final _typeArguments = $value.typeArguments;
        return $List.view(_typeArguments, (e) => $Type(e));
      case 'positionalArguments':
        final _positionalArguments = $value.positionalArguments;
        return $List.view(
          _positionalArguments,
          (e) => runtime.wrapAlways(e, recursive: true),
        );
      case 'namedArguments':
        final _namedArguments = $value.namedArguments;
        return wrapMap(
          _namedArguments,
          (key, value) => MapEntry(
            $Symbol.wrap(key),
            runtime.wrapAlways(value, recursive: true),
          ),
        );
      case 'isMethod':
        final _isMethod = $value.isMethod;
        return $bool(_isMethod);
      case 'isGetter':
        final _isGetter = $value.isGetter;
        return $bool(_isGetter);
      case 'isSetter':
        final _isSetter = $value.isSetter;
        return $bool(_isSetter);
      case 'isAccessor':
        final _isAccessor = $value.isAccessor;
        return $bool(_isAccessor);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  Symbol get memberName => $value.memberName;

  @override
  List<Type> get typeArguments => $value.typeArguments;

  @override
  List<dynamic> get positionalArguments => $value.positionalArguments;

  @override
  Map<Symbol, dynamic> get namedArguments => $value.namedArguments;

  @override
  bool get isMethod => $value.isMethod;

  @override
  bool get isGetter => $value.isGetter;

  @override
  bool get isSetter => $value.isSetter;

  @override
  bool get isAccessor => $value.isAccessor;
}
