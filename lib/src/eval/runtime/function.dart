import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/type.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

import '../../../dart_eval_bridge.dart';
import 'class.dart';

typedef EvalCallableFunc = $Value? Function(Runtime runtime, $Value? target, List<$Value?> args);

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
  EvalFunctionPtr(this.$this, this.offset, this.requiredPositionalArgCount, this.positionalArgTypes, this.sortedNamedArgs,
      this.sortedNamedArgTypes);

  final int offset;
  final $Instance? $this;
  final int requiredPositionalArgCount;
  final List<RuntimeType> positionalArgTypes;
  final List<String> sortedNamedArgs;
  final List<RuntimeType> sortedNamedArgTypes;

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    final cpat = runtime.args[0] as List;
    final cnat = runtime.args[2] as List;

    final csPosArgTypes = [for (final a in cpat) runtime.runtimeTypes[a]];
    final csNamedArgs = runtime.args[1] as List;
    final csNamedArgTypes = [for (final a in cnat) runtime.runtimeTypes[a]];

    if (csPosArgTypes.length < requiredPositionalArgCount || csPosArgTypes.length > positionalArgTypes.length) {
      throw ArgumentError(
          'FunctionPtr: Cannot invoke function with the given arguments (unacceptable # of positional arguments). '
              '${positionalArgTypes.length} >= ${csPosArgTypes.length} >= $requiredPositionalArgCount');
    }

    var i = 0, j = 0;
    while (i < csPosArgTypes.length) {
      if (!csPosArgTypes[i].isAssignableTo(positionalArgTypes[i])) {
        throw ArgumentError('FunctionPtr: Cannot invoke function with the given arguments');
      }
      i++;
    }

    // Very efficient algorithm for checking that named args match
    // Requires that the named arg arrays be sorted
    i = 0;
    var cl = csNamedArgs.length;
    var tl = sortedNamedArgs.length - 1;
    while (j < cl) {
      if (i > tl) {
        throw ArgumentError('FunctionPtr: Cannot invoke function with the given arguments');
      }
      final _t = csNamedArgTypes[j];
      final _ti = sortedNamedArgTypes[i];
      if (sortedNamedArgs[i] == csNamedArgs[j] && _t.isAssignableTo(_ti)) {
        j++;
      }
      i++;
    }

    final al = runtime.args.length;
    runtime.args = [for (i = 3; i < al; i++) runtime.args[i], $this];
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
