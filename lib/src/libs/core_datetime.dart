import '../../dart_eval.dart';

class EvalDateTime extends DateTime
    with
        ValueInterop<DateTime>,
        EvalBridgeObjectMixin<DateTime>,
        BridgeRectifier<DateTime> {
  EvalDateTime(int year,
      [int month = 1,
        int day = 1,
        int hour = 0,
        int minute = 0,
        int second = 0,
        int millisecond = 0,
        int microsecond = 0])
      : super(year, month, day, hour, minute, second, millisecond, microsecond);

  EvalDateTime.utc(int year,
      [int month = 1,
        int day = 1,
        int hour = 0,
        int minute = 0,
        int second = 0,
        int millisecond = 0,
        int microsecond = 0])
      : super.utc(
      year, month, day, hour, minute, second, millisecond, microsecond);

  EvalDateTime.now() : super.now();

  EvalDateTime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
      {bool isUtc = false})
      : super.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: isUtc);

  EvalDateTime.fromMicrosecondsSinceEpoch(int microsecondsSinceEpoch,
      {bool isUtc = false})
      : super.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch, isUtc: isUtc);

  static final BridgeInstantiator<DateTime> _evalInstantiator =
      (String constructor, List<dynamic> pos, Map<String, dynamic> named) {
    switch (constructor) {
      case '':
        return EvalDateTime(
            pos[0],
            pos.length < 2 ? 1 : pos[1],
            pos.length < 3 ? 1 : pos[2],
            pos.length < 4 ? 0 : pos[3],
            pos.length < 5 ? 0 : pos[4],
            pos.length < 6 ? 0 : pos[5],
            pos.length < 7 ? 0 : pos[6],
            pos.length < 8 ? 0 : pos[7]);
      case 'utc':
        return EvalDateTime.utc(
            pos[0],
            pos.length < 2 ? 1 : pos[1],
            pos.length < 3 ? 1 : pos[2],
            pos.length < 4 ? 0 : pos[3],
            pos.length < 5 ? 0 : pos[4],
            pos.length < 6 ? 0 : pos[5],
            pos.length < 7 ? 0 : pos[6],
            pos.length < 8 ? 0 : pos[7]);
      case 'now':
        return EvalDateTime.now();
      case 'fromMillisecondsSinceEpoch':
        return EvalDateTime.fromMillisecondsSinceEpoch(pos[0],
            isUtc: named['isUtc']);
      case 'fromMicrosecondsSinceEpoch':
        return EvalDateTime.fromMicrosecondsSinceEpoch(pos[0],
            isUtc: named['isUtc']);
      default:
        throw ArgumentError('Cannot find constructor $constructor');
    }
  };

  static final clsgen = (EvalScope lexicalScope) => EvalBridgeClass([
    DartConstructorDeclaration('', [
      ParameterDefinition(
          'year', EvalType.intType, false, false, false, true, null,
          isField: false),
      ParameterDefinition(
          'month', EvalType.intType, false, true, false, false, null,
          isField: false),
      ParameterDefinition(
          'day', EvalType.intType, false, true, false, false, null,
          isField: false),
      ParameterDefinition(
          'hour', EvalType.intType, false, true, false, false, null,
          isField: false),
      ParameterDefinition(
          'minute', EvalType.intType, false, true, false, false, null,
          isField: false),
      ParameterDefinition(
          'second', EvalType.intType, false, true, false, false, null,
          isField: false),
      ParameterDefinition(
          'millisecond', EvalType.intType, false, true, false, false, null,
          isField: false),
      ParameterDefinition(
          'microsecond', EvalType.intType, false, true, false, false, null,
          isField: false)
    ]),
    DartConstructorDeclaration('utc', [
      ParameterDefinition(
          'year', EvalType.intType, false, false, false, true, null,
          isField: false),
      ParameterDefinition(
          'month', EvalType.intType, false, true, false, false, null,
          isField: false),
      ParameterDefinition(
          'day', EvalType.intType, false, true, false, false, null,
          isField: false),
      ParameterDefinition(
          'hour', EvalType.intType, false, true, false, false, null,
          isField: false),
      ParameterDefinition(
          'minute', EvalType.intType, false, true, false, false, null,
          isField: false),
      ParameterDefinition(
          'second', EvalType.intType, false, true, false, false, null,
          isField: false),
      ParameterDefinition(
          'millisecond', EvalType.intType, false, true, false, false, null,
          isField: false),
      ParameterDefinition(
          'microsecond', EvalType.intType, false, true, false, false, null,
          isField: false)
    ]),
    DartConstructorDeclaration('now', []),
    DartConstructorDeclaration('fromMillisecondsSinceEpoch', [
      ParameterDefinition('millisecondsSinceEpoch', EvalType.intType,
          false, false, false, true, null,
          isField: false),
      ParameterDefinition(
          'isUtc', EvalType.boolType, false, true, true, false, null,
          isField: false)
    ]),
    DartConstructorDeclaration('fromMicrosecondsSinceEpoch', [
      ParameterDefinition('microsecondsSinceEpoch', EvalType.intType,
          false, false, false, true, null,
          isField: false),
      ParameterDefinition(
          'isUtc', EvalType.boolType, false, true, true, false, null,
          isField: false)
    ]),
    DartConstructorDeclaration('_withValue', [
      ParameterDefinition(
          '_value', EvalType.intType, false, false, false, true, null,
          isField: true),
      ParameterDefinition(
          'isUtc', EvalType.boolType, false, false, true, true, null,
          isField: false)
    ]),
    DartConstructorDeclaration('_internal', [
      ParameterDefinition(
          'year', EvalType.intType, false, false, false, true, null,
          isField: false),
      ParameterDefinition(
          'month', EvalType.intType, false, false, false, true, null,
          isField: false),
      ParameterDefinition(
          'day', EvalType.intType, false, false, false, true, null,
          isField: false),
      ParameterDefinition(
          'hour', EvalType.intType, false, false, false, true, null,
          isField: false),
      ParameterDefinition(
          'minute', EvalType.intType, false, false, false, true, null,
          isField: false),
      ParameterDefinition(
          'second', EvalType.intType, false, false, false, true, null,
          isField: false),
      ParameterDefinition(
          'millisecond', EvalType.intType, false, false, false, true, null,
          isField: false),
      ParameterDefinition(
          'microsecond', EvalType.intType, false, false, false, true, null,
          isField: false),
      ParameterDefinition(
          'isUtc', EvalType.boolType, false, false, false, true, null,
          isField: false)
    ]),
    DartConstructorDeclaration('_now', [])
  ], EvalType.DateTimeType, lexicalScope, DateTime,
      _evalInstantiator);

  static late EvalBridgeClass cls;

  @override
  EvalBridgeData evalBridgeData = EvalBridgeData(cls);

  static EvalValue evalMakeWrapper(DateTime? target) {

    if (target == null) {
      return EvalNull();
    }
    return EvalRealObject(target, cls: cls, fields: {
      '_value': EvalField(
          '_value',
          null,
          null,
          Getter(EvalCallableImpl((lexical, inherited, generics, args,
              {target}) =>
              EvalInt(target?.realValue!._value!)))),
      'isUtc': EvalField(
          'isUtc',
          null,
          null,
          Getter(EvalCallableImpl((lexical, inherited, generics, args,
              {target}) =>
              EvalBool(target?.realValue!.isUtc!))))
    });
  }

  @override
  bool get isUtc {
    final _f = evalBridgeTryGetField('isUtc');
    if (_f != null) return _f.evalReifyFull();
    return super.isUtc;
  }

  @override
  bool isBefore(DateTime other) =>
      bridgeCall('isBefore', [evalMakeWrapper(other)]);
  @override
  bool isAfter(DateTime other) =>
      bridgeCall('isAfter', [evalMakeWrapper(other)]);
  @override
  bool isAtSameMomentAs(DateTime other) =>
      bridgeCall('isAtSameMomentAs', [evalMakeWrapper(other)]);
  @override
  int compareTo(DateTime other) =>
      bridgeCall('compareTo', [evalMakeWrapper(other)]);
  @override
  DateTime toLocal() => bridgeCall('toLocal');
  @override
  DateTime toUtc() => bridgeCall('toUtc');
  @override
  String toString() => bridgeCall('toString');
  @override
  String toIso8601String() => bridgeCall('toIso8601String');
  @override
  Duration difference(DateTime other) =>
      bridgeCall('difference', [evalMakeWrapper(other)]);
  @override
  EvalValue evalGetField(String name, {bool internalGet = false}) {
    switch (name) {
      case 'isUtc':
        final _f = evalBridgeTryGetField('isUtc');
        if (_f != null) return _f;
        final _v = super.isUtc;
        if (_v == null) return EvalNull();
        return EvalBool(_v);
      case 'isBefore':
        return evalBridgeTryGetField('isBefore') ??
            EvalBridgeFunction(
                super.isBefore, (_x) => EvalBool(_x as bool));
      case 'isAfter':
        return evalBridgeTryGetField('isAfter') ??
            EvalBridgeFunction(
                super.isAfter, (_x) => EvalBool(_x as bool));
      case 'isAtSameMomentAs':
        return evalBridgeTryGetField('isAtSameMomentAs') ??
            EvalBridgeFunction(
                super.isAtSameMomentAs, (_x) => EvalBool(_x as bool));
      case 'compareTo':
        return evalBridgeTryGetField('compareTo') ??
            EvalBridgeFunction(
                super.compareTo, (_x) => EvalInt(_x as int));
      case 'hashCode':
        final _f = evalBridgeTryGetField('hashCode');
        if (_f != null) return _f;
        final _v = super.hashCode;
        if (_v == null) return EvalNull();
        return EvalInt(_v);

      case 'toUtc':
        return evalBridgeTryGetField('toUtc') ??
            EvalBridgeFunction(
                super.toUtc, evalMakeWrapper);
      case 'toString':
        return evalBridgeTryGetField('toString') ??
            EvalBridgeFunction(
                super.toString, (_x) => EvalString(_x as String));
      case 'toIso8601String':
        return evalBridgeTryGetField('toIso8601String') ??
            EvalBridgeFunction(
                super.toIso8601String, (_x) => EvalString(_x as String));
      case 'add':
        return evalBridgeTryGetField('add') ??
            EvalBridgeFunction(super.add, evalMakeWrapper);
      case 'subtract':
        return evalBridgeTryGetField('subtract') ??
            EvalBridgeFunction(
                super.subtract, evalMakeWrapper);
      case 'millisecondsSinceEpoch':
        final _f = evalBridgeTryGetField('millisecondsSinceEpoch');
        if (_f != null) return _f;
        final _v = super.millisecondsSinceEpoch;
        if (_v == null) return EvalNull();
        return EvalInt(_v);
      case 'microsecondsSinceEpoch':
        final _f = evalBridgeTryGetField('microsecondsSinceEpoch');
        if (_f != null) return _f;
        final _v = super.microsecondsSinceEpoch;
        if (_v == null) return EvalNull();
        return EvalInt(_v);
      case 'timeZoneName':
        final _f = evalBridgeTryGetField('timeZoneName');
        if (_f != null) return _f;
        final _v = super.timeZoneName;
        if (_v == null) return EvalNull();
        return EvalString(_v);
      case 'year':
        final _f = evalBridgeTryGetField('year');
        if (_f != null) return _f;
        final _v = super.year;
        if (_v == null) return EvalNull();
        return EvalInt(_v);
      case 'month':
        final _f = evalBridgeTryGetField('month');
        if (_f != null) return _f;
        final _v = super.month;
        if (_v == null) return EvalNull();
        return EvalInt(_v);
      case 'day':
        final _f = evalBridgeTryGetField('day');
        if (_f != null) return _f;
        final _v = super.day;
        if (_v == null) return EvalNull();
        return EvalInt(_v);
      case 'hour':
        final _f = evalBridgeTryGetField('hour');
        if (_f != null) return _f;
        final _v = super.hour;
        if (_v == null) return EvalNull();
        return EvalInt(_v);
      case 'minute':
        final _f = evalBridgeTryGetField('minute');
        if (_f != null) return _f;
        final _v = super.minute;
        if (_v == null) return EvalNull();
        return EvalInt(_v);
      case 'second':
        final _f = evalBridgeTryGetField('second');
        if (_f != null) return _f;
        final _v = super.second;
        if (_v == null) return EvalNull();
        return EvalInt(_v);
      case 'millisecond':
        final _f = evalBridgeTryGetField('millisecond');
        if (_f != null) return _f;
        final _v = super.millisecond;
        if (_v == null) return EvalNull();
        return EvalInt(_v);
      case 'microsecond':
        final _f = evalBridgeTryGetField('microsecond');
        if (_f != null) return _f;
        final _v = super.microsecond;
        if (_v == null) return EvalNull();
        return EvalInt(_v);
      case 'weekday':
        final _f = evalBridgeTryGetField('weekday');
        if (_f != null) return _f;
        final _v = super.weekday;
        if (_v == null) return EvalNull();
        return EvalInt(_v);
      default:
        return super.evalGetField(name, internalGet: internalGet);
    }
  }
}