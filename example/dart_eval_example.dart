import 'package:dart_eval/dart_eval.dart';

// *** Class definitions. ***                                                            //
//
// NOTE: In order to use these within dart_eval, scroll to the end of the file           //
// to see an example of the necessary boilerplate (will be auto-generated in the future) //

class TimestampedTime {
  const TimestampedTime(this.utcTime, {this.timezoneOffset = 0});

  final int utcTime;
  final int timezoneOffset;
}

abstract class WorldTimeTracker {
  WorldTimeTracker();

  TimestampedTime getTimeFor(String country);
}

// *** Main code *** //

void main() {
  // Setup a parser
  final parser = Parse();

  // Add our class definitions
  parser.define(EvalTimestampedTime.declaration);
  parser.define(EvalWorldTimeTracker.declaration);

  // Parse the code we want to run. The scope variable now holds
  // all top-level declared classes and functions, ready to run
  final scope = parser.parse('''
    class MyWorldTimeTracker extends WorldTimeTracker {
    
      MyWorldTimeTracker();
      
      final countries = <String, TimestampedTime> {
        'USA': _currentTimeWithOffset(4),
        'UK': _currentTimeWithOffset(6),
      };
      
      static TimestampedTime _currentTimeWithOffset(int offset) {
        return TimestampedTime(DateTime.now().millisecondsSinceEpoch,
          timezoneOffset: offset);
      }
            
      @override
      TimestampedTime getTimeFor(String country) {
        return countries[country];
      }
    }
    
    MyWorldTimeTracker fn(String country) {
      final timeTracker = MyWorldTimeTracker();
      final myTime = timeTracker.getTimeFor(country);
      
      print(country + ' timezone offset: ' + myTime.timezoneOffset.toString() + ' (from Eval!)');
      
      return timeTracker;
    }
    ''');

  // The returned scope is a callable class, so it's easy to call your method
  final timeTracker =
      scope('fn', [Parameter(EvalString('USA'))]) as WorldTimeTracker;

  print('UK timezone offset: ' +
      timeTracker.getTimeFor('UK').timezoneOffset.toString() +
      ' (from outside Eval!)');
}

///////////////////////////////////////////////////////////////////////////////////////////
// *** Start of required boilerplate code. This can be auto-generated in the future. *** //
///////////////////////////////////////////////////////////////////////////////////////////

// Create a library-local lexical scope so that all classes and functions within
// a library can always access each other. Inherit from the empty scope.
final _libraryLexicalScope = EvalScope(EvalScope.empty, {});

// Define the type of the class, which includes its name, the library it's defined in, and
// what it inherits from (Object in this case => EvalType.objectType)
final timestampedTimeType = EvalType('TimestampedTime', 'TimestampedTime',
    'package:dart_eval/dart_eval_example.dart', [EvalType.objectType], true);

/// Extend the original class with the below mixins
class EvalTimestampedTime extends TimestampedTime
    with
        ValueInterop<EvalTimestampedTime>,
        EvalBridgeObjectMixin<EvalTimestampedTime>,
        BridgeRectifier<EvalTimestampedTime> {
  /// Create constructors for each of the original class's constructors
  EvalTimestampedTime(int utcTime, {int timezoneOffset = 0})
      : super(utcTime, timezoneOffset: timezoneOffset);

  /// Create a [BridgeInstantiator] to instantiate this class.
  /// If you had multiple constructors in your class you would use a switch statement
  /// on the constructor parameter to choose which one to call
  static final BridgeInstantiator<EvalTimestampedTime> _evalInstantiator =
      (String constructor, List<dynamic> pos, Map<String, dynamic> named) {
    return EvalTimestampedTime(pos[0], timezoneOffset: named['timezoneOffset']);
  };

  // Define the declaration, which creates the static class reference with the correct library lexical scope
  static final declaration = DartBridgeDeclaration(
      visibility: DeclarationVisibility.PUBLIC,
      declarator: (ctx, lex, cur) => {
            'TimestampedTime': EvalField(
                'TimestampedTime', cls = clsgen(lex), null, Getter(null))
          });

  /// Define the static class reference. This should include all static methods
  /// and fields, as well as constructors which are effectively static.
  static final clsgen = (lexicalScope) => EvalBridgeClass([
        DartConstructorDeclaration('', [
          ParameterDefinition(
              'utcTime', EvalType.intType, false, false, false, true, null,
              isField: true),
          ParameterDefinition('timezoneOffset', EvalType.intType, false, true,
              true, false, null,
              isField: false)
        ])
      ], timestampedTimeType, lexicalScope, TimestampedTime, _evalInstantiator);

  static late EvalBridgeClass cls;

  /// Create an instance of [EvalBridgeData] so that dart_eval can store information
  /// about any changes it's made to a psuedo-subclass of this class when extending it
  @override
  EvalBridgeData evalBridgeData = EvalBridgeData(cls);

  /// Not required, but recommended: create a utility method for wrapping an existing,
  /// external instance of the original class in an Eval-friendly wrapper.
  ///
  /// If another class "Class A" in your app - outside of Eval - returns an instance
  /// of the original class "Class B" in a method or getter, and then make
  /// Class A Bridge-compatible, you will have to wrap that return value.
  ///
  /// Doing it in the source class is the best way to ensure code reuse and ease of
  /// future updates.
  static EvalValue evalMakeWrapper(TimestampedTime? target) {
    if (target == null) {
      return EvalNull();
    }
    return EvalRealObject(target, cls: cls, fields: {
      'utcTime': EvalField(
          'utcTime',
          null,
          null,
          Getter(EvalCallableImpl((lexical, inherited, generics, args,
                  {target}) =>
              EvalInt(target?.realValue!.utcTime!)))),
      'timezoneOffset': EvalField(
          'timezoneOffset',
          null,
          null,
          Getter(EvalCallableImpl((lexical, inherited, generics, args,
                  {target}) =>
              EvalInt(target?.realValue!.timezoneOffset!))))
    });
  }

  /// For each getter and setter: attempt to set/get the property
  /// using [evalBridgeTryGetField] first.
  @override
  int get utcTime {
    final _f = evalBridgeTryGetField('utcTime');
    if (_f != null) return _f.evalReifyFull();
    return super.utcTime;
  }

  @override
  int get timezoneOffset {
    final _f = evalBridgeTryGetField('timezoneOffset');
    if (_f != null) return _f.evalReifyFull();
    return super.timezoneOffset;
  }

  /// Override the [evalGetField] method to give Eval access to your class's base
  /// fields and methods.
  /// You'll have to wrap the return values in an Eval class - these are defined
  /// for built-in Dart types (e.g. [EvalInt], [EvalString]) - but for your own
  /// classes you'll want to use static definitions of [evalMakeWrapper].
  @override
  EvalValue evalGetField(String name, {bool internalGet = false}) {
    switch (name) {
      case 'utcTime':
        final _f = evalBridgeTryGetField('utcTime');
        if (_f != null) return _f;
        return EvalInt(super.utcTime);
      case 'timezoneOffset':
        final _f = evalBridgeTryGetField('timezoneOffset');
        if (_f != null) return _f;
        return EvalInt(super.timezoneOffset);
      default:
        return super.evalGetField(name, internalGet: internalGet);
    }
  }
}

final worldTimeTrackerType = EvalType('WorldTimeTracker', 'WorldTimeTracker',
    'package:dart_eval/dart_eval_example.dart', [EvalType.objectType], true);

class EvalWorldTimeTracker extends WorldTimeTracker
    with
        ValueInterop<EvalWorldTimeTracker>,
        EvalBridgeObjectMixin<EvalWorldTimeTracker>,
        BridgeRectifier<EvalWorldTimeTracker> {
  EvalWorldTimeTracker() : super();

  static final BridgeInstantiator<EvalWorldTimeTracker> _evalInstantiator =
      (String constructor, List<dynamic> pos, Map<String, dynamic> named) {
    return EvalWorldTimeTracker();
  };

  static final declaration = DartBridgeDeclaration(
      visibility: DeclarationVisibility.PUBLIC,
      declarator: (ctx, lex, cur) => {
            'WorldTimeTracker': EvalField(
                'WorldTimeTracker', cls = clsgen(lex), null, Getter(null))
          });

  static final clsgen = (lexicalScope) => EvalBridgeClass(
      [DartConstructorDeclaration('', [])],
      worldTimeTrackerType,
      _libraryLexicalScope,
      WorldTimeTracker,
      _evalInstantiator);

  static late EvalBridgeClass cls;

  @override
  EvalBridgeData evalBridgeData = EvalBridgeData(cls);

  static EvalValue evalMakeWrapper(WorldTimeTracker? target) {
    if (target == null) {
      return EvalNull();
    }
    return EvalRealObject(target, cls: cls);
  }

  /// Use [bridgeCall] to override methods
  @override
  TimestampedTime getTimeFor(String country) =>
      bridgeCall('getTimeFor', [EvalString(country)]);

  @override
  EvalValue evalGetField(String name, {bool internalGet = false}) {
    switch (name) {
      case 'getTimeFor':
        return evalBridgeTryGetField('getTimeFor') ??
            (throw Exception(
                'Cannot access method getTimeFor() of an abstract class'));
      default:
        return super.evalGetField(name, internalGet: internalGet);
    }
  }
}
