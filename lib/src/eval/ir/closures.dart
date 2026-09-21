import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'representation.dart';

/// Creates a callable value with an explicit environment and call signature.
final class CreateClosure extends Operation {
  final SSA result;
  final DeferredOrOffset target;
  final List<SSA> captures;
  final int requiredPositional;
  final int positionalCount;
  final List<String> namedNames;
  final bool boundReceiver;
  final bool hasEnvironment;
  final List<Object?> positionalDefaults;
  final List<Object?> namedDefaults;
  final List<String> requiredNamed;
  final List<bool> positionalUnboxed;
  final List<bool> namedUnboxed;
  final int runtimeTypeId;

  /// Hidden thunk function indices for defaults that can't serialize as
  /// scalars, parallel to `[...positionalDefaults, ...namedDefaults]`.
  /// `-1` means the corresponding slot's scalar value is used directly.
  final List<int> defaultThunks;

  CreateClosure(
    this.result,
    this.target,
    this.captures, {
    this.requiredPositional = 0,
    this.positionalCount = 0,
    this.namedNames = const [],
    this.boundReceiver = false,
    this.hasEnvironment = true,
    this.positionalDefaults = const [],
    this.namedDefaults = const [],
    this.requiredNamed = const [],
    this.positionalUnboxed = const [],
    this.namedUnboxed = const [],
    this.runtimeTypeId = -1,
    this.defaultThunks = const [],
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
      positionalCount: positionalCount,
      namedNames: namedNames,
      boundReceiver: boundReceiver,
      hasEnvironment: hasEnvironment,
      positionalDefaults: positionalDefaults,
      namedDefaults: namedDefaults,
      requiredNamed: requiredNamed,
      positionalUnboxed: positionalUnboxed,
      namedUnboxed: namedUnboxed,
      runtimeTypeId: runtimeTypeId,
      defaultThunks: defaultThunks,
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
  final List<int> typeArguments;
  final bool trusted;

  InvokeClosure(
    this.result,
    this.closure,
    this.positional,
    this.named, {
    this.typeArguments = const [],
    this.trusted = false,
  });

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
      typeArguments: typeArguments,
      trusted: trusted,
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

/// A shared lexical binding with an explicit payload representation.
final class NewCaptureCell extends Operation {
  NewCaptureCell(this.result, this.value, this.representation);
  final SSA result, value;
  final MachineRepresentation representation;
  @override
  SSA get writesTo => result;
  @override
  Set<SSA> get readsFrom => {value};
  @override
  Operation copyWith({SSA? writesTo, Set<SSA>? readsFrom}) => NewCaptureCell(
    writesTo ?? result,
    readsFrom?.single ?? value,
    representation,
  );
}

final class ReadCaptureCell extends Operation {
  ReadCaptureCell(this.result, this.cell, this.representation);
  final SSA result, cell;
  final MachineRepresentation representation;
  @override
  SSA get writesTo => result;
  @override
  Set<SSA> get readsFrom => {cell};
  @override
  Operation copyWith({SSA? writesTo, Set<SSA>? readsFrom}) => ReadCaptureCell(
    writesTo ?? result,
    readsFrom?.single ?? cell,
    representation,
  );
}

final class WriteCaptureCell extends Operation {
  WriteCaptureCell(this.cell, this.value, this.representation);
  final SSA cell, value;
  final MachineRepresentation representation;
  @override
  Set<SSA> get readsFrom => {cell, value};
  @override
  Operation copyWith({SSA? writesTo, Set<SSA>? readsFrom}) {
    final mapping = readsFrom == null
        ? <SSA, SSA>{}
        : Map<SSA, SSA>.fromIterables(this.readsFrom, readsFrom);
    return WriteCaptureCell(
      mapping[cell] ?? cell,
      mapping[value] ?? value,
      representation,
    );
  }
}
