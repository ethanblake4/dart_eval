import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

import '../variable.dart';

StatementInfo compileTryStatement(
    TryStatement s, CompilerContext ctx, AlwaysReturnType? expectedReturnType) {
  int jumpOver = -1;
  if (s.finallyBlock != null) {
    final loc = ctx.pushOp(PushFinally.make(-1), PushFinally.LEN);
    ctx.pushOp(PushReturnFromCatch.make(), PushReturnFromCatch.LEN);
    ctx.beginAllocScope();
    final bodyInfo = compileBlock(s.finallyBlock!, expectedReturnType, ctx);
    if (!bodyInfo.willAlwaysReturn && !bodyInfo.willAlwaysThrow) {
      /// If the finally block doesn't return, we may need to return the value from the try block
      ctx.pushOp(Return.make(-2), Return.LEN);
    }
    ctx.endAllocScope(popValues: true);
    jumpOver = ctx.pushOp(JumpConstant.make(-1), JumpConstant.LEN);
    ctx.rewriteOp(loc, PushFinally.make(ctx.out.length), 0);
  }

  final tryOp = ctx.pushOp(Try.make(-1), Try.LEN);

  final initialState = ctx.saveState();

  ctx.beginAllocScope();
  ctx.labels.add(SimpleCompilerLabel());
  final bodyInfo = compileBlock(s.body, expectedReturnType, ctx);
  ctx.labels.removeLast();
  ctx.endAllocScope();

  ctx.resolveBranchStateDiscontinuity(initialState);

  ctx.pushOp(PopCatch.make(), PopCatch.LEN);

  if (s.finallyBlock == null) {
    jumpOver = ctx.pushOp(JumpConstant.make(-1), JumpConstant.LEN);
  } else {
    ctx.pushOp(Return.make(-3), JumpConstant.LEN);
  }

  ctx.rewriteOp(
      tryOp, Try.make(s.catchClauses.isNotEmpty ? ctx.out.length : -1), 0);

  var catchInfo = StatementInfo(-1);
  if (s.catchClauses.isNotEmpty) {
    final state = ctx.saveState();
    ctx.beginAllocScope();
    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    final v = Variable.alloc(ctx, CoreTypes.dynamic.ref(ctx));
    ctx.caughtExceptions.add(v);
    catchInfo =
        _compileCatchClause(ctx, s.catchClauses, 0, v, expectedReturnType);
    ctx.caughtExceptions.removeLast();
    ctx.endAllocScope();
    ctx.resolveBranchStateDiscontinuity(state);
    ctx.pushOp(Return.make(-3), Return.LEN);
  }

  ctx.rewriteOp(jumpOver, JumpConstant.make(ctx.out.length), 0);

  return bodyInfo | catchInfo.copyWith(willAlwaysThrow: false);
}

// Catch clauses are compiled into a single effective catch clause
// with a series of branches to check types for 'on' clauses.
StatementInfo _compileCatchClause(
    CompilerContext ctx,
    List<CatchClause> clauses,
    int index,
    Variable exceptionVar,
    AlwaysReturnType? expectedReturnType) {
  final catchClause = clauses[index];
  final exceptionType = catchClause.exceptionType;

  if (exceptionType == null) {
    ctx.setLocal(catchClause.exceptionParameter!.name.lexeme, exceptionVar);
    return compileBlock(catchClause.body, expectedReturnType, ctx);
  }
  final slot = TypeRef.fromAnnotation(ctx, ctx.library, exceptionType);
  return macroBranch(ctx, expectedReturnType, condition: (ctx) {
    ctx.pushOp(
        IsType.make(
            exceptionVar.scopeFrameOffset, ctx.typeRefIndexMap[slot]!, false),
        IsType.length);
    return Variable.alloc(ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
  }, thenBranch: (ctx, expectedReturnType) {
    ctx.setLocal(catchClause.exceptionParameter!.name.lexeme,
        exceptionVar.copyWith(type: slot));
    return compileBlock(catchClause.body, expectedReturnType, ctx);
  },
      elseBranch: clauses.length <= index + 1
          ? null
          : (ctx, expectedReturnType) {
              return _compileCatchClause(
                  ctx, clauses, index + 1, exceptionVar, expectedReturnType);
            },
      source: catchClause);
}

///
