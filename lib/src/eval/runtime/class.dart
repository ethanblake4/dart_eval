import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

/// Interface for objects with a backing value
abstract class $Value {
  int get $runtimeType;

  /// The backing Dart value of this [$Value]
  dynamic get $value;

  /// Fully reify the underlying value so it can be used in a Dart context.
  /// For example, recursively transform collections into their underlying
  /// [$value]s.
  dynamic get $reified;
}

/// Implementation for objects with a backing value
class $ValueImpl<T> implements $Value {
  const $ValueImpl(this.$runtimeType, this.$value);

  @override
  final int $runtimeType;

  /// The backing Dart value
  @override
  final T $value;

  /// Transform this value into a Dart value, fully usable outside Eval
  /// This includes recursively transforming values inside collections
  @override
  T get $reified => $value;
}

/// Instance
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
  int get $runtimeType => evalClass.delegatedType;

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

class EvalTypeClass implements EvalClass {
  EvalTypeClass();

  @override
  Never get $value => throw UnimplementedError();

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    throw UnimplementedError();
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError();
  }

  @override
  $Instance? get evalSuperclass => throw UnimplementedError();

  @override
  Never get $reified => throw UnimplementedError();

  @override
  List<Object> get values => const [];

  @override
  Map<String, int> get getters => throw UnimplementedError();

  @override
  Map<String, int> get methods => throw UnimplementedError();

  @override
  List<EvalClass?> get mixins => throw UnimplementedError();

  @override
  Map<String, int> get setters => throw UnimplementedError();

  @override
  EvalClass? get superclass => throw UnimplementedError();

  @override
  EvalClass get evalClass => throw UnimplementedError();

  @override
  set values(List<Object?> _values) => throw UnimplementedError();

  @override
  int get $runtimeType => throw UnimplementedError();

  @override
  int get delegatedType => throw UnimplementedError();
}
