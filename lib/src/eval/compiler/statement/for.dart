import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/statement/variable_declaration.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

StatementInfo compileForStatement(ForStatement s, CompilerContext ctx, AlwaysReturnType? expectedReturnType) {
  final parts = s.forLoopParts;

  if (!(parts is ForParts)) {
    throw UnimplementedError('For-each is not supported yet');
  }

  ctx.beginAllocScope(requireNonlinearAccess: true);

  if (parts is ForPartsWithDeclarations) {
    compileVariableDeclarationList(parts.variables, ctx);
  } else if (parts is ForPartsWithExpression) {
    if (parts.initialization != null) {
      compileExpression(parts.initialization!, ctx);
    }
  }

  JumpIfFalse? rewriteCond;
  int? rewritePos;
  Variable? conditionResult;
  final loopStart = ctx.out.length;

  ctx.beginAllocScope(requireNonlinearAccess: true);

  if (parts.condition != null) {
    conditionResult = compileExpression(parts.condition!, ctx).unboxIfNeeded(ctx);
    rewriteCond = JumpIfFalse.make(conditionResult.scopeFrameOffset, -1);
    rewritePos = ctx.pushOp(rewriteCond, JumpIfFalse.LEN);
  }

  var pops = ctx.peekAllocPops();

  final statementResult = compileStatement(s.body, expectedReturnType, ctx);
  if (!(statementResult.willAlwaysThrow || statementResult.willAlwaysReturn)) {
    for (final u in parts.updaters) {
      compileExpression(u, ctx);
    }
    ctx.resolveNonlinearity(2);
    ctx.endAllocScope();
    ctx.pushOp(JumpConstant.make(loopStart), JumpConstant.LEN);
  } else {
    pops = 0;
  }

  if (rewritePos != null) {
    ctx.rewriteOp(rewritePos, JumpIfFalse.make(conditionResult!.scopeFrameOffset, ctx.out.length), 0);
  }

  ctx.endAllocScope(popAdjust: pops);

  return statementResult;
}