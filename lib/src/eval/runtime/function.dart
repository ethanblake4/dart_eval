import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/type.dart';

import '../../../dart_eval_bridge.dart';

/// Typedef of a function that can be called by dart_eval.
typedef EvalCallableFunc = $Value? Function(
    Runtime runtime, $Value? target, List<$Value?> args);

/// Abstract supertype for values representing a callable in dart_eval.
abstract class EvalCallable {
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args);
}

/// Abstract supertype for values representing a [Function] in dart_eval.
///
/// See [$Function] or [$Closure] to wrap an existing Dart function as a
/// [EvalFunction].
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
  EvalFunctionPtr(this.$prev, this.offset, this.requiredPositionalArgCount,
      this.positionalArgTypes, this.sortedNamedArgs, this.sortedNamedArgTypes);

  final int offset;
  final List<Object?>? $prev;
  final int requiredPositionalArgCount;
  final List<RuntimeType> positionalArgTypes;
  final List<String> sortedNamedArgs;
  final List<RuntimeType> sortedNamedArgTypes;

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    runtime.args = [if ($prev != null) $prev, ...args];
    runtime.bridgeCall(offset);
 
    return runtime.returnValue is $Value ? runtime.returnValue as $Value? : runtime.wrap(runtime.returnValue);
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.function);

  @override
  String toString() {
    return 'EvalFunctionPtr{offset: $offset, prev: ${$prev == null ? 'null' : formatStackSample($prev!, 4)}, '
        'rPAC: $requiredPositionalArgCount, '
        'pAT: $positionalArgTypes, '
        'sNA: $sortedNamedArgs, '
        'sNAT: $sortedNamedArgTypes}';
  }
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
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.function);
}

/// An implementation of [EvalFunction] that wraps an existing Dart function for
/// use in dart_eval.
///
/// The wrapped function should be of the type
/// ```dart
/// $Value? Function(Runtime runtime, $Value? target, List<$Value?> args)
/// ```
///
/// The target is the object that the function is being called on, or null if
/// the function is being called statically.
///
/// The args are the arguments passed to the function.
///
/// In dynamic invocation / closure contexts such as when passing a function
/// as an argument, use [$Closure] instead.
class $Function extends EvalFunction {
  const $Function(this.func);

  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.function)),
      constructors: {},
      wrap: true);

  final EvalCallableFunc func;

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return func(runtime, target, args);
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.function);
}

/// Variant of [$Function] for use in a dynamic invocation / closure context,
/// such as when passing a function as an argument.
class $Closure extends EvalFunction {
  const $Closure(this.func, [this.$this]);

  final EvalCallableFunc func;
  final $Instance? $this;

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    return func(runtime, $this ?? target, args.sublist(3));
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.function);
}
