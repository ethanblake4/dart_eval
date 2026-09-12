import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';

StatementInfo compileBreakStatement(BreakStatement s, CompilerContext ctx) {
  if (s.label != null) {
    throw CompileError('Break labels are not currently supported', s);
  }

  final label = ctx.labels.lastWhere(
    (label) => label.breakTarget != null,
    orElse: () => throw CompileError(
      "Cannot use 'break' outside of a loop or switch context",
      s,
    ),
  );
  label.cleanup(ctx);
  final target = label.breakTarget!;
  ctx.pushOp(Jump(target.label!));
  final tail = ctx.flushBlock();
  ctx.builder.link(tail, target);
  return StatementInfo(-1, willAlwaysBreak: true);
}
