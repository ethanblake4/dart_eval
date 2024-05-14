import 'package:control_flow_graph/control_flow_graph.dart';

class LogicalNot extends Operation {
  final SSA target;
  final SSA source;

  LogicalNot(this.target, this.source);

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => LogicalOp.not;

  @override
  String toString() => '$target = !$source';

  @override
  bool operator ==(Object other) =>
      other is LogicalNot && target == other.target && source == other.source;

  @override
  int get hashCode => target.hashCode ^ source.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LogicalNot(writesTo ?? target, source);
  }
}
