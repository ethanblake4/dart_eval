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

/// dart_eval wrapper binding for [Duration]
class $Duration implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.',
      $Duration.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.microsecondsPerMillisecond*g',
      $Duration.$microsecondsPerMillisecond,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.millisecondsPerSecond*g',
      $Duration.$millisecondsPerSecond,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.secondsPerMinute*g',
      $Duration.$secondsPerMinute,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.minutesPerHour*g',
      $Duration.$minutesPerHour,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.hoursPerDay*g',
      $Duration.$hoursPerDay,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.microsecondsPerSecond*g',
      $Duration.$microsecondsPerSecond,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.microsecondsPerMinute*g',
      $Duration.$microsecondsPerMinute,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.microsecondsPerHour*g',
      $Duration.$microsecondsPerHour,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.microsecondsPerDay*g',
      $Duration.$microsecondsPerDay,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.millisecondsPerMinute*g',
      $Duration.$millisecondsPerMinute,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.millisecondsPerHour*g',
      $Duration.$millisecondsPerHour,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.millisecondsPerDay*g',
      $Duration.$millisecondsPerDay,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.secondsPerHour*g',
      $Duration.$secondsPerHour,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.secondsPerDay*g',
      $Duration.$secondsPerDay,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.minutesPerDay*g',
      $Duration.$minutesPerDay,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Duration.zero*g',
      $Duration.$zero,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Duration]
  static const $spec = BridgeTypeSpec('dart:core', 'Duration');

  /// Compile-time type declaration of [$Duration]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Duration]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(CoreTypes.comparable, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
        ]),
      ],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'days',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'hours',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'minutes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'seconds',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'milliseconds',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'microseconds',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),
          ],
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
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
              false,
            ),
          ],
        ),
      ),

      '+': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
              false,
            ),
          ],
        ),
      ),

      '-': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
              false,
            ),
          ],
        ),
      ),

      '*': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'factor',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
              false,
            ),
          ],
        ),
      ),

      '~/': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'quotient',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      '<': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
              false,
            ),
          ],
        ),
      ),

      '>': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
              false,
            ),
          ],
        ),
      ),

      '<=': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
              false,
            ),
          ],
        ),
      ),

      '>=': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
              false,
            ),
          ],
        ),
      ),

      'abs': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    getters: {
      'inDays': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'inHours': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'inMinutes': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'inSeconds': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'inMilliseconds': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isNegative': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {
      'microsecondsPerMillisecond': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'millisecondsPerSecond': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'secondsPerMinute': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'minutesPerHour': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'hoursPerDay': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'microsecondsPerSecond': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'microsecondsPerMinute': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'microsecondsPerHour': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'microsecondsPerDay': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'millisecondsPerMinute': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'millisecondsPerHour': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'millisecondsPerDay': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'secondsPerHour': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'secondsPerDay': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'minutesPerDay': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'zero': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
        isStatic: true,
      ),

      'inMicroseconds': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Duration.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;
    final _arg5OrNull = c is List && c.length > 3 ? c[3] as $Value? : null;

    return $Duration.wrap(
      Duration(
        days: (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
        hours: (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
        minutes: _arg2OrNull == null ? 0 : (_arg2OrNull as $int).$value,
        seconds: _arg3OrNull == null ? 0 : (_arg3OrNull as $int).$value,
        milliseconds: _arg4OrNull == null ? 0 : (_arg4OrNull as $int).$value,
        microseconds: _arg5OrNull == null ? 0 : (_arg5OrNull as $int).$value,
      ),
    );
  }

  /// Wrapper for the [Duration.microsecondsPerMillisecond] getter
  static $Value? $microsecondsPerMillisecond(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.microsecondsPerMillisecond;
    return $int(value);
  }

  /// Wrapper for the [Duration.millisecondsPerSecond] getter
  static $Value? $millisecondsPerSecond(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.millisecondsPerSecond;
    return $int(value);
  }

  /// Wrapper for the [Duration.secondsPerMinute] getter
  static $Value? $secondsPerMinute(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.secondsPerMinute;
    return $int(value);
  }

  /// Wrapper for the [Duration.minutesPerHour] getter
  static $Value? $minutesPerHour(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.minutesPerHour;
    return $int(value);
  }

  /// Wrapper for the [Duration.hoursPerDay] getter
  static $Value? $hoursPerDay(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.hoursPerDay;
    return $int(value);
  }

  /// Wrapper for the [Duration.microsecondsPerSecond] getter
  static $Value? $microsecondsPerSecond(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.microsecondsPerSecond;
    return $int(value);
  }

  /// Wrapper for the [Duration.microsecondsPerMinute] getter
  static $Value? $microsecondsPerMinute(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.microsecondsPerMinute;
    return $int(value);
  }

  /// Wrapper for the [Duration.microsecondsPerHour] getter
  static $Value? $microsecondsPerHour(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.microsecondsPerHour;
    return $int(value);
  }

  /// Wrapper for the [Duration.microsecondsPerDay] getter
  static $Value? $microsecondsPerDay(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.microsecondsPerDay;
    return $int(value);
  }

  /// Wrapper for the [Duration.millisecondsPerMinute] getter
  static $Value? $millisecondsPerMinute(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.millisecondsPerMinute;
    return $int(value);
  }

  /// Wrapper for the [Duration.millisecondsPerHour] getter
  static $Value? $millisecondsPerHour(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.millisecondsPerHour;
    return $int(value);
  }

  /// Wrapper for the [Duration.millisecondsPerDay] getter
  static $Value? $millisecondsPerDay(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.millisecondsPerDay;
    return $int(value);
  }

  /// Wrapper for the [Duration.secondsPerHour] getter
  static $Value? $secondsPerHour(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.secondsPerHour;
    return $int(value);
  }

  /// Wrapper for the [Duration.secondsPerDay] getter
  static $Value? $secondsPerDay(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.secondsPerDay;
    return $int(value);
  }

  /// Wrapper for the [Duration.minutesPerDay] getter
  static $Value? $minutesPerDay(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Duration.minutesPerDay;
    return $int(value);
  }

  /// Wrapper for the [Duration.zero] getter
  static $Value? $zero(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Duration.zero;
    return $Duration.wrap(value);
  }

  final $Instance _superclass;

  @override
  final Duration $value;

  @override
  Duration get $reified => $value;

  /// Wrap a [Duration] in a [$Duration]
  $Duration.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'inMicroseconds':
        final _inMicroseconds = $value.inMicroseconds;
        return $int(_inMicroseconds);
      case 'inDays':
        final _inDays = $value.inDays;
        return $int(_inDays);
      case 'inHours':
        final _inHours = $value.inHours;
        return $int(_inHours);
      case 'inMinutes':
        final _inMinutes = $value.inMinutes;
        return $int(_inMinutes);
      case 'inSeconds':
        final _inSeconds = $value.inSeconds;
        return $int(_inSeconds);
      case 'inMilliseconds':
        final _inMilliseconds = $value.inMilliseconds;
        return $int(_inMilliseconds);
      case 'isNegative':
        final _isNegative = $value.isNegative;
        return $bool(_isNegative);
      case 'compareTo':
        return $Closure(__compareTo.func, this);

      case '+':
        return $Closure(__operatorPlus.func, this);

      case '-':
        return $Closure(__operatorMinus.func, this);

      case '*':
        return $Closure(__operatorMul.func, this);

      case '~/':
        return $Closure(__operatorIntDiv.func, this);

      case '<':
        return $Closure(__operatorLt.func, this);

      case '>':
        return $Closure(__operatorGt.func, this);

      case '<=':
        return $Closure(__operatorLte.func, this);

      case '>=':
        return $Closure(__operatorGte.func, this);

      case 'abs':
        return $Closure(__abs.func, this);
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
    final self = target! as $Duration;
    final result = self.$value.compareTo((r as $Value?)!.$value);
    return $int(result);
  }

  static const $Function __operatorPlus = $Function(_operatorPlus);
  static $Value? _operatorPlus(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Duration;
    final result = (self.$value + (r as $Value?)!.$value);
    return $Duration.wrap(result);
  }

  static const $Function __operatorMinus = $Function(_operatorMinus);
  static $Value? _operatorMinus(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Duration;
    final result = (self.$value - (r as $Value?)!.$value);
    return $Duration.wrap(result);
  }

  static const $Function __operatorMul = $Function(_operatorMul);
  static $Value? _operatorMul(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Duration;
    final result = (self.$value * (r as $num).$value);
    return $Duration.wrap(result);
  }

  static const $Function __operatorIntDiv = $Function(_operatorIntDiv);
  static $Value? _operatorIntDiv(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Duration;
    final result = (self.$value ~/ (r as $int).$value);
    return $Duration.wrap(result);
  }

  static const $Function __operatorLt = $Function(_operatorLt);
  static $Value? _operatorLt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Duration;
    final result = (self.$value < (r as $Value?)!.$value);
    return $bool(result);
  }

  static const $Function __operatorGt = $Function(_operatorGt);
  static $Value? _operatorGt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Duration;
    final result = (self.$value > (r as $Value?)!.$value);
    return $bool(result);
  }

  static const $Function __operatorLte = $Function(_operatorLte);
  static $Value? _operatorLte(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Duration;
    final result = (self.$value <= (r as $Value?)!.$value);
    return $bool(result);
  }

  static const $Function __operatorGte = $Function(_operatorGte);
  static $Value? _operatorGte(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Duration;
    final result = (self.$value >= (r as $Value?)!.$value);
    return $bool(result);
  }

  static const $Function __abs = $Function(_abs);
  static $Value? _abs(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Duration;
    final result = self.$value.abs();
    return $Duration.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
