// ignore_for_file: unused_import, unnecessary_import
// ignore_for_file: always_specify_types, avoid_redundant_argument_values
// ignore_for_file: sort_constructors_first
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_is_empty
// ignore_for_file: undefined_hidden_name
// ignore_for_file: dead_code, unused_local_variable
// ignore_for_file: unnecessary_type_check, unnecessary_non_null_assertion
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
import 'duration.dart';

/// dart_eval wrapper binding for [DateTime]
class $DateTime implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.',
      $DateTime.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.utc',
      $DateTime.$utc,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.now',
      $DateTime.$now,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.timestamp',
      $DateTime.$timestamp,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.fromMillisecondsSinceEpoch',
      $DateTime.$fromMillisecondsSinceEpoch,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.fromMicrosecondsSinceEpoch',
      $DateTime.$fromMicrosecondsSinceEpoch,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.parse',
      $DateTime.$parse,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.tryParse',
      $DateTime.$tryParse,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.monday*g',
      $DateTime.$monday,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.tuesday*g',
      $DateTime.$tuesday,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.wednesday*g',
      $DateTime.$wednesday,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.thursday*g',
      $DateTime.$thursday,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.friday*g',
      $DateTime.$friday,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.saturday*g',
      $DateTime.$saturday,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.sunday*g',
      $DateTime.$sunday,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.daysPerWeek*g',
      $DateTime.$daysPerWeek,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.january*g',
      $DateTime.$january,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.february*g',
      $DateTime.$february,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.march*g',
      $DateTime.$march,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.april*g',
      $DateTime.$april,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.may*g',
      $DateTime.$may,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.june*g',
      $DateTime.$june,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.july*g',
      $DateTime.$july,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.august*g',
      $DateTime.$august,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.september*g',
      $DateTime.$september,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.october*g',
      $DateTime.$october,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.november*g',
      $DateTime.$november,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.december*g',
      $DateTime.$december,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'DateTime.monthsPerYear*g',
      $DateTime.$monthsPerYear,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$DateTime]
  static const $spec = BridgeTypeSpec('dart:core', 'DateTime');

  /// Compile-time type declaration of [$DateTime]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$DateTime]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(CoreTypes.comparable, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime, [])),
        ]),
      ],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'year',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'month',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'day',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'hour',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'minute',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'second',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'millisecond',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'microsecond',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),
          ],
        ),
        isFactory: false,
      ),

      'utc': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'year',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'month',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'day',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'hour',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'minute',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'second',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'millisecond',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'microsecond',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),
          ],
        ),
        isFactory: false,
      ),

      'now': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),

      'timestamp': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),

      'fromMillisecondsSinceEpoch': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'isUtc',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'millisecondsSinceEpoch',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),

      'fromMicrosecondsSinceEpoch': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'isUtc',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'microsecondsSinceEpoch',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
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
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime, [])),
              false,
            ),
          ],
        ),
      ),

      'parse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'formattedString',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'tryParse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.dateTime, []),
            nullable: true,
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'formattedString',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'isBefore': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime, [])),
              false,
            ),
          ],
        ),
      ),

      'isAfter': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime, [])),
              false,
            ),
          ],
        ),
      ),

      'isAtSameMomentAs': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime, [])),
              false,
            ),
          ],
        ),
      ),

      'toLocal': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'toUtc': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'toIso8601String': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'add': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'duration',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
              false,
            ),
          ],
        ),
      ),

      'subtract': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'duration',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
              false,
            ),
          ],
        ),
      ),

      'difference': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime, [])),
              false,
            ),
          ],
        ),
      ),
    },
    getters: {
      'millisecondsSinceEpoch': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'microsecondsSinceEpoch': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'timeZoneName': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'timeZoneOffset': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.duration, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'year': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'month': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'day': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'hour': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'minute': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'second': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'millisecond': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'microsecond': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'weekday': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {
      'monday': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'tuesday': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'wednesday': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'thursday': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'friday': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'saturday': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'sunday': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'daysPerWeek': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'january': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'february': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'march': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'april': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'may': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'june': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'july': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'august': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'september': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'october': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'november': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'december': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'monthsPerYear': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'isUtc': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [DateTime.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;
    final _arg5OrNull = c is List && c.length > 3 ? c[3] as $Value? : null;
    final _arg6OrNull = c is List && c.length > 4 ? c[4] as $Value? : null;
    final _arg7OrNull = c is List && c.length > 5 ? c[5] as $Value? : null;

    return $DateTime.wrap(
      DateTime(
        (r as $int).$value,
        (s is $Value ? s : null) == null ? 1 : (s as $int).$value,
        _arg2OrNull == null ? 1 : (_arg2OrNull as $int).$value,
        _arg3OrNull == null ? 0 : (_arg3OrNull as $int).$value,
        _arg4OrNull == null ? 0 : (_arg4OrNull as $int).$value,
        _arg5OrNull == null ? 0 : (_arg5OrNull as $int).$value,
        _arg6OrNull == null ? 0 : (_arg6OrNull as $int).$value,
        _arg7OrNull == null ? 0 : (_arg7OrNull as $int).$value,
      ),
    );
  }

  /// Wrapper for the [DateTime.utc] constructor
  static $Value? $utc(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;
    final _arg5OrNull = c is List && c.length > 3 ? c[3] as $Value? : null;
    final _arg6OrNull = c is List && c.length > 4 ? c[4] as $Value? : null;
    final _arg7OrNull = c is List && c.length > 5 ? c[5] as $Value? : null;

    return $DateTime.wrap(
      DateTime.utc(
        (r as $int).$value,
        (s is $Value ? s : null) == null ? 1 : (s as $int).$value,
        _arg2OrNull == null ? 1 : (_arg2OrNull as $int).$value,
        _arg3OrNull == null ? 0 : (_arg3OrNull as $int).$value,
        _arg4OrNull == null ? 0 : (_arg4OrNull as $int).$value,
        _arg5OrNull == null ? 0 : (_arg5OrNull as $int).$value,
        _arg6OrNull == null ? 0 : (_arg6OrNull as $int).$value,
        _arg7OrNull == null ? 0 : (_arg7OrNull as $int).$value,
      ),
    );
  }

  /// Wrapper for the [DateTime.now] constructor
  static $Value? $now(Runtime runtime, Object? r, Object? s, Object? c) {
    return $DateTime.wrap(DateTime.now());
  }

  /// Wrapper for the [DateTime.timestamp] constructor
  static $Value? $timestamp(Runtime runtime, Object? r, Object? s, Object? c) {
    return $DateTime.wrap(DateTime.timestamp());
  }

  /// Wrapper for the [DateTime.fromMillisecondsSinceEpoch] constructor
  static $Value? $fromMillisecondsSinceEpoch(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $DateTime.wrap(
      DateTime.fromMillisecondsSinceEpoch(
        (r as $int).$value,
        isUtc: (s is $Value ? s : null) == null ? false : (s as $bool).$value,
      ),
    );
  }

  /// Wrapper for the [DateTime.fromMicrosecondsSinceEpoch] constructor
  static $Value? $fromMicrosecondsSinceEpoch(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $DateTime.wrap(
      DateTime.fromMicrosecondsSinceEpoch(
        (r as $int).$value,
        isUtc: (s is $Value ? s : null) == null ? false : (s as $bool).$value,
      ),
    );
  }

  /// Wrapper for the [DateTime.parse] method
  static $Value? $parse(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.parse((r as $String).$value);
    return $DateTime.wrap(value);
  }

  /// Wrapper for the [DateTime.tryParse] method
  static $Value? $tryParse(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.tryParse((r as $String).$value);
    return value == null ? const $null() : $DateTime.wrap(value);
  }

  /// Wrapper for the [DateTime.monday] getter
  static $Value? $monday(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.monday;
    return $int(value);
  }

  /// Wrapper for the [DateTime.tuesday] getter
  static $Value? $tuesday(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.tuesday;
    return $int(value);
  }

  /// Wrapper for the [DateTime.wednesday] getter
  static $Value? $wednesday(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.wednesday;
    return $int(value);
  }

  /// Wrapper for the [DateTime.thursday] getter
  static $Value? $thursday(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.thursday;
    return $int(value);
  }

  /// Wrapper for the [DateTime.friday] getter
  static $Value? $friday(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.friday;
    return $int(value);
  }

  /// Wrapper for the [DateTime.saturday] getter
  static $Value? $saturday(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.saturday;
    return $int(value);
  }

  /// Wrapper for the [DateTime.sunday] getter
  static $Value? $sunday(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.sunday;
    return $int(value);
  }

  /// Wrapper for the [DateTime.daysPerWeek] getter
  static $Value? $daysPerWeek(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = DateTime.daysPerWeek;
    return $int(value);
  }

  /// Wrapper for the [DateTime.january] getter
  static $Value? $january(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.january;
    return $int(value);
  }

  /// Wrapper for the [DateTime.february] getter
  static $Value? $february(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.february;
    return $int(value);
  }

  /// Wrapper for the [DateTime.march] getter
  static $Value? $march(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.march;
    return $int(value);
  }

  /// Wrapper for the [DateTime.april] getter
  static $Value? $april(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.april;
    return $int(value);
  }

  /// Wrapper for the [DateTime.may] getter
  static $Value? $may(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.may;
    return $int(value);
  }

  /// Wrapper for the [DateTime.june] getter
  static $Value? $june(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.june;
    return $int(value);
  }

  /// Wrapper for the [DateTime.july] getter
  static $Value? $july(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.july;
    return $int(value);
  }

  /// Wrapper for the [DateTime.august] getter
  static $Value? $august(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.august;
    return $int(value);
  }

  /// Wrapper for the [DateTime.september] getter
  static $Value? $september(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.september;
    return $int(value);
  }

  /// Wrapper for the [DateTime.october] getter
  static $Value? $october(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.october;
    return $int(value);
  }

  /// Wrapper for the [DateTime.november] getter
  static $Value? $november(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.november;
    return $int(value);
  }

  /// Wrapper for the [DateTime.december] getter
  static $Value? $december(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = DateTime.december;
    return $int(value);
  }

  /// Wrapper for the [DateTime.monthsPerYear] getter
  static $Value? $monthsPerYear(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = DateTime.monthsPerYear;
    return $int(value);
  }

  final $Instance _superclass;

  @override
  final DateTime $value;

  @override
  DateTime get $reified => $value;

  /// Wrap a [DateTime] in a [$DateTime]
  $DateTime.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'isUtc':
        final _isUtc = $value.isUtc;
        return $bool(_isUtc);
      case 'millisecondsSinceEpoch':
        final _millisecondsSinceEpoch = $value.millisecondsSinceEpoch;
        return $int(_millisecondsSinceEpoch);
      case 'microsecondsSinceEpoch':
        final _microsecondsSinceEpoch = $value.microsecondsSinceEpoch;
        return $int(_microsecondsSinceEpoch);
      case 'timeZoneName':
        final _timeZoneName = $value.timeZoneName;
        return $String(_timeZoneName);
      case 'timeZoneOffset':
        final _timeZoneOffset = $value.timeZoneOffset;
        return $Duration.wrap(_timeZoneOffset);
      case 'year':
        final _year = $value.year;
        return $int(_year);
      case 'month':
        final _month = $value.month;
        return $int(_month);
      case 'day':
        final _day = $value.day;
        return $int(_day);
      case 'hour':
        final _hour = $value.hour;
        return $int(_hour);
      case 'minute':
        final _minute = $value.minute;
        return $int(_minute);
      case 'second':
        final _second = $value.second;
        return $int(_second);
      case 'millisecond':
        final _millisecond = $value.millisecond;
        return $int(_millisecond);
      case 'microsecond':
        final _microsecond = $value.microsecond;
        return $int(_microsecond);
      case 'weekday':
        final _weekday = $value.weekday;
        return $int(_weekday);
      case 'compareTo':
        return __compareTo;

      case 'isBefore':
        return __isBefore;

      case 'isAfter':
        return __isAfter;

      case 'isAtSameMomentAs':
        return __isAtSameMomentAs;

      case 'toLocal':
        return __toLocal;

      case 'toUtc':
        return __toUtc;

      case 'toIso8601String':
        return __toIso8601String;

      case 'add':
        return __add;

      case 'subtract':
        return __subtract;

      case 'difference':
        return __difference;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __compareTo = $Function(_compareTo);
  static $Value? _compareTo(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final self = target! as $DateTime;
    final result = self.$value.compareTo(args[0]!.$value);
    return $int(result);
  }

  static const $Function __isBefore = $Function(_isBefore);
  static $Value? _isBefore(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final self = target! as $DateTime;
    final result = self.$value.isBefore(args[0]!.$value);
    return $bool(result);
  }

  static const $Function __isAfter = $Function(_isAfter);
  static $Value? _isAfter(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $DateTime;
    final result = self.$value.isAfter(args[0]!.$value);
    return $bool(result);
  }

  static const $Function __isAtSameMomentAs = $Function(_isAtSameMomentAs);
  static $Value? _isAtSameMomentAs(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final self = target! as $DateTime;
    final result = self.$value.isAtSameMomentAs(args[0]!.$value);
    return $bool(result);
  }

  static const $Function __toLocal = $Function(_toLocal);
  static $Value? _toLocal(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $DateTime;
    final result = self.$value.toLocal();
    return $DateTime.wrap(result);
  }

  static const $Function __toUtc = $Function(_toUtc);
  static $Value? _toUtc(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $DateTime;
    final result = self.$value.toUtc();
    return $DateTime.wrap(result);
  }

  static const $Function __toIso8601String = $Function(_toIso8601String);
  static $Value? _toIso8601String(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final self = target! as $DateTime;
    final result = self.$value.toIso8601String();
    return $String(result);
  }

  static const $Function __add = $Function(_add);
  static $Value? _add(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $DateTime;
    final result = self.$value.add(args[0]!.$value);
    return $DateTime.wrap(result);
  }

  static const $Function __subtract = $Function(_subtract);
  static $Value? _subtract(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final self = target! as $DateTime;
    final result = self.$value.subtract(args[0]!.$value);
    return $DateTime.wrap(result);
  }

  static const $Function __difference = $Function(_difference);
  static $Value? _difference(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final self = target! as $DateTime;
    final result = self.$value.difference(args[0]!.$value);
    return $Duration.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
