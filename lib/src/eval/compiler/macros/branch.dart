import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/expression/condition.dart';
import 'package:dart_eval/src/eval/compiler/macros/macro.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import '../values/value_rep.dart';
import '../variable/binding.dart';

typedef MacroConditionGraph =
    (BasicBlockBuilder, bool, bool) Function(
      CompilerContext ctx,
      BasicBlock<Operation> whenTrue,
      BasicBlock<Operation> whenFalse,
    );

/// A null comparison never calls an overridden equality operator.
Variable compileNullCondition(CompilerContext ctx, Variable value) =>
    Variable.ssa(
      ctx,
      switch (value.representation) {
        MachineRepresentation.integer ||
        MachineRepresentation.doublePrecision ||
        MachineRepresentation.boolean => LoadBool(ctx.svar('is_null'), false),
        _ => IsNull(ctx.svar('is_null'), value.ssa),
      },
      CoreTypes.bool.ref(ctx),
      rep: ValueRep.bool,
    );

/// Emits `value != null` as an unboxed-bool condition suitable for
/// [macroBranch]'s `condition` closure.
Variable compileNonNullCondition(CompilerContext ctx, Variable value) {
  final boolType = CoreTypes.bool.ref(ctx);
  final isNull = compileNullCondition(ctx, value);
  return Variable.ssa(
    ctx,
    LogicalNot(ctx.svar('nonnull_ne'), isNull.ssa),
    boolType,
    rep: ValueRep.bool,
  );
}

StatementInfo macroBranch(
  CompilerContext ctx,
  TypeRef? expectedReturnType, {
  MacroVariableClosure? condition,
  Expression? conditionExpression,
  MacroConditionGraph? conditionGraph,
  required MacroStatementClosure thenBranch,
  MacroStatementClosure? elseBranch,
  AstNode? source,
  bool testNullish = false,
  bool Function()? thenEdgeUnreachable,
  bool Function()? elseEdgeUnreachable,
}) {
  assert(
    [
          condition,
          conditionExpression,
          conditionGraph,
        ].where((c) => c != null).length ==
        1,
  );
  assert(!testNullish || conditionExpression == null);
  ctx.beginScope();
  ctx.enterTypeInferenceContext();

  final thenBlock = BasicBlock<Operation>([], label: ctx.label('if_true'));
  final elseBlock = BasicBlock<Operation>([], label: ctx.label('if_false'));
  final endBlock = BasicBlock<Operation>([], label: ctx.label('if_end'));
  final BasicBlockBuilder branches;
  var thenReachable = true;
  var elseReachable = true;
  Map<String, LocalBinding>? conditionLocals;
  if (conditionGraph != null) {
    // Pattern variables exist only on the successful edge, including guards.
    ctx.beginScope();
    final result = conditionGraph(ctx, thenBlock, elseBlock);
    branches = result.$1;
    thenReachable = result.$2;
    elseReachable = result.$3;
    conditionLocals = ctx.locals.removeLast();
  } else if (conditionExpression != null) {
    final condition = compileCondition(
      conditionExpression,
      ctx,
      thenBlock,
      elseBlock,
    );
    branches = condition.$1;
    thenReachable = condition.$2;
    elseReachable = condition.$3;
  } else {
    final rawCondition = condition!(ctx);
    if (!testNullish) {
      enforceConditionType(ctx, rawCondition, source);
    }
    final conditionResult = testNullish
        ? rawCondition
        : convertForAssignment(
            ctx,
            rawCondition,
            CoreTypes.bool.ref(ctx),
            representation: MachineRepresentation.boolean,
            source: source,
            description: "Conditions must have a static type of 'bool'",
          );
    ctx.pushOp(
      testNullish
          ? JumpIfNonNull(conditionResult.ssa, elseBlock.label!)
          : JumpIfFalse(conditionResult.ssa, elseBlock.label!),
    );
    ctx.flushBlock();
    branches = ctx.builder.split(thenBlock, elseBlock);
  }
  final initialState = ctx.saveState();

  ctx.builder = branches.block(0);
  ctx.inferTypes();
  if (conditionLocals != null) ctx.locals.add(conditionLocals);
  ctx.beginScope();
  final thenResult = thenBranch(ctx, expectedReturnType);
  ctx.endScope();
  if (conditionLocals != null) ctx.endScope();
  final thenState = ctx.saveState();
  ctx.uninferTypes();
  final thenEndsFlow = ctx.flowTerminated;
  if (!thenResult.willAlwaysReturn &&
      !thenResult.willAlwaysThrow &&
      !thenResult.willAlwaysBreak &&
      !thenEndsFlow) {
    ctx.resolveBranchStateDiscontinuity(initialState);
    ctx.pushOp(Jump(endBlock.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, endBlock);
  } else if (ctx.blockCode.isNotEmpty) {
    ctx.flushBlock();
  }
  ctx.restoreState(initialState);

  ctx.builder = branches.block(1);
  if (conditionExpression != null) {
    applyConditionPromotions(ctx, conditionExpression, false);
  }
  ctx.beginScope();
  final elseResult =
      elseBranch?.call(ctx, expectedReturnType) ?? StatementInfo();
  ctx.endScope();
  final elseEndsFlow = ctx.flowTerminated;
  final elseState = ctx.saveState();
  if (!elseResult.willAlwaysReturn &&
      !elseResult.willAlwaysThrow &&
      !elseResult.willAlwaysBreak &&
      !elseEndsFlow) {
    ctx.resolveBranchStateDiscontinuity(initialState);
    ctx.pushOp(Jump(endBlock.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, endBlock);
  } else if (ctx.blockCode.isNotEmpty) {
    ctx.flushBlock();
  }
  // Select the join without introducing edges from terminated or statically
  // unreachable branches.
  ctx.builder = BasicBlockBuilder(ctx.activeGraph, [endBlock], branches);
  ctx.builder.float(endBlock);
  final thenContinues =
      thenReachable &&
      thenEdgeUnreachable?.call() != true &&
      !thenEndsFlow &&
      !thenResult.willAlwaysReturn &&
      !thenResult.willAlwaysThrow &&
      !thenResult.willAlwaysBreak;
  final elseContinues =
      elseReachable &&
      elseEdgeUnreachable?.call() != true &&
      !elseEndsFlow &&
      !elseResult.willAlwaysReturn &&
      !elseResult.willAlwaysThrow &&
      !elseResult.willAlwaysBreak;
  ctx.restoreState(
    !thenContinues && elseContinues
        ? elseState
        : thenContinues && !elseContinues
        ? thenState
        : initialState,
  );
  // Surviving snapshots retain their flow facts, but their outgoing edges
  // already converted local storage back to the initial representation.
  ctx.restoreBoxingState(initialState);
  if (thenContinues && elseContinues) {
    ctx.mergeBranchState([thenState, elseState]);
    for (var i = 0; i < ctx.locals.length; i++) {
      for (final entry in ctx.locals[i].entries) {
        final thenType = thenState.locals[i][entry.key]?.current.type;
        final elseType = elseState.locals[i][entry.key]?.current.type;
        final current = entry.value.current;
        if (thenType != null &&
            thenType == elseType &&
            isPromotionSubtype(ctx, thenType, current.type)) {
          entry.value.rebind(current.withType(thenType));
        }
      }
    }
  }
  ctx.endScope();
  final info = thenResult | elseResult;
  if (!thenContinues && !elseContinues) {
    // No edge reaches the join — anything after is dead code. It still
    // analyzes, so keep compiling, but report that control never continues
    // (willAlwaysThrow doubles as the "unreachable" marker elsewhere).
    return info.copyWith(
      willAlwaysThrow:
          markNeverTerminates(ctx).willAlwaysThrow || info.willAlwaysThrow,
    );
  }
  return info;
}
