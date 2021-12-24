import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/stdlib_base.dart';

import 'class.dart';

typedef DbcCallableFunc = IDbcValue? Function(Runtime runtime, IDbcValue? target,
    List<IDbcValue?> args);

abstract class DbcCallable {
  IDbcValue? call(Runtime runtime, IDbcValue? target, List<IDbcValue?> args);
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
  IDbcValue? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'call':
        return this;
      default:
        throw EvalUnknownPropertyException(identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, IDbcValue value) {
    throw EvalUnknownPropertyException(identifier);
  }

  @override
  DbcInstance? get evalSuperclass => DbcObject();

  @override
  dynamic get $value => throw UnimplementedError();

  @override
  dynamic get $reified => throw UnimplementedError();
}

class DbcFunctionPtr extends DbcFunction {
  DbcFunctionPtr(this.$this, this.offset);

  final DbcInstance $this;
  final int offset;

  @override
  IDbcValue? call(Runtime runtime, IDbcValue? target, List<IDbcValue?> args) {
    runtime.pushArg($this);
    runtime.bridgeCall(offset);
    return runtime.returnValue as IDbcValue?;
  }
}

class DbcFunctionImpl extends DbcFunction {
  const DbcFunctionImpl(this.func);

  final DbcCallableFunc func;

  @override
  IDbcValue? call(Runtime runtime, IDbcValue? target, List<IDbcValue?> args) {
    return func(runtime, target, args);
  }
}
