import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/statement/break.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';

StatementInfo compileContinueStatement(
  ContinueStatement s,
  CompilerContext ctx,
) {
  final label = findJumpLabel(
    ctx,
    s.label?.name.lexeme,
    (label) => label.continueTarget != null,
    s,
    kind: 'continue',
  );
  jumpToLabel(ctx, label, label.continueTarget!);
  return StatementInfo(willAlwaysBreak: true);
}
