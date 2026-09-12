import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:control_flow_graph/control_flow_graph.dart';

class CompilerLabel {
  final int offset;
  final int Function(CompilerContext ctx) cleanup;
  final String? name;
  final LabelType type;
  final BasicBlock? breakTarget;
  final BasicBlock? continueTarget;

  const CompilerLabel(
    this.type,
    this.offset,
    this.cleanup, {
    this.name,
    this.breakTarget,
    this.continueTarget,
  });
}

class SimpleCompilerLabel implements CompilerLabel {
  @override
  BasicBlock? get breakTarget => null;
  @override
  BasicBlock? get continueTarget => null;
  @override
  get offset => -1;
  @override
  final String? name;
  @override
  get type => LabelType.block;

  const SimpleCompilerLabel({this.name});

  @override
  get cleanup => (CompilerContext ctx) {
    ctx.endAllocScopeQuiet();
    return -1;
  };
}

enum LabelType { loop, branch, block }
