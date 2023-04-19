import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';

/// dart_eval [$Instance] wrapper of a [DateTime]
class $DateTime implements DateTime, $Instance {
  /// Configure the [$DateTime] class for runtime with a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:core', 'DateTime.now',
        (runtime, target, args) => $DateTime.wrap(DateTime.now()));
    runtime.registerBridgeFunc('dart:core', 'DateTime.parse', $parse);
  }

  static const _dtBoolGetter = BridgeMethodDef(BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType)),
      params: [],
      namedParams: []));

  static const _dtIntGetter = BridgeMethodDef(BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)),
      params: [],
      namedParams: []));

  /// Compile-time class declaration for [$DateTime]
  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.dateTime)),
      constructors: {
        'now': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime)),
            params: [],
            namedParams: [])),
      },
      methods: {
        'parse': BridgeMethodDef(
            BridgeFunctionDef(
                returns:
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime)),
                params: [
                  BridgeParameter(
                      'formattedString',
                      BridgeTypeAnnotation(
                          BridgeTypeRef.type(RuntimeTypes.stringType)),
                      false)
                ],
                namedParams: []),
            isStatic: true),
        'isAfter': BridgeMethodDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType)),
            params: [
              BridgeParameter(
                  'other',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime)),
                  false),
            ])),
        'isBefore': BridgeMethodDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType)),
            params: [
              BridgeParameter(
                  'other',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime)),
                  false),
            ])),
      },
      getters: {
        'day': _dtIntGetter,
        'hour': _dtIntGetter,
        'minute': _dtIntGetter,
        'second': _dtIntGetter,
        'millisecondsSinceEpoch': _dtIntGetter,
        'month': _dtIntGetter,
        'year': _dtIntGetter,
        'isUtc': _dtBoolGetter,
        'millisecond': _dtIntGetter,
        'microsecond': _dtIntGetter,
        'microsecondsSinceEpoch': _dtIntGetter,
        'weekday': _dtIntGetter,
      },
      setters: {},
      fields: {},
      wrap: true);

  /// Wrap a [DateTime] in a [$DateTime]
  $DateTime.wrap(this.$value) : _superclass = $Object($value);

  @override
  final DateTime $value;

  @override
  DateTime get $reified => $value;

  final $Instance _superclass;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'day':
        return $int($value.day);
      case 'hour':
        return $int($value.hour);
      case 'minute':
        return $int($value.minute);
      case 'second':
        return $int($value.second);
      case 'millisecondsSinceEpoch':
        return $int($value.millisecondsSinceEpoch);
      //
      case 'isUtc':
        return $bool($value.isUtc);
      case 'year':
        return $int($value.year);
      case 'month':
        return $int($value.month);
      case 'millisecond':
        return $int($value.millisecond);
      case 'microsecond':
        return $int($value.microsecond);
      case 'microsecondsSinceEpoch':
        return $int($value.microsecondsSinceEpoch);
      case 'weekday':
        return $int($value.weekday);
      case 'isAfter':
        return $Function(_isAfter);
      case 'isBefore':
        return $Function(_isBefore);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  static $Value? _isAfter(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    var a = target!.$value as DateTime;
    var other = args[0]!.$value as DateTime;
    return $bool(a.isAfter(other));
  }

  static $Value? _isBefore(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    var a = target!.$value as DateTime;
    var other = args[0]!.$value as DateTime;
    return $bool(a.isBefore(other));
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.dateTime);

  @override
  DateTime add(Duration duration) => $value.add(duration);

  @override
  int compareTo(DateTime other) => $value.compareTo(other);

  @override
  int get day => $value.day;

  @override
  Duration difference(DateTime other) => $value.difference(other);

  @override
  int get hour => $value.hour;

  @override
  bool isAfter(DateTime other) => $value.isAfter(other);

  @override
  bool isAtSameMomentAs(DateTime other) => $value.isAtSameMomentAs(other);

  @override
  bool isBefore(DateTime other) => $value.isBefore(other);

  @override
  bool get isUtc => $value.isUtc;

  @override
  int get microsecond => $value.microsecond;

  @override
  int get microsecondsSinceEpoch => $value.microsecondsSinceEpoch;

  @override
  int get millisecond => $value.millisecond;

  @override
  int get millisecondsSinceEpoch => $value.millisecondsSinceEpoch;

  @override
  int get minute => $value.minute;

  @override
  int get month => $value.month;

  @override
  int get second => $value.second;

  @override
  DateTime subtract(Duration duration) => $value.subtract(duration);

  @override
  String get timeZoneName => $value.timeZoneName;

  @override
  Duration get timeZoneOffset => $value.timeZoneOffset;

  @override
  String toIso8601String() => $value.toIso8601String();

  @override
  DateTime toLocal() => $value.toLocal();

  @override
  DateTime toUtc() => $value.toUtc();

  @override
  int get weekday => $value.weekday;

  @override
  int get year => $value.year;

  @override
  int get hashCode => $value.hashCode;

  @override
  bool operator ==(Object other) => $value == other;

  static $Value? $parse(Runtime runtime, $Value? target, List<$Value?> args) {
    final formattedString = args[0]!.$value as String;
    return $DateTime.wrap(DateTime.parse(formattedString));
  }
}
