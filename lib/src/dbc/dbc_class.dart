import 'package:dart_eval/src/dbc/dbc_declaration.dart';
import 'package:dart_eval/src/dbc/dbc_exception.dart';
import 'package:dart_eval/src/dbc/dbc_function.dart';
import 'package:dart_eval/src/dbc/dbc_stdlib_base.dart';

/// Interface for objects with a backing value
abstract class DbcValueInterface {
  dynamic get evalValue;
  dynamic get reifiedValue;
}

/// Implementation for objects with a backing value
mixin DbcValue implements DbcValueInterface {
  /// The backing Dart value
  @override
  dynamic evalValue;

  /// Transform this value into a Dart value, fully usable outside Eval
  /// This includes recursively transforming values inside collections
  @override
  dynamic get reifiedValue => evalValue;
}

/// Instance
abstract class DbcInstance implements DbcValueInterface {
  static DbcClass get evalClass => throw UnimplementedError();

  DbcInstance? get evalSuperclass;

  DbcValueInterface? evalGetProperty(String identifier);

  //DbcValueInterface? evalNoSuchMethod(Invocation invocation);

  void evalSetProperty(String identifier, DbcValueInterface value);
}

class DbcInstanceImpl with DbcValue implements DbcInstance {

  static late final DbcClass evalClass;

  @override
  final DbcInstance? evalSuperclass;
  final List<Object> values = [];

  DbcInstanceImpl(this.evalSuperclass);

  @override
  DbcValueInterface? evalGetProperty(String identifier) {
    final exec = evalClass.evalVm.exec;
    final getter = evalClass.getters[identifier];
    if (getter == null) return evalSuperclass?.evalGetProperty(identifier);
    exec.beginBridgedScope();
    exec.push(this);
    exec.execute(getter);
    exec.popScope();
    return exec.returnValue;
  }

  @override
  void evalSetProperty(String identifier, DbcValueInterface value) {
    final vm = evalClass.evalVm;
    final setter = evalClass.setters[identifier];
    if (setter == null) {
      if (evalSuperclass != null) {
        return evalSuperclass!.evalSetProperty(identifier, value);
      } else {
        throw EvalUnknownPropertyException(identifier);
      }
    }

    vm.exec.beginBridgedScope();
    vm.exec.push(this);
    vm.exec.push(value);
    vm.exec.execute(setter);
    vm.exec.popScope();
  }
}

class DbcTypeClass implements DbcClass {

  DbcTypeClass._internal(this.evalVm);

  factory DbcTypeClass(DbcVmInterface vm) {
    return _cache[vm] ?? (_cache[vm] = DbcTypeClass._internal(vm));
  }

  static final Map<DbcVmInterface, DbcTypeClass> _cache = {};

  @override
  final DbcVmInterface evalVm;

  @override
  Never get evalValue => throw UnimplementedError();

  @override
  set evalValue(_evalValue) {
    throw UnimplementedError();
  }

  @override
  DbcValueInterface? evalGetProperty(String identifier) {
    throw UnimplementedError();
  }

  @override
  void evalSetProperty(String identifier, DbcValueInterface value) {
    throw UnimplementedError();
  }

  @override
  DbcInstance? get evalSuperclass => throw UnimplementedError();

  @override
  Never get reifiedValue => throw UnimplementedError();

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
}

class DbcBridgeData {
  final DbcVmInterface vm;
  final DbcInstance? evalSuperclass;
  final Map<String, int> lookupGetter;
  final Map<String, int> lookupSetter;

  DbcBridgeData(this.vm, this.evalSuperclass, this.lookupGetter, this.lookupSetter);

  DbcBridgeData.ofClass(DbcClass cls): this(cls.evalVm, DbcObject(), {}, {});
}

mixin DbcBridgeInstance on DbcValue implements DbcInstance {

  DbcBridgeData get evalData;

  @override
  DbcInstance? get evalSuperclass => evalData.evalSuperclass;

  DbcValueInterface? evalBridgeGetOverriddenProperty(String identifier) {
    return evalSuperclass!.evalGetProperty(identifier);
  }

  bool evalBridgeSetOverriddenProperty(String identifier, DbcValueInterface value) {
    try {
      evalSuperclass!.evalSetProperty(identifier, value);
      return true;
    } on EvalUnknownPropertyException catch (_) {
      return false;
    }
  }
}

class Dx with DbcValue, DbcBridgeInstance {

  static late final DbcClass evalClass;

  @override
  DbcBridgeData evalData = DbcBridgeData.ofClass(evalClass);

  @override
  DbcValueInterface? evalGetProperty(String identifier) {

    final overridden = evalBridgeGetOverriddenProperty(identifier);
    if (overridden != null) {
      return overridden;
    }

    switch (identifier) {
      case 'someData':
        return DbcObject();
      //case 'noSuchMethod':
      //  throw NoSuchMethodError.withInvocation(this, Invocation.method(memberName, positionalArguments))
      default:

    }
  }

  @override
  void evalSetProperty(String identifier, DbcValueInterface value) {
    if (evalBridgeSetOverriddenProperty(identifier, value)) {
      return;
    }
    switch (identifier) {
      default:
    }
  }
}