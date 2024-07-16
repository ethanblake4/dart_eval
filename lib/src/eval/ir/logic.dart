import 'package:control_flow_graph/control_flow_graph.dart';

final class LogicalNot extends Operation {
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

final class LogicalAnd extends Operation {
  final SSA target;
  final SSA left;
  final SSA right;

  LogicalAnd(this.target, this.left, this.right);

  @override
  Set<SSA> get readsFrom => {left, right};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => LogicalOp.and;

  @override
  String toString() => '$target = $left && $right';

  @override
  bool operator ==(Object other) =>
      other is LogicalAnd &&
      target == other.target &&
      left == other.left &&
      right == other.right;

  @override
  int get hashCode => target.hashCode ^ left.hashCode ^ right.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LogicalAnd(writesTo ?? target, left, right);
  }
}

final class LogicalOr extends Operation {
  final SSA target;
  final SSA left;
  final SSA right;

  LogicalOr(this.target, this.left, this.right);

  @override
  Set<SSA> get readsFrom => {left, right};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => LogicalOp.or;

  @override
  String toString() => '$target = $left || $right';

  @override
  bool operator ==(Object other) =>
      other is LogicalOr &&
      target == other.target &&
      left == other.left &&
      right == other.right;

  @override
  int get hashCode => target.hashCode ^ left.hashCode ^ right.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LogicalOr(writesTo ?? target, left, right);
  }
}
