import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';
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
  required MacroStatementClosure thenBranch,
  MacroStatementClosure? elseBranch,
  AstNode? source,
  bool testNullish = false,
}) {
  assert((condition == null) != (conditionExpression == null));
  assert(!testNullish || conditionExpression == null);
  ctx.beginScope();
  ctx.enterTypeInferenceContext();

  final thenBlock = BasicBlock<Operation>([], label: ctx.label('if_true'));
  final elseBlock = BasicBlock<Operation>([], label: ctx.label('if_false'));
  final endBlock = BasicBlock<Operation>([], label: ctx.label('if_end'));
  final BasicBlockBuilder branches;
  if (conditionExpression != null) {
    branches = compileCondition(conditionExpression, ctx, thenBlock, elseBlock);
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
  ctx.beginScope();
  final thenResult = thenBranch(ctx, expectedReturnType);
  ctx.endScope();
  final thenState = ctx.saveState();
  ctx.uninferTypes();
  if (!thenResult.willAlwaysReturn &&
      !thenResult.willAlwaysThrow &&
      !thenResult.willAlwaysBreak &&
      !ctx.blockEndsControlFlow) {
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
  if (!elseResult.willAlwaysReturn &&
      !elseResult.willAlwaysThrow &&
      !elseResult.willAlwaysBreak &&
      !ctx.blockEndsControlFlow) {
    ctx.resolveBranchStateDiscontinuity(initialState);
    ctx.pushOp(Jump(endBlock.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, endBlock);
  } else if (ctx.blockCode.isNotEmpty) {
    ctx.flushBlock();
  }
  final elseState = ctx.saveState();
  // Select the join without introducing edges from terminated branches.
  ctx.builder = BasicBlockBuilder(ctx.activeGraph, [endBlock], branches);
  ctx.builder.float(endBlock);
  final thenContinues =
      !thenResult.willAlwaysReturn &&
      !thenResult.willAlwaysThrow &&
      !thenResult.willAlwaysBreak;
  final elseContinues =
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
  return thenResult | elseResult;
}
