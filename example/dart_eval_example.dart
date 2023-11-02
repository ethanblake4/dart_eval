import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';

// ** Sample class definitions **

class TimestampedTime {
  const TimestampedTime(this.utcTime, {this.timezoneOffset = 0});

  final int utcTime;
  final int timezoneOffset;
}

abstract class WorldTimeTracker {
  WorldTimeTracker();

  TimestampedTime getTimeFor(String country);
}

// ** Main code **

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
  compiler.defineBridgeClasses(
      [$TimestampedTime.$declaration, $WorldTimeTracker$bridge.$declaration]);

  // Compile the source code into a Program containing metadata and bytecode.
  // In a real app, you could also compile the Eval code separately and output
  // it to a file using program.write().
  final program = compiler.compile({
    'example': {'main.dart': source}
  });

  // Create a runtime from the compiled program, and register bridge functions
  // for all static methods and constructors. Default constructors use
  // "ClassName." syntax.
  final runtime = Runtime.ofProgram(program)
    ..registerBridgeFunc('package:example/bridge.dart', 'TimestampedTime.',
        $TimestampedTime.$new)
    ..registerBridgeFunc('package:example/bridge.dart', 'WorldTimeTracker.',
        $WorldTimeTracker$bridge.$new,
        isBridge: true);

  // Call the function and cast the result to the desired type
  final timeTracker = runtime.executeLib(
    'package:example/main.dart',
    'fn',
    // Wrap args in $Value wrappers except int, double, bool, and List
    [$String('USA')],
  ) as WorldTimeTracker;

  // We can now utilize the returned bridge class
  print('UK timezone offset: ${timeTracker.getTimeFor('UK').timezoneOffset}'
      ' (from outside Eval!)');
}

/// Create a wrapper for [TimestampedTime]. A wrapper is a performant interop
/// solution when you *don't* need the ability to override the class within the
/// dart_eval VM.
class $TimestampedTime implements TimestampedTime, $Instance {
  /// Create a wrap constructor, which wraps an underlying instance
  /// and inherits from [$Object].
  $TimestampedTime.wrap(this.$value) : _superclass = $Object($value);

  /// Define this class's compile-time type reference.
  static final $type = BridgeTypeSpec(
    'package:example/bridge.dart',
    'TimestampedTime',
  ).ref;

  /// Define the compile-time class declaration and map out all the fields and
  /// methods for the compiler.
  static final $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {
      // Define the default constructor with an empty string
      '': BridgeFunctionDef(returns: $type.annotate, params: [
        // Parameters using built-in types can use [CoreTypes]
        'utcTime'.param(CoreTypes.int.ref.annotate)
      ], namedParams: [
        'timezoneOffset'.paramOptional(CoreTypes.int.ref.annotate)
      ]).asConstructor
    },
    fields: {
      'utcTime': BridgeFieldDef(CoreTypes.int.ref.annotate),
      'timezoneOffset': BridgeFieldDef(CoreTypes.int.ref.annotate)
    },
    wrap: true,
  );

  /// Define static [EvalCallableFunc] functions for all static methods and
  /// constructors. This is for the default constructor and is what the runtime
  /// will use to create an instance of this class.
  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $TimestampedTime.wrap(TimestampedTime(
      args[0]!.$value,
      timezoneOffset: args[1]?.$value ?? 0,
    ));
  }

  /// The underlying Dart instance that this wrapper wraps
  @override
  final TimestampedTime $value;

  /// In most cases [$reified] should just return [$value], but collection
  /// types like Lists should use it to recursively reify their contents.
  @override
  TimestampedTime get $reified => $value;

  /// Although not required, creating a superclass field allows you to inherit
  /// basic properties from [$Object], such as == and hashCode.
  final $Instance _superclass;

  /// [$getProperty] is how dart_eval accesses a wrapper's properties and methods,
  /// so map them out here. In the default case, fall back to our [_superclass]
  /// implementation. For methods, you would return a [$Function] with a closure.
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

  /// Lookup the runtime type ID
  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  /// Map out non-final fields with [$setProperty]. We don't have any here,
  /// so just fallback to the Object implementation.
  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  /// Finally, our standard [TimestampedTime] implementations! Redirect to the
  /// wrapped [$value]'s implementation for all properties and methods.
  @override
  int get timezoneOffset => $value.timezoneOffset;

  @override
  int get utcTime => $value.utcTime;
}

/// Unlike [TimestampedTime], we need to subclass [WorldTimeTracker]. For that,
/// we can use a bridge class!
///
/// Bridge classes are flexible and in some ways simpler than wrappers, but
/// they have a lot of overhead. Avoid them if possible in performance-sensitive
/// situations.
///
/// Because [WorldTimeTracker] is abstract, we can implement it here.
/// If it were a concrete class you would instead extend it.
class $WorldTimeTracker$bridge
    with $Bridge<WorldTimeTracker>
    implements WorldTimeTracker {
  static final $type = BridgeTypeSpec(
    'package:example/bridge.dart',
    'WorldTimeTracker',
  ).ref;

  /// Again, we map out all the fields and methods for the compiler.
  static final $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      // Even though this class is abstract, we currently need to define
      // the default constructor anyway.
      '': BridgeFunctionDef(returns: $type.annotate).asConstructor
    },
    methods: {
      'getTimeFor': BridgeFunctionDef(
        returns: $TimestampedTime.$type.annotate,
        params: ['country'.param(CoreTypes.string.ref.annotate)],
      ).asMethod
    },
    bridge: true,
  );

  /// Define static [EvalCallableFunc] functions for all static methods and
  /// constructors. This is for the default constructor and is what the runtime
  /// will use to create an instance of this class.
  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $WorldTimeTracker$bridge();
  }

  /// [$bridgeGet] works differently than [$getProperty] - it's only called
  /// if the Eval subclass hasn't provided an override implementation.
  @override
  $Value? $bridgeGet(String identifier) {
    // [WorldTimeTracker] is abstract, so if we haven't overridden all of its
    // methods that's an error.
    // If it were concrete, this implementation would look like [$getProperty]
    // except you'd access fields and invoke methods on 'super'.
    throw UnimplementedError(
      'Cannot get property "$identifier" on abstract class WorldTimeTracker',
    );
  }

  @override
  void $bridgeSet(
    String identifier,
    $Value value,
  ) {
    /// Same idea here.
    throw UnimplementedError(
      'Cannot set property "$identifier" on abstract class WorldTimeTracker',
    );
  }

  /// In a bridge class, override all fields and methods with [$_invoke],
  /// [$_get], and [$_set]. This allows us to override the methods by extending
  /// the class in dart_eval.
  @override
  TimestampedTime getTimeFor(String country) => $_invoke(
        'getTimeFor',
        [$String(country)],
      );
}
