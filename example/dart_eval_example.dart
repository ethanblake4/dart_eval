import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

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

void main(List<String> args) {
  final source = '''
    import 'package:example/bridge.dart';
    
    class MyWorldTimeTracker extends WorldTimeTracker {
    
      MyWorldTimeTracker();
      
      static TimestampedTime _currentTimeWithOffset(int offset) {
        return TimestampedTime(DateTime.now().millisecondsSinceEpoch,
          timezoneOffset: offset);
      }
      
      @override
      TimestampedTime getTimeFor(String country) {
        final countries = <String, TimestampedTime> {
          'USA': _currentTimeWithOffset(4),
          'UK': _currentTimeWithOffset(6),
        };
      
        return countries[country];
      }
    }
    
    MyWorldTimeTracker fn(String country) {
      final timeTracker = MyWorldTimeTracker();
      final myTime = timeTracker.getTimeFor(country);
      
      print(country + ' timezone offset: ' + myTime.timezoneOffset.toString() + ' (from Eval!)');
      
      return timeTracker;
    }
  ''';

  // Create a compiler and define the classes' bridge declarations so it knows their structure
  final compiler = Compiler();
  compiler.defineBridgeClasses([$TimestampedTime.$declaration, $WorldTimeTracker$bridge.$declaration]);

  // Compile the source code into a Program containing metadata and bytecode. In a real app, you would likely
  // compile the Eval code separately and output it to a file using program.write(), sharing only bridge classes
  // with a local shared library
  final program = compiler.compile({
    'example': {'main.dart': source}
  });

  // Create a runtime from the compiled program, and register bridge functions for all static methods and constructors.
  // Default constructors use "ClassName." syntax.
  final runtime = Runtime.ofProgram(program)
    ..registerBridgeFunc('package:example/bridge.dart', 'TimestampedTime.', $TimestampedTime.$new)
    ..registerBridgeFunc('package:example/bridge.dart', 'WorldTimeTracker.', $WorldTimeTracker$bridge.$new);

  // Call runtime.setup() after registering all bridge functions
  runtime.setup();

  // Specify some args for the function we're about to call. Except for [int]s, [double]s, [bool]s, and [List]s, use
  // [$Value] wrappers. For named args, specify them in order using null to represent an unspecified arg.
  runtime.args = [$String('USA')];

  // Call the function and cast the result to the desired type
  final timeTracker = runtime.executeLib('package:example/main.dart', 'fn') as WorldTimeTracker;

  // We can now utilize the returned bridge class
  print('UK timezone offset: ' + timeTracker.getTimeFor('UK').timezoneOffset.toString() + ' (from outside Eval!)');
}

///////////////////////////////////////////////////////////////////////////////////////////
// *** Start of required boilerplate code. This can be auto-generated in the future. *** //
///////////////////////////////////////////////////////////////////////////////////////////

/// Create a wrapper for [TimestampedTime]. A wrapper is a performant interop solution
/// when you *don't* need the ability to override the class within the dart_eval VM.
class $TimestampedTime implements TimestampedTime, $Instance {
  /// Create a wrap constructor. We're not implementing the default constructor here, but if you
  /// were to it'd typically be a runtimeOverride() constructor. You can read more details
  /// about runtime overrides on dart_eval's GitHub wiki page for wrappers. The wrap constructor
  /// wraps an underlying instance and inherits from [$Object].
  $TimestampedTime.wrap(this.$value) : _superclass = $Object($value);

  /// Define the compile-time type descriptor as an unresolved type
  static const $type = BridgeTypeRef.spec(BridgeTypeSpec('package:example/bridge.dart', 'TimestampedTime'));

  /// Define the compile-time class declaration and map out all the fields and methods for the compiler.
  static const $declaration = BridgeClassDef(BridgeClassType($type), constructors: {
    // Define the default constructor with an empty string
    '': BridgeConstructorDef(BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
      // Parameters using built-in types can use [RuntimeTypes] for the most common types. Others, like
      // Future, may need to use a type spec for 'dart:core'.
      BridgeParameter('utcTime', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false)
    ], namedParams: [
      BridgeParameter('timezoneOffset', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), true)
    ]))
  }, methods: {}, getters: {}, setters: {}, fields: {
    'utcTime': BridgeFieldDef(BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType))),
    'timezoneOffset': BridgeFieldDef(BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)))
  });

  /// Define static [EvalCallableFunc] functions for all static methods and constructors. This is for the
  /// default constructor and is what the runtime will use to create an instance of this class.
  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $TimestampedTime.wrap(TimestampedTime(args[0]!.$value, timezoneOffset: args[1]?.$value ?? 0));
  }

  /// The underlying Dart instance that this wrapper wraps
  @override
  final TimestampedTime $value;

  /// In most cases [$reified] should just return [$value]. However, classes with generics may use
  /// it to fully reify any properties they contain. For example, a dart_eval List will typically be
  /// filled with [$Value] objects, but using [$reified] will convert it to a List of Dart values.
  @override
  TimestampedTime get $reified => $value;

  /// Although not required, creating a superclass field allows you to inherit basic properties from
  /// [$Object], such as == and hashCode.
  final $Instance _superclass;

  /// [$getProperty] is how dart_eval accesses a wrapper's properties and methods, so map them out here. In
  /// the default case, fall back to our [_superclass] implementation. For methods, you would return
  /// a [$Function] with a closure (for simplicity) or a custom [EvalFunction] subclass (for maximum performance).
  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'utcTime':
        return $int($value.utcTime);
      case 'timezoneOffset':
        return $int($value.timezoneOffset);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  /// Don't worry about [$runtimeType] for now, it's not currently used and may be removed.
  @override
  int get $runtimeType => throw UnimplementedError();

  /// Map out non-final fields with [$setProperty]. We don't have any here, so just fallback to the Object
  /// implementation. (Although there are no settable fields on Object, in the future it will invoke
  /// noSuchMethod() where appropriate).
  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  /// Finally, our standard [TimestampedTime] implementations! Redirect to the wrapped [$value]'s implementation
  /// for all properties and methods.
  @override
  int get timezoneOffset => $value.timezoneOffset;

  @override
  int get utcTime => $value.utcTime;
}

/// Unlike [TimestampedTime], we need to subclass [WorldTimeTracker]. For that, we can use a bridge class!
/// Bridge classes are flexible and in some ways simpler than wrappers, but they have a lot of overhead. Avoid
/// them if possible in performance-sensitive situations.
///
/// Because [WorldTimeTracker] is abstract, we can implement it here. If it were a concrete class you would instead
/// extend it.
class $WorldTimeTracker$bridge with $Bridge<WorldTimeTracker> implements WorldTimeTracker {
  static const _$type = BridgeTypeRef.spec(BridgeTypeSpec('package:example/bridge.dart', 'WorldTimeTracker'));

  /// Define the compile-time class declaration and map out all the fields and methods for the compiler.
  static const $declaration = BridgeClassDef(BridgeClassType(_$type, isAbstract: true), constructors: {
    // Even though this class is abstract, we currently need to define the default constructor anyway. This
    // may change in the future.
    '': BridgeConstructorDef(BridgeFunctionDef(returns: BridgeTypeAnnotation(_$type), params: [], namedParams: []))
  }, methods: {
    'getTimeFor': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation($TimestampedTime.$type),
        params: [BridgeParameter('country', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.stringType)), false)],
        namedParams: []))
  }, getters: {}, setters: {}, fields: {});

  /// Define static [EvalCallableFunc] functions for all static methods and constructors. This is for the
  /// default constructor and is what the runtime will use to create an instance of this class.
  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $WorldTimeTracker$bridge();
  }

  /// [$bridgeGet] works differently than [$getProperty] - it's only called if the Eval subclass hasn't provided
  /// an override implementation.
  @override
  $Value? $bridgeGet(String identifier) {
    // [WorldTimeTracker] is abstract, so if we haven't overridden all of it's methods that's an error.
    // If it were concrete, this implementation would look like [$getProperty] except you'd access fields
    // and invoke methods on 'super'.
    throw UnimplementedError('Cannot get property "$identifier" on abstract class WorldTimeTracker');
  }

  @override
  void $bridgeSet(String identifier, $Value value) {
    /// Same idea here.
    throw UnimplementedError('Cannot set property "$identifier" on abstract class WorldTimeTracker');
  }

  /// In a bridge class, override all fields and methods with [$_invoke], [$_get], and [$_set]. This
  /// is necessary since we may use the overridden VM implementation outside the VM.
  @override
  TimestampedTime getTimeFor(String country) => $_invoke('getTimeFor', [$String(country)]);
}
