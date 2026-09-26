import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/helpers/assigned_locals.dart';
import 'package:dart_eval/src/eval/compiler/variable/binding.dart';
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
import '../backend/representation.dart';
import '../values/value_rep.dart';

StatementInfo compileTryStatement(
  TryStatement s,
  CompilerContext ctx,
  TypeRef? expectedReturnType,
) {
  final catchBlock = s.catchClauses.isEmpty
      ? null
      : BasicBlock<Operation>([], label: ctx.label('catch'));
  final finallyBlock = s.finallyBlock == null
      ? null
      : BasicBlock<Operation>([], label: ctx.label('finally'));
  final endBlock = BasicBlock<Operation>([], label: ctx.label('try_end'));
  final bodyBlock = BasicBlock<Operation>([], label: ctx.label('try_body'));
  final outerState = ctx.saveState();
  final captureSlots = <(int, String), ExceptionSlot>{};
  // Mutable bindings crossing a handler boundary live in typed frame slots.
  // An exception can leave between any two operations, so edge phi copies
  // cannot preserve the current value of a binding.
  for (var frame = 0; frame < ctx.locals.length; frame++) {
    for (final entry in ctx.locals[frame].entries.toList()) {
      final binding = entry.value;
      final current = binding.current;
      if (binding.captureCell case final cell?) {
        final slot = ExceptionSlot(
          ctx.svar('handler_cell').name,
          MachineRepresentation.object,
        );
        captureSlots[(frame, entry.key)] = slot;
        ctx.pushOp(StoreExceptionSlot(slot, cell));
        binding.storeInExceptionSlot(slot);
      } else if (binding.storage is! ExceptionSlotStorage) {
        final slot = ExceptionSlot(
          ctx.svar('handler_local').name,
          current.representation,
        );
        ctx.pushOp(StoreExceptionSlot(slot, current.ssa));
        binding.storeInExceptionSlot(slot);
      }
    }
  }
  final initialState = ctx.saveState();
  // A local the try body may have reassigned: on the exceptional edge into
  // `catch`/`finally` its slot may hold the written value, so handler entry
  // demotes it to its declared type with facts cleared.
  final tryAssigned = assignedLocalNames([s.body]);

  void restoreBindings({ContextSaveState? flowInto, bool leaving = false}) {
    ctx.restoreState(leaving ? outerState : (flowInto ?? initialState));
    if (!leaving) {
      for (final name in tryAssigned) {
        final binding = ctx.lookupBinding(name);
        if (binding == null) continue;
        final value = binding.current.withType(binding.declaredType);
        // The epoch bump invalidates condition records another local holds
        // on this one (`b` recorded `x` non-null; `x` reassigned in the try
        // body can't be relied on once an exception may have left midway).
        binding.rebind(value.withFacts(value.facts.cleared()));
        binding.current.writeEpoch = value.writeEpoch + 1;
      }
    }
    for (var frame = 0; frame < ctx.locals.length; frame++) {
      for (final entry in ctx.locals[frame].entries.toList()) {
        final binding = entry.value;
        final current = binding.current;
        final cellSlot = captureSlots[(frame, entry.key)];
        final slot =
            cellSlot ??
            switch (initialState.locals[frame][entry.key]!.storage) {
              ExceptionSlotStorage s => s.slot,
              _ => null,
            };
        if (slot == null) continue;
        final loaded = cellSlot == null
            ? current.ssa
            : entry.value.captureCell!;
        ctx.pushOp(LoadExceptionSlot(loaded, slot));
      }
    }
  }

  ctx.pushOp(
    EnterTry(
      catchTarget: catchBlock?.label,
      finallyTarget: finallyBlock?.label,
    ),
  );
  ctx.pushOp(Jump(bodyBlock.label!));
  final entry = ctx.flushBlock();
  final parent = ctx.builder;
  ctx.builder.link(entry, bodyBlock);
  if (catchBlock != null) ctx.builder.link(entry, catchBlock);
  if (finallyBlock != null) ctx.builder.link(entry, finallyBlock);
  ctx.builder = BasicBlockBuilder(ctx.activeGraph, [bodyBlock], parent);
  ctx.exceptionDepth++;
  bool completes(StatementInfo info) =>
      !info.willAlwaysReturn && !info.willAlwaysThrow && !info.willAlwaysBreak;
  void finishProtected(StatementInfo info) {
    if (completes(info)) {
      ctx.pushOp(LeaveTry());
      ctx.pushOp(Jump((finallyBlock ?? endBlock).label!));
      final tail = ctx.flushBlock();
      ctx.builder.link(tail, finallyBlock ?? endBlock);
    } else if (ctx.blockCode.isNotEmpty) {
      ctx.flushBlock();
    }
  }

  final bodyInfo = compileBlock(s.body, expectedReturnType, ctx);
  final bodyExitState = completes(bodyInfo) ? ctx.saveState() : null;
  finishProtected(bodyInfo);
  var catchInfo = StatementInfo(willAlwaysThrow: true);
  ContextSaveState? catchExitState;
  if (catchBlock != null) {
    ctx.builder = BasicBlockBuilder(ctx.activeGraph, [catchBlock], parent);
    restoreBindings();
    ctx.beginScope();
    final exception = Variable.ssa(
      ctx,
      CaughtException(ctx.svar('exception')),
      CoreTypes.dynamic.ref(ctx),
    );
    ctx.caughtExceptionTargets.add(catchBlock.label!);
    catchInfo = _compileCatchClause(
      ctx,
      s.catchClauses,
      0,
      exception,
      expectedReturnType,
    );
    ctx.caughtExceptionTargets.removeLast();
    ctx.endScope();
    catchExitState = completes(catchInfo) ? ctx.saveState() : null;
    finishProtected(catchInfo);
  }
  StatementInfo? finalInfo;
  ContextSaveState? finallyEntryState;
  ContextSaveState? finallyExitState;
  if (finallyBlock != null) {
    ctx.builder = BasicBlockBuilder(ctx.activeGraph, [finallyBlock], parent);
    restoreBindings();
    finallyEntryState = ctx.saveState();
    finalInfo = compileBlock(s.finallyBlock!, expectedReturnType, ctx);
    if (completes(finalInfo)) {
      finallyExitState = ctx.saveState();
      final normalCompletion =
          completes(bodyInfo) || catchBlock != null && completes(catchInfo);
      ctx.pushOp(ResumeCompletion(terminal: !normalCompletion));
      if (normalCompletion) ctx.pushOp(Jump(endBlock.label!));
      final tail = ctx.flushBlock();
      if (normalCompletion) ctx.builder.link(tail, endBlock);
    } else if (ctx.blockCode.isNotEmpty) {
      ctx.flushBlock();
    }
  }
  ctx.exceptionDepth--;
  ctx.builder.float(endBlock);
  ctx.builder = BasicBlockBuilder(ctx.activeGraph, [endBlock], parent);
  restoreBindings(leaving: true);
  // The flow state reaching `endBlock` is the join of the normal-completion
  // edges — the try body and each completing catch. An exceptional edge
  // rethrows out of `finally`; it never arrives here.
  final normalExits = [?bodyExitState, ?catchExitState];
  for (var frame = 0; frame < ctx.locals.length; frame++) {
    for (final entry in ctx.locals[frame].entries) {
      final binding = entry.value;
      var sawEdge = false;
      var type = binding.current.type;
      var facts = binding.current.facts;
      var epoch = binding.current.writeEpoch;
      for (final state in normalExits) {
        final other = state.locals[frame][entry.key]?.current;
        if (other == null) continue;
        type = sawEdge && other.type != type
            ? TypeRef.commonBaseType(ctx, {type, other.type})
            : other.type;
        facts = sawEdge ? facts.join(other.facts) : other.facts;
        if (!sawEdge || other.writeEpoch > epoch) epoch = other.writeEpoch;
        sawEdge = true;
      }
      // Writes inside `finally` apply on top: they show up as an epoch bump
      // relative to the state the finally block started from.
      if (sawEdge) {
        final value = binding.current.copyWith(type: type, facts: facts)
          ..writeEpoch = epoch;
        binding.rebind(value);
      }
      final finallyExit =
          finallyExitState?.locals[frame][entry.key]?.current;
      final finallyEntry =
          finallyEntryState?.locals[frame][entry.key]?.current;
      if (finallyExit != null &&
          finallyEntry != null &&
          finallyExit.writeEpoch > finallyEntry.writeEpoch) {
        binding.rebind(finallyExit.copyWith());
      }
    }
  }
  if (finalInfo != null && !completes(finalInfo)) return finalInfo;
  return catchBlock == null ? bodyInfo : bodyInfo | catchInfo;
}

// Catch clauses are compiled into a single effective catch clause
// with a series of branches to check types for 'on' clauses.
StatementInfo _compileCatchClause(
  CompilerContext ctx,
  List<CatchClause> clauses,
  int index,
  Variable exceptionVar,
  TypeRef? expectedReturnType,
) {
  final catchClause = clauses[index];
  final exceptionType = catchClause.exceptionType;

  if (exceptionType == null) {
    if (catchClause.exceptionParameter != null) {
      _bindException(ctx, catchClause, exceptionVar, exceptionVar.type);
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
          ctx.runtimeTypes.idOf(slot),
          false,
        ),
        CoreTypes.bool.ref(ctx),
        rep: ValueRep.bool,
      );
    },
    thenBranch: (ctx, expectedReturnType) {
      if (catchClause.exceptionParameter != null) {
        _bindException(ctx, catchClause, exceptionVar, slot);
      }
      _bindStackTrace(ctx, catchClause);
      return compileBlock(catchClause.body, expectedReturnType, ctx);
    },
    elseBranch: clauses.length <= index + 1
        ? (ctx, _) {
            ctx.pushOp(Rethrow(ctx.caughtExceptionTargets.last));
            return StatementInfo(willAlwaysThrow: true);
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

void _bindException(
  CompilerContext ctx,
  CatchClause clause,
  Variable exception,
  TypeRef type,
) {
  // Assigning to a catch parameter must not replace the value of `rethrow`.
  // A `_` catch parameter is a wildcard: non-binding.
  if (clause.exceptionParameter!.name.lexeme != '_') {
    ctx.setLocal(
      clause.exceptionParameter!.name.lexeme,
      Variable.ssa(
        ctx,
        Assign(
          ctx.svar('catch_parameter'),
          (exception.binding?.read(ctx) ?? exception).ssa,
        ),
        type,
        rep: ValueRep.boxed,
      ),
    );
  }
}

void _bindStackTrace(CompilerContext ctx, CatchClause clause) {
  final parameter = clause.stackTraceParameter;
  if (parameter != null && parameter.name.lexeme != '_') {
    ctx.setLocal(
      parameter.name.lexeme,
      Variable.ssa(
        ctx,
        CaughtStackTrace(ctx.svar('stack_trace')),
        CoreTypes.stackTrace.ref(ctx),
        rep: ValueRep.boxed,
      ),
    );
  }
}
