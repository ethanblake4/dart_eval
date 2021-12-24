import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/declaration.dart';
import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

/// Interface for objects with a backing value
abstract class EvalValue {
  dynamic get $value;
  dynamic get $reified;
}

/// Implementation for objects with a backing value
mixin EvalValueImpl<T> implements EvalValue {
  /// The backing Dart value
  @override
  late T $value;

  /// Transform this value into a Dart value, fully usable outside Eval
  /// This includes recursively transforming values inside collections
  @override
  T get $reified => $value;
}

/// Instance
abstract class EvalInstance implements EvalValue {
  EvalValue? $getProperty(Runtime runtime, String identifier);

  void $setProperty(Runtime runtime, String identifier, EvalValue value);
}

class EvalInstanceImpl implements EvalInstance {

  final EvalClass _evalClass;

  @override
  final EvalInstance? evalSuperclass;
  late final List<Object?> values;

  EvalInstanceImpl(this._evalClass, this.evalSuperclass, this.values);

  EvalClass get evalClass => _evalClass;

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    final getter = _evalClass.getters[identifier];
    if (getter == null) {
      final method = _evalClass.methods[identifier];
      if (method == null) {
        return evalSuperclass?.$getProperty(runtime, identifier);
      }
      return EvalFunctionPtr(this, method);
    }
    runtime.pushArg(this);
    runtime.bridgeCall(getter);
    return runtime.returnValue as EvalValue;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {
    final setter = _evalClass.setters[identifier];
    if (setter == null) {
      if (evalSuperclass != null) {
        return evalSuperclass!.$setProperty(runtime, identifier, value);
      } else {
        throw EvalUnknownPropertyException(identifier);
      }
    }

    runtime.pushArg(this);
    runtime.pushArg(value);
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
  set $value(_evalValue) {
    throw UnimplementedError();
  }

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    throw UnimplementedError();
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {
    throw UnimplementedError();
  }

  @override
  EvalInstance? get evalSuperclass => throw UnimplementedError();

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
  EvalClass get _evalClass => throw UnimplementedError();

  @override
  // TODO: implement evalClass
  get evalClass => throw UnimplementedError();

  @override
  set values(List<Object?> _values) => throw UnimplementedError();
}