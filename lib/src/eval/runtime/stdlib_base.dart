import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';

import 'class.dart';

class DbcNull implements DbcValueInterface {
  const DbcNull();

  @override
  Null get evalValue => null;

  @override
  Null get reifiedValue => null;
}

class DbcObject implements DbcInstance {
  DbcObject();

  @override
  dynamic get evalValue => null;

  @override
  dynamic get reifiedValue => evalValue;

  @override
  DbcInstance? get evalSuperclass => null;

  @override
  DbcValue? evalGetProperty(String identifier) {
    throw UnimplementedError();
  }

  @override
  void evalSetProperty(String identifier, DbcValueInterface value) {
    throw UnimplementedError();
  }
}

class DbcNum<T extends num> implements DbcInstance {
  DbcNum(this.evalValue);

  @override
  T evalValue;

  @override
  DbcValueInterface? evalGetProperty(String identifier) {
    switch(identifier) {
      case '+':
        return __plus;
      case '-':
        return __minus;
    }
    return evalSuperclass.evalGetProperty(identifier);
  }

  @override
  void evalSetProperty(String identifier, DbcValueInterface value) {

  }

  @override
  DbcInstance evalSuperclass = DbcObject();

  @override
  T get reifiedValue => evalValue;

  static const DbcFunctionImpl __plus = DbcFunctionImpl(_plus);
  static DbcValueInterface? _plus(DbcVmInterface vm, DbcValueInterface? target, List<DbcValueInterface?> args) {
    final other = args[0];
    final _evalResult = target!.evalValue + other!.evalValue;

    if (_evalResult is int) {
      return DbcInt(_evalResult);
    }
    if (_evalResult is double) {
      return DbcDouble(_evalResult);
    }

    throw UnimplementedError();
  }

  static const DbcFunctionImpl __minus = DbcFunctionImpl(_minus);
  static DbcValueInterface? _minus(DbcVmInterface vm, DbcValueInterface? target, List<DbcValueInterface?> args) {
    final other = args[0];
    final _evalResult = target!.evalValue - other!.evalValue;

    if (_evalResult is int) {
      return DbcInt(_evalResult);
    }
    if (_evalResult is double) {
      return DbcDouble(_evalResult);
    }

    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DbcNum && runtimeType == other.runtimeType && evalValue == other.evalValue;

  @override
  int get hashCode => evalValue.hashCode;
}

class DbcInt extends DbcNum<int> {

  DbcInt(int evalValue) : super(evalValue);

  @override
  DbcValueInterface? evalGetProperty(String identifier) {
    return super.evalGetProperty(identifier);
  }

  @override
  void evalSetProperty(String identifier, DbcValueInterface value) {
    return super.evalSetProperty(identifier, value);
  }

  @override
  DbcInstance get evalSuperclass => throw UnimplementedError();

  @override
  int get reifiedValue => evalValue;

  @override
  String toString() {
    return evalValue.toString();
  }
}

class DbcDouble extends DbcNum<double> {

  DbcDouble(double evalValue) : super(evalValue);

  @override
  DbcValueInterface? evalGetProperty(String identifier) {
    return super.evalGetProperty(identifier);
  }

  @override
  void evalSetProperty(String identifier, DbcValueInterface value) {
    return super.evalSetProperty(identifier, value);
  }

  @override
  DbcInstance get evalSuperclass => throw UnimplementedError();

  @override
  double get reifiedValue => evalValue;
}

class DbcInvocation implements DbcInstance {

  DbcInvocation.getter(this.positionalArguments);

  final DbcList2? positionalArguments;

  @override
  DbcValueInterface? evalGetProperty(String identifier) {
    switch (identifier) {
      case 'positionalArguments':
        return positionalArguments;
    }
  }

  @override
  void evalSetProperty(String identifier, DbcValueInterface value) {

  }

  @override
  DbcInstance? get evalSuperclass => throw UnimplementedError();

  @override
  dynamic get evalValue => throw UnimplementedError();

  @override
  dynamic get reifiedValue => throw UnimplementedError();

}


class DbcList2 implements DbcInstance {

  DbcList2(this.evalValue);

  @override
  final List<DbcValue> evalValue;

  @override
  DbcInstance evalSuperclass = DbcObject();

  @override
  DbcValueInterface? evalGetProperty(String identifier) {
    switch (identifier) {
      case '[]':

    }
  }

  @override
  void evalSetProperty(String identifier, DbcValueInterface value) {
    throw EvalUnknownPropertyException(identifier);
  }



  @override
  List get reifiedValue => evalValue.map((e) => e.reifiedValue).toList();
}