import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';

/// Creates a callable value with an explicit environment and call signature.
final class CreateClosure extends Operation {
  final SSA result;
  final DeferredOrOffset target;
  final List<SSA> captures;
  final int requiredPositional;
  final List<Object?> positionalTypes;
  final List<String> namedNames;
  final List<Object?> namedTypes;
  final bool boundReceiver;
  final List<bool> positionalUnboxed;
  final List<bool> namedUnboxed;

  CreateClosure(
    this.result,
    this.target,
    this.captures, {
    this.requiredPositional = 0,
    this.positionalTypes = const [],
    this.namedNames = const [],
    this.namedTypes = const [],
    this.boundReceiver = false,
    this.positionalUnboxed = const [],
    this.namedUnboxed = const [],
  });

  @override
  SSA get writesTo => result;
  @override
  Set<SSA> get readsFrom => captures.toSet();
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final replacements = readsFrom == null
        ? <SSA, SSA>{}
        : Map<SSA, SSA>.fromIterables(this.readsFrom, readsFrom);
    return CreateClosure(
      writesTo ?? result,
      target,
      captures.map((value) => replacements[value] ?? value).toList(),
      requiredPositional: requiredPositional,
      positionalTypes: positionalTypes,
      namedNames: namedNames,
      namedTypes: namedTypes,
      boundReceiver: boundReceiver,
      positionalUnboxed: positionalUnboxed,
      namedUnboxed: namedUnboxed,
    );
  }

  @override
  String toString() => '$result = closure $target captures $captures';
}

/// Invokes a closure while retaining named argument names and operand order.
final class InvokeClosure extends Operation {
  final SSA result;
  final SSA closure;
  final List<SSA> positional;
  final Map<String, SSA> named;

  InvokeClosure(this.result, this.closure, this.positional, this.named);

  @override
  SSA get writesTo => result;
  @override
  Set<SSA> get readsFrom => {closure, ...positional, ...named.values};
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final replacements = readsFrom == null
        ? <SSA, SSA>{}
        : Map<SSA, SSA>.fromIterables(this.readsFrom, readsFrom);
    SSA replace(SSA value) => replacements[value] ?? value;
    return InvokeClosure(
      writesTo ?? result,
      replace(closure),
      positional.map(replace).toList(),
      named.map((key, value) => MapEntry(key, replace(value))),
    );
  }

  @override
  String toString() => '$result = invokeclosure $closure($positional, $named)';
}

/// Reads a captured binding from the active closure environment.
final class LoadCapture extends Operation {
  final SSA result;
  final int index;
  LoadCapture(this.result, this.index);
  @override
  SSA get writesTo => result;
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      LoadCapture(writesTo ?? result, index);
  @override
  String toString() => '$result = capture[$index]';
}
