import 'package:control_flow_graph/control_flow_graph.dart';
import 'operands.dart';
import 'representation.dart';

enum NumericOperator {
  add,
  subtract,
  multiply,
  divide,
  truncatingDivide,
  modulo,
  bitAnd,
  bitOr,
  bitXor,
  shiftLeft,
  shiftRight,
  unsignedShiftRight,
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
  equal,
  notEqual;

  bool get isComparison => index >= lessThan.index;
  bool get isIntegerOnly =>
      index >= bitAnd.index && index <= unsignedShiftRight.index;
}

/// `int → double` widening — the only implicit numeric conversion in Dart.
final class IntToDouble extends Operation {
  IntToDouble(this.target, this.source);

  final SSA target;
  final SSA source;

  @override
  SSA get writesTo => target;
  @override
  Set<SSA> get readsFrom => {source};
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      IntToDouble(writesTo ?? target, readsFrom?.single ?? source);
}

/// An operation on two values of the same primitive numeric representation.
final class NumericBinary extends Operation {
  NumericBinary(
    this.result,
    this.left,
    this.right,
    this.operandRepresentation,
    this.operator,
  ) {
    if (operandRepresentation != MachineRepresentation.integer &&
        operandRepresentation != MachineRepresentation.doublePrecision) {
      throw ArgumentError.value(
        operandRepresentation,
        'operandRepresentation',
        'Expected an integer or double representation',
      );
    }
  }

  final SSA result;
  final SSA left;
  final SSA right;
  final MachineRepresentation operandRepresentation;
  final NumericOperator operator;

  MachineRepresentation get resultRepresentation => operator.isComparison
      ? MachineRepresentation.boolean
      : operator == NumericOperator.truncatingDivide
      ? MachineRepresentation.integer
      : operator == NumericOperator.divide
      ? MachineRepresentation.doublePrecision
      : operandRepresentation;

  @override
  SSA get writesTo => result;
  @override
  List<SSA> get operands => [left, right];
  @override
  Set<SSA> get readsFrom => {left, right};
  @override
  bool get isPure =>
      operator != NumericOperator.truncatingDivide &&
      operator != NumericOperator.modulo &&
      operator != NumericOperator.shiftLeft &&
      operator != NumericOperator.shiftRight &&
      operator != NumericOperator.unsignedShiftRight;
  @override
  Operation copyWith({SSA? writesTo, Set<SSA>? readsFrom}) => copyWithOperands(
    writesTo: writesTo,
    operands: renameOperands(operands, this.readsFrom, readsFrom),
  );
  @override
  NumericBinary copyWithOperands({SSA? writesTo, List<SSA>? operands}) =>
      NumericBinary(
        writesTo ?? result,
        operands?[0] ?? left,
        operands?[1] ?? right,
        operandRepresentation,
        operator,
      );
  @override
  String toString() =>
      '$result = ${operandRepresentation.name}.${operator.name} $left, $right';
}
