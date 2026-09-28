import 'package:control_flow_graph/control_flow_graph.dart';

/// Saves a lazy generator's initial frame before its body executes.
final class BeginGenerator extends Operation {
  BeginGenerator(
    this.result, {
    required this.runtimeTypeId,
    this.asynchronous = false,
  });
  final SSA result;
  final bool asynchronous;
  // Closure element types are inferred after compiling their yields.
  int runtimeTypeId;

  @override
  SSA get writesTo => result;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) => BeginGenerator(
    writesTo ?? result,
    runtimeTypeId: runtimeTypeId,
    asynchronous: asynchronous,
  );
}

/// Suspends a generator at a yield or a delegated sequence.
final class YieldGenerator extends Operation {
  YieldGenerator(
    this.value, {
    this.delegate = false,
    this.asynchronous = false,
  });
  final SSA value;
  final bool delegate;
  final bool asynchronous;

  @override
  Set<SSA> get readsFrom => {value};

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) => YieldGenerator(
    readsFrom?.single ?? value,
    delegate: delegate,
    asynchronous: asynchronous,
  );
}
