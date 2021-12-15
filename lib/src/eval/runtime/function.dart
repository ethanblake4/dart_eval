import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/stdlib_base.dart';

import 'class.dart';

typedef DbcCallableFunc = DbcValueInterface? Function(DbcVmInterface vm, DbcValueInterface? target,
    List<DbcValueInterface?> args);

abstract class DbcCallable {
  DbcValueInterface? call(DbcVmInterface vm, DbcValueInterface? target, List<DbcValueInterface?> args);
}

class DbcVmInterface {
  DbcVmInterface(this.exec);

  Runtime exec;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DbcVmInterface && runtimeType == other.runtimeType && exec == other.exec;

  @override
  int get hashCode => exec.hashCode;
}

abstract class DbcFunction implements DbcInstance, DbcCallable {

  const DbcFunction();

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
  DbcInstance? get evalSuperclass => DbcObject();

  @override
  dynamic get evalValue => throw UnimplementedError();

  @override
  dynamic get reifiedValue => throw UnimplementedError();
}

class DbcFunctionPtr extends DbcFunction {
  DbcFunctionPtr(this.offset);

  final int offset;

  @override
  DbcValueInterface? call(DbcVmInterface vm, DbcValueInterface? target, List<DbcValueInterface?> args) {
    final exec = vm.exec;
    exec.execute(offset);
  }
}

class DbcFunctionImpl extends DbcFunction {
  const DbcFunctionImpl(this.func);

  final DbcCallableFunc func;

  @override
  DbcValueInterface? call(DbcVmInterface vm, DbcValueInterface? target, List<DbcValueInterface?> args) {
    return func(vm, target, args);
  }
}
