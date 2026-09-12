import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

StatementInfo compileContinueStatement(
  ContinueStatement s,
  CompilerContext ctx,
) {
  if (s.label != null) {
    throw CompileError('Continue labels are not currently supported', s);
  }
  final label = ctx.labels.lastWhere(
    (label) => label.continueTarget != null,
    orElse: () => throw CompileError(
      "Cannot use 'continue' outside of a loop context",
      s,
    ),
  );
  label.cleanup(ctx);
  final target = label.continueTarget!;
  ctx.pushOp(Jump(target.label!));
  final tail = ctx.flushBlock();
  ctx.builder.link(tail, target);
  return StatementInfo(-1, willAlwaysBreak: true);
}
