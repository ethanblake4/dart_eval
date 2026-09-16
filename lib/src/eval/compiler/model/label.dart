import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:control_flow_graph/control_flow_graph.dart';

class CompilerLabel {
  final void Function(CompilerContext ctx) cleanup;
  final BasicBlock? breakTarget;
  final BasicBlock? continueTarget;
  final int exceptionDepth;

  const CompilerLabel(
    this.cleanup, {
    this.breakTarget,
    this.continueTarget,
    required this.exceptionDepth,
  });
}
