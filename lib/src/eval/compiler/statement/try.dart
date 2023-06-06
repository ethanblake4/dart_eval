import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

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

  final jumpOver = ctx.pushOp(JumpConstant.make(-1), JumpConstant.LEN);
  ctx.rewriteOp(tryOp, Try.make(ctx.out.length), 0);

  ctx.beginAllocScope();
  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  final v = Variable.alloc(ctx, EvalTypes.dynamicType);
  final catchInfo = _compileCatchClause(ctx, s.catchClauses, 0, v, expectedReturnType);
  ctx.endAllocScope();

  ctx.rewriteOp(jumpOver, JumpConstant.make(ctx.out.length), 0);

  if (s.finallyBlock != null) {
    throw CompileError('Finally blocks are not supported yet');
  }

  return bodyInfo | catchInfo.copyWith(willAlwaysThrow: false);
}

StatementInfo _compileCatchClause(CompilerContext ctx, List<CatchClause> clauses, int index, Variable exceptionVar,
    AlwaysReturnType? expectedReturnType) {
  final catchClause = clauses[index];
  final exceptionType = catchClause.exceptionType;
  if (exceptionType == null) {
    ctx.setLocal(catchClause.exceptionParameter!.name.value() as String, exceptionVar);
    return compileStatement(catchClause.body, expectedReturnType, ctx);
  }
  final slot = TypeRef.fromAnnotation(ctx, ctx.library, exceptionType);
  return macroBranch(
    ctx,
    expectedReturnType,
    condition: (_ctx) {
      ctx.pushOp(IsType.make(exceptionVar.scopeFrameOffset, runtimeTypeMap[slot] ?? ctx.typeRefIndexMap[slot]!, false),
          IsType.LEN);
      return Variable.alloc(ctx, EvalTypes.boolType.copyWith(boxed: false));
    },
    thenBranch: (_ctx, _expectedReturnType) {
      ctx.setLocal(catchClause.exceptionParameter!.name.value() as String, exceptionVar.copyWith(type: slot));
      return compileStatement(catchClause.body, expectedReturnType, ctx);
    },
    elseBranch: clauses.length <= index + 1
        ? null
        : (ctx, expectedReturnType) {
            return _compileCatchClause(ctx, clauses, index + 1, exceptionVar, expectedReturnType);
          },
  );
}

/// 