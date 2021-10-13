import 'package:dart_eval/src/dbc/dbc_exception.dart';
import 'package:dart_eval/src/dbc/dbc_function.dart';

import 'dbc_class.dart';
import 'dbc_executor.dart';

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

class DbcList extends DbcInstanceImpl {
  DbcList(DbcExecutor exec, Map<String, int> lookupGetter, Map<String, int> lookupSetter)
      : super(DbcObject()) {
    evalValue = [];
  }
}
