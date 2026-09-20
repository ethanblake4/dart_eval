import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:control_flow_graph/control_flow_graph.dart';

class CompilerLabel {
  final void Function(CompilerContext ctx) cleanup;
  final BasicBlock? breakTarget;
  final BasicBlock? continueTarget;
  final int exceptionDepth;

  /// Names this label answers to in `break`/`continue` statements — the
  /// identifiers of a wrapping `LabeledStatement` (`outer:` in
  /// `outer: while (...)`).
  final Set<String> names;

  const CompilerLabel(
    this.cleanup, {
    this.breakTarget,
    this.continueTarget,
    this.names = const {},
    required this.exceptionDepth,
  });
}
