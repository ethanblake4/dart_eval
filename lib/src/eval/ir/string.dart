import 'package:control_flow_graph/control_flow_graph.dart';
import 'representation.dart';

/// Operations selected only for statically known, unboxed String operands.
enum StringOperator {
  length,
  concatenate,
  codeUnitAt,
  indexOf,
  substringFrom,
  indexAt,
  equal,
  notEqual,
  isEmpty,
  isNotEmpty,
  startsWith,
}

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

/// Formats a statically known native primitive using Dart's own conversion.
final class PrimitiveToString extends Operation {
  PrimitiveToString(this.target, this.input, this.representation);

  final SSA target, input;
  final MachineRepresentation representation;

  @override
  SSA get writesTo => target;
  @override
  Set<SSA> get readsFrom => {input};

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) => PrimitiveToString(
    writesTo ?? target,
    readsFrom?.single ?? input,
    representation,
  );

  @override
  String toString() => '$target = ${representation.name}.toString $input';
}

/// Concatenates three native strings without allocating an intermediate prefix.
final class StringConcat3 extends Operation {
  StringConcat3(this.target, this.first, this.second, this.third);

  final SSA target, first, second, third;

  @override
  SSA get writesTo => target;
  @override
  Set<SSA> get readsFrom => {first, second, third};

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final operands = renameOperands(
      [first, second, third],
      this.readsFrom,
      readsFrom,
    );
    return StringConcat3(
      writesTo ?? target,
      operands[0],
      operands[1],
      operands[2],
    );
  }

  @override
  String toString() => '$target = string.concatenate3 $first $second $third';
}

/// `string.substring(start, end)` for statically known, unboxed operands.
final class StringSubstring extends Operation {
  StringSubstring(this.target, this.string, this.start, this.end);
  final SSA target;
  final SSA string;
  final SSA start;
  final SSA end;
  @override
  SSA get writesTo => target;
  @override
  Set<SSA> get readsFrom => {string, start, end};
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final operands = renameOperands(
      [string, start, end],
      this.readsFrom,
      readsFrom,
    );
    return StringSubstring(
      writesTo ?? target,
      operands[0],
      operands[1],
      operands[2],
    );
  }

  @override
  String toString() => '$target = string.substring $string $start $end';
}
