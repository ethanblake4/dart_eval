import 'package:control_flow_graph/control_flow_graph.dart';

/// Rebuilds ordered operands from the ordered set used by CFG renaming.
/// Repeated arguments retain their positions and multiplicity.
List<SSA> renameOperands(
  List<SSA> operands,
  Set<SSA> original,
  Set<SSA>? renamed,
) {
  if (renamed == null) return operands;
  if (original.length != renamed.length) {
    throw ArgumentError('Operand renaming must preserve the number of inputs');
  }
  final replacements = Map<SSA, SSA>.fromIterables(original, renamed);
  return [for (final operand in operands) replacements[operand]!];
}
