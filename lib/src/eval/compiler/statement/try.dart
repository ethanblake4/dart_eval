import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/ir/exception.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

import '../variable.dart';

StatementInfo compileTryStatement(
  TryStatement s,
  CompilerContext ctx,
  AlwaysReturnType? expectedReturnType,
) {
  final catchBlock = s.catchClauses.isEmpty
      ? null
      : BasicBlock<Operation>([], label: ctx.label('catch'));
  final finallyBlock = s.finallyBlock == null
      ? null
      : BasicBlock<Operation>([], label: ctx.label('finally'));
  final endBlock = BasicBlock<Operation>([], label: ctx.label('try_end'));
  ctx.pushOp(
    EnterTry(
      catchTarget: catchBlock?.label,
      finallyTarget: finallyBlock?.label,
    ),
  );
  final entry = ctx.flushBlock();
  final parent = ctx.builder;
  final initialState = ctx.saveState();
  final firstProtectedId = ctx.activeGraph.lastBlockId;
  final bodyInfo = compileBlock(s.body, expectedReturnType, ctx);
  ctx.resolveBranchStateDiscontinuity(initialState);
  if (!bodyInfo.willAlwaysReturn &&
      !bodyInfo.willAlwaysThrow &&
      !bodyInfo.willAlwaysBreak) {
    ctx.pushOp(LeaveTry());
    ctx.pushOp(Jump((finallyBlock ?? endBlock).label!));
  }
  final tryTail = ctx.flushBlock();
  final lastProtectedId = ctx.activeGraph.lastBlockId;
  if (!bodyInfo.willAlwaysReturn &&
      !bodyInfo.willAlwaysThrow &&
      !bodyInfo.willAlwaysBreak) {
    ctx.builder.link(tryTail, finallyBlock ?? endBlock);
  }
  final handler = catchBlock ?? finallyBlock;
  if (handler != null) {
    ctx.builder.link(entry, handler);
    for (var id = firstProtectedId; id < lastProtectedId; id++) {
      ctx.builder.link(ctx.activeGraph[id]!, handler);
    }
  }

  var catchInfo = StatementInfo(-1);
  if (catchBlock != null) {
    ctx.restoreState(initialState);
    ctx.builder = BasicBlockBuilder(ctx.activeGraph, [catchBlock], parent);
    ctx.beginAllocScope();
    final exception = Variable.ssa(
      ctx,
      CaughtException(ctx.svar('exception')),
      CoreTypes.dynamic.ref(ctx),
    );
    ctx.caughtExceptions.add(exception);
    catchInfo = _compileCatchClause(
      ctx,
      s.catchClauses,
      0,
      exception,
      expectedReturnType,
    );
    ctx.caughtExceptions.removeLast();
    ctx.endAllocScope();
    ctx.resolveBranchStateDiscontinuity(initialState);
    if (!catchInfo.willAlwaysReturn &&
        !catchInfo.willAlwaysThrow &&
        !catchInfo.willAlwaysBreak) {
      ctx.pushOp(LeaveTry());
      ctx.pushOp(Jump((finallyBlock ?? endBlock).label!));
      final tail = ctx.flushBlock();
      ctx.builder.link(tail, finallyBlock ?? endBlock);
    } else if (ctx.blockCode.isNotEmpty) {
      ctx.flushBlock();
    }
  }

  if (finallyBlock != null) {
    ctx.restoreState(initialState);
    ctx.builder.float(finallyBlock);
    ctx.builder = BasicBlockBuilder(ctx.activeGraph, [finallyBlock], parent);
    final finalInfo = compileBlock(s.finallyBlock!, expectedReturnType, ctx);
    if (!finalInfo.willAlwaysReturn &&
        !finalInfo.willAlwaysThrow &&
        !finalInfo.willAlwaysBreak) {
      ctx.pushOp(ResumeCompletion());
      final tail = ctx.flushBlock();
      ctx.builder.link(tail, endBlock);
    } else if (ctx.blockCode.isNotEmpty) {
      ctx.flushBlock();
    }
  }
  ctx.builder.float(endBlock);
  ctx.builder = BasicBlockBuilder(ctx.activeGraph, [endBlock], parent);
  ctx.restoreState(initialState);
  return bodyInfo | catchInfo;
}

// Catch clauses are compiled into a single effective catch clause
// with a series of branches to check types for 'on' clauses.
StatementInfo _compileCatchClause(
  CompilerContext ctx,
  List<CatchClause> clauses,
  int index,
  Variable exceptionVar,
  AlwaysReturnType? expectedReturnType,
) {
  final catchClause = clauses[index];
  final exceptionType = catchClause.exceptionType;

  if (exceptionType == null) {
    if (catchClause.exceptionParameter != null) {
      ctx.setLocal(catchClause.exceptionParameter!.name.lexeme, exceptionVar);
    }
    _bindStackTrace(ctx, catchClause);
    return compileBlock(catchClause.body, expectedReturnType, ctx);
  }
  final slot = TypeRef.fromAnnotation(ctx, ctx.library, exceptionType);
  return macroBranch(
    ctx,
    expectedReturnType,
    condition: (ctx) {
      return Variable.ssa(
        ctx,
        IsType(
          ctx.svar('is_exception_type'),
          exceptionVar.ssa,
          slot.toRuntimeType(ctx).type,
          false,
        ),
        CoreTypes.bool.ref(ctx).copyWith(boxed: false),
      );
    },
    thenBranch: (ctx, expectedReturnType) {
      if (catchClause.exceptionParameter != null) {
        ctx.setLocal(
          catchClause.exceptionParameter!.name.lexeme,
          exceptionVar.copyWith(type: slot),
        );
      }
      _bindStackTrace(ctx, catchClause);
      return compileBlock(catchClause.body, expectedReturnType, ctx);
    },
    elseBranch: clauses.length <= index + 1
        ? (ctx, _) {
            ctx.pushOp(Rethrow(exceptionVar.ssa));
            return StatementInfo(-1, willAlwaysThrow: true);
          }
        : (ctx, expectedReturnType) {
            return _compileCatchClause(
              ctx,
              clauses,
              index + 1,
              exceptionVar,
              expectedReturnType,
            );
          },
    source: catchClause,
  );
}

void _bindStackTrace(CompilerContext ctx, CatchClause clause) {
  final parameter = clause.stackTraceParameter;
  if (parameter != null) {
    ctx.setLocal(
      parameter.name.lexeme,
      Variable.ssa(
        ctx,
        CaughtStackTrace(ctx.svar('stack_trace')),
        CoreTypes.stackTrace.ref(ctx),
      ),
    );
  }
}
