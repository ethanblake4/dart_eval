import 'package:control_flow_graph/control_flow_graph.dart';

final class IntAdd extends Operation {
  final SSA target;
  final SSA left;
  final SSA right;

  IntAdd(this.target, this.left, this.right);

  @override
  Set<SSA> get readsFrom => {left, right};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => ArithmeticOp.add;

  @override
  String toString() => '$target = iadd $left $right';

  @override
  bool operator ==(Object other) =>
      other is IntAdd &&
      target == other.target &&
      left == other.left &&
      right == other.right;

  @override
  int get hashCode => target.hashCode ^ left.hashCode ^ right.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return IntAdd(writesTo ?? target, left, right);
  }
}

final class Increment extends Operation {
  final SSA target;

  Increment(this.target);

  @override
  Set<SSA> get readsFrom => {target};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => AssignmentOp.addAssign;

  @override
  String toString() => '++ $target';

  @override
  bool operator ==(Object other) =>
      other is Increment && target == other.target;

  @override
  int get hashCode => target.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return Increment(writesTo ?? target);
  }
}

final class LessThan extends Operation {
  final SSA target;
  final SSA left;
  final SSA right;

  LessThan(this.target, this.left, this.right);

  @override
  Set<SSA> get readsFrom => {left, right};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => ComparisonOp.lessThan;

  @override
  String toString() => '$target = $left < $right';

  @override
  bool operator ==(Object other) =>
      other is LessThan &&
      target == other.target &&
      left == other.left &&
      right == other.right;

  @override
  int get hashCode => target.hashCode ^ left.hashCode ^ right.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LessThan(writesTo ?? target, left, right);
  }
}
