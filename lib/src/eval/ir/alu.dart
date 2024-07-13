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

final class IntSub extends Operation {
  final SSA target;
  final SSA left;
  final SSA right;

  IntSub(this.target, this.left, this.right);

  @override
  Set<SSA> get readsFrom => {left, right};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => ArithmeticOp.subtract;

  @override
  String toString() => '$target = isub $left $right';

  @override
  bool operator ==(Object other) =>
      other is IntSub &&
      target == other.target &&
      left == other.left &&
      right == other.right;

  @override
  int get hashCode => target.hashCode ^ left.hashCode ^ right.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return IntSub(writesTo ?? target, left, right);
  }
}

final class IntLessThan extends Operation {
  final SSA target;
  final SSA left;
  final SSA right;

  IntLessThan(this.target, this.left, this.right);

  @override
  Set<SSA> get readsFrom => {left, right};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => ComparisonOp.lessThan;

  @override
  String toString() => '$target = ilt $left $right';

  @override
  bool operator ==(Object other) =>
      other is IntLessThan &&
      target == other.target &&
      left == other.left &&
      right == other.right;

  @override
  int get hashCode => target.hashCode ^ left.hashCode ^ right.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return IntLessThan(writesTo ?? target, left, right);
  }
}

final class IntEqual extends Operation {
  final SSA target;
  final SSA left;
  final SSA right;

  IntEqual(this.target, this.left, this.right);

  @override
  Set<SSA> get readsFrom => {left, right};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => ComparisonOp.equal;

  @override
  String toString() => '$target = ieq $left $right';

  @override
  bool operator ==(Object other) =>
      other is IntEqual &&
      target == other.target &&
      left == other.left &&
      right == other.right;

  @override
  int get hashCode => target.hashCode ^ left.hashCode ^ right.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return IntEqual(writesTo ?? target, left, right);
  }
}

final class IntNotEqual extends Operation {
  final SSA target;
  final SSA left;
  final SSA right;

  IntNotEqual(this.target, this.left, this.right);

  @override
  Set<SSA> get readsFrom => {left, right};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => ComparisonOp.notEqual;

  @override
  String toString() => '$target = ineq $left $right';

  @override
  bool operator ==(Object other) =>
      other is IntNotEqual &&
      target == other.target &&
      left == other.left &&
      right == other.right;

  @override
  int get hashCode => target.hashCode ^ left.hashCode ^ right.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return IntNotEqual(writesTo ?? target, left, right);
  }
}

final class IntLessThanOrEqual extends Operation {
  final SSA target;
  final SSA left;
  final SSA right;

  IntLessThanOrEqual(this.target, this.left, this.right);

  @override
  Set<SSA> get readsFrom => {left, right};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => ComparisonOp.lessThanOrEqual;

  @override
  String toString() => '$target = ilte $left $right';

  @override
  bool operator ==(Object other) =>
      other is IntLessThanOrEqual &&
      target == other.target &&
      left == other.left &&
      right == other.right;

  @override
  int get hashCode => target.hashCode ^ left.hashCode ^ right.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return IntLessThanOrEqual(writesTo ?? target, left, right);
  }
}

final class IntGreaterThan extends Operation {
  final SSA target;
  final SSA left;
  final SSA right;

  IntGreaterThan(this.target, this.left, this.right);

  @override
  Set<SSA> get readsFrom => {left, right};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => ComparisonOp.greaterThan;

  @override
  String toString() => '$target = igt $left $right';

  @override
  bool operator ==(Object other) =>
      other is IntGreaterThan &&
      target == other.target &&
      left == other.left &&
      right == other.right;

  @override
  int get hashCode => target.hashCode ^ left.hashCode ^ right.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return IntGreaterThan(writesTo ?? target, left, right);
  }
}

final class IntGreaterThanOrEqual extends Operation {
  final SSA target;
  final SSA left;
  final SSA right;

  IntGreaterThanOrEqual(this.target, this.left, this.right);

  @override
  Set<SSA> get readsFrom => {left, right};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => ComparisonOp.greaterThanOrEqual;

  @override
  String toString() => '$target = igte $left $right';

  @override
  bool operator ==(Object other) =>
      other is IntGreaterThanOrEqual &&
      target == other.target &&
      left == other.left &&
      right == other.right;

  @override
  int get hashCode => target.hashCode ^ left.hashCode ^ right.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return IntGreaterThanOrEqual(writesTo ?? target, left, right);
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
