import 'package:dart_eval/src/dbc/dbc_exception.dart';
import 'package:dart_eval/src/dbc/dbc_executor.dart';
import 'package:dart_eval/src/dbc/dbc_stdlib_base.dart';

import 'dbc_class.dart';

typedef DbcCallableFunc = DbcValueInterface? Function(DbcVmInterface vm, DbcValueInterface? target,
    List<DbcValueInterface?> positionalArgs, Map<String, DbcValueInterface?> namedArgs);

abstract class DbcCallable {
  DbcValueInterface? call(DbcVmInterface vm, DbcValueInterface? target, List<DbcValueInterface?> positionalArgs,
      Map<String, DbcValueInterface?> namedArgs);
}

class DbcVmInterface {
  DbcVmInterface(this.exec);

  DbcExecutor exec;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DbcVmInterface && runtimeType == other.runtimeType && exec == other.exec;

  @override
  int get hashCode => exec.hashCode;
}

abstract class DbcFunction implements DbcInstance, DbcCallable {
  @override
  DbcValueInterface? evalGetProperty(String identifier) {
    switch (identifier) {
      case 'call':
        return this;
      default:
        throw EvalUnknownPropertyException(identifier);
    }
  }

  @override
  void evalSetProperty(String identifier, DbcValueInterface value) {
    throw EvalUnknownPropertyException(identifier);
  }

  @override
  DbcInstance? evalSuperclass = DbcObject();

  @override
  dynamic get evalValue => throw UnimplementedError();

  @override
  dynamic get reifiedValue => throw UnimplementedError();
}

class DbcFunctionPtr extends DbcFunction {
  DbcFunctionPtr(this.offset);

  final int offset;

  @override
  DbcValueInterface? call(DbcVmInterface vm, DbcValueInterface? target, List<DbcValueInterface?> positionalArgs,
      Map<String, DbcValueInterface?> namedArgs) {
    final exec = vm.exec;
    exec.execute(offset);
  }
}

class DbcFunctionImpl extends DbcFunction {
  DbcFunctionImpl(this.func);

  DbcCallableFunc func;

  @override
  DbcValueInterface? call(DbcVmInterface vm, DbcValueInterface? target, List<DbcValueInterface?> positionalArgs,
      Map<String, DbcValueInterface?> namedArgs) {
    return func(vm, target, positionalArgs, namedArgs);
  }
}
