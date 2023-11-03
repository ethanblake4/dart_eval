import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

/// Interface for objects with a backing value
abstract class $Value {
  int $getRuntimeType(Runtime runtime);

  /// The backing Dart value of this [$Value]
  dynamic get $value;

  /// Fully reify the underlying value so it can be used in a Dart context.
  /// For example, recursively transform collections into their underlying
  /// [$value]s.
  dynamic get $reified;
}

/// Interface for objects with properties and methods
abstract class $Instance implements $Value {
  /// Get a property by [identifier] on this instance
  $Value? $getProperty(Runtime runtime, String identifier);

  /// Set a property by [identifier] on this instance to [value]
  void $setProperty(Runtime runtime, String identifier, $Value value);
}

class $InstanceImpl implements $Instance {
  final EvalClass evalClass;
  final $Instance? evalSuperclass;
  late final List<Object?> values;

  $InstanceImpl(this.evalClass, this.evalSuperclass, this.values);

  @override
  int $getRuntimeType(Runtime runtime) => evalClass.delegatedType;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    final getter = evalClass.getters[identifier];
    if (getter == null) {
      final method = evalClass.methods[identifier];
      if (method == null) {
        return evalSuperclass?.$getProperty(runtime, identifier);
      }
      return EvalStaticFunctionPtr(this, method);
    }
    runtime.args.add(this);
    runtime.bridgeCall(getter);
    return runtime.returnValue as $Value;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    final setter = evalClass.setters[identifier];
    if (setter == null) {
      if (evalSuperclass != null) {
        return evalSuperclass!.$setProperty(runtime, identifier, value);
      } else {
        throw EvalUnknownPropertyException(identifier);
      }
    }

    runtime.args.add(this);
    runtime.args.add(value);
    runtime.bridgeCall(setter);
  }

  @override
  Never get $reified => throw UnimplementedError();

  @override
  Never get $value => throw UnimplementedError();
}
