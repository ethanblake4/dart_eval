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
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
  equal,
  notEqual;

  bool get isComparison => index >= lessThan.index;
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
      operator != NumericOperator.modulo;
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
