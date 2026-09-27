import 'package:control_flow_graph/control_flow_graph.dart';

/// Saves a lazy generator's initial frame before its body executes.
final class BeginSyncGenerator extends Operation {
  BeginSyncGenerator(this.result, {required this.runtimeTypeId});
  final SSA result;
  // Closure element types are inferred after compiling their yields.
  int runtimeTypeId;

  @override
  SSA get writesTo => result;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      BeginSyncGenerator(writesTo ?? result, runtimeTypeId: runtimeTypeId);
}

/// Suspends an iterator until its next moveNext call.
final class YieldSync extends Operation {
  YieldSync(this.value);
  final SSA value;

  @override
  Set<SSA> get readsFrom => {value};

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      YieldSync(readsFrom?.single ?? value);
}
