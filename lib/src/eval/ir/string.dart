import 'package:control_flow_graph/control_flow_graph.dart';

/// Operations selected only for statically known, unboxed String operands.
enum StringOperator { length, concatenate, codeUnitAt, indexAt }

final class StringOperation extends Operation {
  StringOperation(this.target, this.operator, this.string, [this.argument]);
  final SSA target;
  final StringOperator operator;
  final SSA string;
  final SSA? argument;
  @override
  SSA get writesTo => target;
  @override
  Set<SSA> get readsFrom => {string, ?argument};
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final operands = renameOperands(
      [string, ?argument],
      this.readsFrom,
      readsFrom,
    );
    return StringOperation(
      writesTo ?? target,
      operator,
      operands.first,
      argument == null ? null : operands.last,
    );
  }

  @override
  String toString() => '$target = string.${operator.name} $string $argument';
}
