import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import 'class.dart';

typedef EvalCallableFunc = EvalValue? Function(Runtime runtime, EvalValue? target,
    List<EvalValue?> args);

abstract class EvalCallable {
  EvalValue? call(Runtime runtime, EvalValue? target, List<EvalValue?> args);
}

abstract class EvalFunction implements EvalInstance, EvalCallable {

  const EvalFunction();

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'call':
        return this;
      default:
        throw EvalUnknownPropertyException(identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {
    throw EvalUnknownPropertyException(identifier);
  }

  @override
  dynamic get $value => throw UnimplementedError();

  @override
  dynamic get $reified => throw UnimplementedError();
}

class EvalFunctionPtr extends EvalFunction {
  EvalFunctionPtr(this.$this, this.offset);

  final EvalInstance $this;
  final int offset;

  @override
  EvalValue? call(Runtime runtime, EvalValue? target, List<EvalValue?> args) {
    runtime.args.add($this);
    runtime.bridgeCall(offset);
    return runtime.returnValue as EvalValue?;
  }
}

class EvalFunctionImpl extends EvalFunction {
  const EvalFunctionImpl(this.func);

  final EvalCallableFunc func;

  @override
  EvalValue? call(Runtime runtime, EvalValue? target, List<EvalValue?> args) {
    return func(runtime, target, args);
  }
}
