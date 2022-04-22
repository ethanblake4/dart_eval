import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/type.dart';

import '../../../dart_eval_bridge.dart';

typedef EvalCallableFunc = $Value? Function(
    Runtime runtime, $Value? target, List<$Value?> args);

abstract class EvalCallable {
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args);
}

abstract class EvalFunction implements $Instance, EvalCallable {
  const EvalFunction();

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'call':
        return this;
      default:
        throw EvalUnknownPropertyException(identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw EvalUnknownPropertyException(identifier);
  }

  @override
  dynamic get $value => throw UnimplementedError();

  @override
  dynamic get $reified => throw UnimplementedError();
}

class EvalFunctionPtr extends EvalFunction {
  EvalFunctionPtr(this.$this, this.offset, this.requiredPositionalArgCount,
      this.positionalArgTypes, this.sortedNamedArgs, this.sortedNamedArgTypes);

  final int offset;
  final $Instance? $this;
  final int requiredPositionalArgCount;
  final List<RuntimeType> positionalArgTypes;
  final List<String> sortedNamedArgs;
  final List<RuntimeType> sortedNamedArgTypes;

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    runtime.args = [null, ...runtime.args, $this];
    runtime.bridgeCall(offset);
    return runtime.returnValue as $Value?;
  }

  @override
  int get $runtimeType => RuntimeTypes.functionType;
}

class EvalStaticFunctionPtr extends EvalFunction {
  EvalStaticFunctionPtr(this.$this, this.offset);

  final int offset;
  final $Instance? $this;

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    runtime.args = args;
    runtime.bridgeCall(offset);
    return runtime.returnValue as $Value?;
  }

  @override
  int get $runtimeType => RuntimeTypes.functionType;
}

class $Function extends EvalFunction {
  const $Function(this.func);

  final EvalCallableFunc func;

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return func(runtime, target, args);
  }

  @override
  int get $runtimeType => RuntimeTypes.functionType;
}
