import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/complete_jump.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';

StatementInfo compileBreakStatement(BreakStatement s, CompilerContext ctx) {
  final label = findJumpLabel(
    ctx,
    s.label?.name.lexeme,
    (label) => label.breakTarget != null,
    s,
    kind: 'break',
  );
  jumpToLabel(ctx, label, label.breakTarget!);
  return StatementInfo(willAlwaysBreak: true);
}

/// Finds the innermost [CompilerLabel] matching [name] (or the innermost
/// unconditionally when [name] is null) for which [hasTarget] holds.
CompilerLabel findJumpLabel(
  CompilerContext ctx,
  String? name,
  bool Function(CompilerLabel) hasTarget,
  AstNode source, {
  required String kind,
}) {
  for (var i = ctx.labels.length - 1; i >= 0; i--) {
    final label = ctx.labels[i];
    if (name != null && !label.names.contains(name)) continue;
    if (hasTarget(label)) return label;
  }
  throw CompileError(
    name == null
        ? "Cannot use '$kind' outside of a loop or switch context"
        : "Cannot resolve label '$name'",
    source,
  );
}

/// Emits the jump to [target], unwinding exception handlers when the label was
/// registered at a shallower [CompilerLabel.exceptionDepth].
void jumpToLabel(CompilerContext ctx, CompilerLabel label, BasicBlock target) {
  label.cleanup(ctx);
  if (ctx.exceptionDepth > label.exceptionDepth) {
    completeJump(ctx, target, label.exceptionDepth);
  } else {
    ctx.pushOp(Jump(target.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, target);
  }
}
