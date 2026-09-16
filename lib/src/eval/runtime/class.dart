import 'runtime.dart';

/// Interface for objects with a backing value. Those can be stored to the
/// execution frame and passed as arguments. Related to this is the term
/// "boxing" (and "unboxing"): wrapping an object in a [$Value] (usually
/// by calling a "wrap" method), and unwrapping (with [$value]).
abstract class $Value {
  /// Index of the class [Type] in the runtime dictionary. By definition
  /// can change from run to run, so it's customary to use [Runtime.lookupType]
  /// in implementations.
  int $getRuntimeType(Runtime runtime);

  /// The backing Dart value of this [$Value].
  dynamic get $value;

  /// Fully reify the underlying value so it can be used in a Dart context.
  /// For example, recursively transform collections into their underlying
  /// [$value]s.
  dynamic get $reified;
}

/// Interface for objects with properties and methods. Given the nature
/// of Dart (that virtually everything is an object), most classes
/// (including wrappers) implement this interface.
abstract class $Instance implements $Value {
  /// Get a property by [identifier] on this instance
  $Value? $getProperty(Runtime runtime, String identifier);

  /// Set a property by [identifier] on this instance to [value]
  void $setProperty(Runtime runtime, String identifier, $Value value);
}
