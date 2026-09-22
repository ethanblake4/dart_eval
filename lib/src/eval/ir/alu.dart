import 'package:control_flow_graph/control_flow_graph.dart';
import 'operands.dart';

final class IntAdd extends Operation {
  @override
  bool get isPure => true;

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [left, right],
      this.readsFrom,
      readsFrom,
    );
    return IntAdd(writesTo ?? target, newReadsFrom[0], newReadsFrom[1]);
  }
}

final class IntSub extends Operation {
  @override
  bool get isPure => true;

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [left, right],
      this.readsFrom,
      readsFrom,
    );
    return IntSub(writesTo ?? target, newReadsFrom[0], newReadsFrom[1]);
  }
}

final class IntLessThan extends Operation {
  @override
  bool get isPure => true;

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [left, right],
      this.readsFrom,
      readsFrom,
    );
    return IntLessThan(writesTo ?? target, newReadsFrom[0], newReadsFrom[1]);
  }
}

final class IntEqual extends Operation {
  @override
  bool get isPure => true;

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [left, right],
      this.readsFrom,
      readsFrom,
    );
    return IntEqual(writesTo ?? target, newReadsFrom[0], newReadsFrom[1]);
  }
}

final class IntNotEqual extends Operation {
  @override
  bool get isPure => true;

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [left, right],
      this.readsFrom,
      readsFrom,
    );
    return IntNotEqual(writesTo ?? target, newReadsFrom[0], newReadsFrom[1]);
  }
}

final class IntLessThanOrEqual extends Operation {
  @override
  bool get isPure => true;

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [left, right],
      this.readsFrom,
      readsFrom,
    );
    return IntLessThanOrEqual(
      writesTo ?? target,
      newReadsFrom[0],
      newReadsFrom[1],
    );
  }
}

final class IntGreaterThan extends Operation {
  @override
  bool get isPure => true;

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [left, right],
      this.readsFrom,
      readsFrom,
    );
    return IntGreaterThan(writesTo ?? target, newReadsFrom[0], newReadsFrom[1]);
  }
}

final class IntGreaterThanOrEqual extends Operation {
  @override
  bool get isPure => true;

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [left, right],
      this.readsFrom,
      readsFrom,
    );
    return IntGreaterThanOrEqual(
      writesTo ?? target,
      newReadsFrom[0],
      newReadsFrom[1],
    );
  }
}

final class Increment extends Operation {
  final SSA target;

  final SSA source;

  Increment(this.target, [SSA? source]) : source = source ?? target;

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => AssignmentOp.addAssign;

  @override
  String toString() => '$target = increment $source';

  @override
  bool operator ==(Object other) =>
      other is Increment && target == other.target && source == other.source;

  @override
  int get hashCode => Object.hash(target, source);

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return Increment(writesTo ?? target, readsFrom?.single ?? source);
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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [left, right],
      this.readsFrom,
      readsFrom,
    );
    return LessThan(writesTo ?? target, newReadsFrom[0], newReadsFrom[1]);
  }
}

final class Negate extends Operation {
  @override
  bool get isPure => true;

  final SSA target;
  final SSA source;

  Negate(this.target, this.source);

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = -$source';

  @override
  bool operator ==(Object other) =>
      other is Negate && target == other.target && source == other.source;

  @override
  int get hashCode => target.hashCode ^ source.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return Negate(writesTo ?? target, readsFrom?.single ?? source);
  }
}
