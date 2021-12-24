import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/declaration.dart';
import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/stdlib_base.dart';

/// Interface for objects with a backing value
abstract class IDbcValue {
  dynamic get $value;
  dynamic get $reified;
}

/// Implementation for objects with a backing value
mixin DbcValue implements IDbcValue {
  /// The backing Dart value
  @override
  dynamic $value;

  /// Transform this value into a Dart value, fully usable outside Eval
  /// This includes recursively transforming values inside collections
  @override
  dynamic get $reified => $value;
}

/// Instance
abstract class DbcInstance implements IDbcValue {
  IDbcValue? $getProperty(Runtime runtime, String identifier);

  void $setProperty(Runtime runtime, String identifier, IDbcValue value);
}

class DbcInstanceImpl with DbcValue implements DbcInstance {

  final DbcClass _evalClass;

  @override
  final DbcInstance? evalSuperclass;
  late final List<Object?> values;

  DbcInstanceImpl(this._evalClass, this.evalSuperclass, this.values);

  DbcClass get evalClass => _evalClass;

  @override
  IDbcValue? $getProperty(Runtime runtime, String identifier) {
    final getter = _evalClass.getters[identifier];
    if (getter == null) {
      final method = _evalClass.methods[identifier];
      if (method == null) {
        return evalSuperclass?.$getProperty(runtime, identifier);
      }
      return DbcFunctionPtr(this, method);
    }
    runtime.pushArg(this);
    runtime.bridgeCall(getter);
    return runtime.returnValue as IDbcValue;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, IDbcValue value) {
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
}

class DbcTypeClass implements DbcClass {

  DbcTypeClass._internal();

  factory DbcTypeClass() {
    return DbcTypeClass._internal();
  }


  @override
  Never get $value => throw UnimplementedError();

  @override
  set $value(_evalValue) {
    throw UnimplementedError();
  }

  @override
  IDbcValue? $getProperty(Runtime runtime, String identifier) {
    throw UnimplementedError();
  }

  @override
  void $setProperty(Runtime runtime, String identifier, IDbcValue value) {
    throw UnimplementedError();
  }

  @override
  DbcInstance? get evalSuperclass => throw UnimplementedError();

  @override
  Never get $reified => throw UnimplementedError();

  @override
  List<Object> get values => const [];

  @override
  Map<String, int> get getters => throw UnimplementedError();

  @override
  Map<String, int> get methods => throw UnimplementedError();

  @override
  List<DbcClass?> get mixins => throw UnimplementedError();

  @override
  Map<String, int> get setters => throw UnimplementedError();

  @override
  DbcClass? get superclass => throw UnimplementedError();

  @override
  DbcClass get _evalClass => throw UnimplementedError();

  @override
  // TODO: implement evalClass
  get evalClass => throw UnimplementedError();

  @override
  set values(List<Object?> _values) => throw UnimplementedError();

}

class DbcBridgeData {
  final Runtime runtime;
  final DbcInstance? subclass;

  const DbcBridgeData(this.runtime, this.subclass);
}