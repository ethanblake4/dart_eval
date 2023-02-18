import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../variable.dart';

StatementInfo compileTryStatement(TryStatement s, CompilerContext ctx, AlwaysReturnType? expectedReturnType) {
  final tryOp = ctx.pushOp(Try.make(-1), Try.LEN);

  final _initialState = ctx.saveState();
  ctx.beginAllocScope();
  final bodyInfo = compileStatement(s.body, expectedReturnType, ctx);
  ctx.resolveBranchStateDiscontinuity(_initialState);
  ctx.pushOp(PopCatch.make(), PopCatch.LEN);

  if (s.catchClauses.isEmpty) {
    throw CompileError('Try statements must have at least one catch clause');
  }
  if (s.catchClauses.length > 1) {
    throw CompileError('Multiple catch clauses are not supported yet');
  }

  final jumpOver = ctx.pushOp(JumpConstant.make(-1), JumpConstant.LEN);
  ctx.rewriteOp(tryOp, Try.make(ctx.out.length), 0);

  final catchClause = s.catchClauses.first;

  ctx.beginAllocScope();
  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  final v = Variable.alloc(ctx, EvalTypes.dynamicType);
  ctx.setLocal(catchClause.exceptionParameter!.name.value() as String, v);
  final catchInfo = compileStatement(catchClause.body, expectedReturnType, ctx);
  ctx.endAllocScope();
  ctx.rewriteOp(jumpOver, JumpConstant.make(ctx.out.length), 0);

  if (s.finallyBlock != null) {
    throw CompileError('Finally blocks are not supported yet');
  }

  return bodyInfo | catchInfo.copyWith(willAlwaysThrow: false);
}
