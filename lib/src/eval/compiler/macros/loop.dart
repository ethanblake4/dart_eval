import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:analyzer/dart/ast/ast.dart';
import '../helpers/assigned_locals.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/expression/condition.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/macro.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';

StatementInfo macroLoop(
  CompilerContext ctx,
  TypeRef? expectedReturnType, {
  required MacroStatementClosure body,
  MacroClosure? initialization,
  MacroVariableClosure? condition,
  Expression? conditionExpression,
  MacroClosure? update,
  MacroClosure? after,
  bool alwaysLoopOnce = false,
  bool updateBeforeBody = false,
  Iterable<AstNode> assignedNamesScan = const [],
}) {
  assert(condition == null || conditionExpression == null);
  ctx.beginScope();
  initialization?.call(ctx);
  // Locals reassigned by the body or updaters can hold a differently-typed
  // value on the back edge, so their allocation proofs are dropped before
  // the header/condition is compiled against the pre-loop state.
  ctx.widenAssignedLocals(assignedLoopLocalNames(assignedNamesScan));
  final initialState = ctx.saveState();
  final edgeStates = <ContextSaveState>[];
  final header = BasicBlock<Operation>([], label: ctx.label('loop_header'));
  final bodyBlock = BasicBlock<Operation>([], label: ctx.label('loop_body'));
  final exit = BasicBlock<Operation>([], label: ctx.label('loop_exit'));
  final updateBlock = update != null && !updateBeforeBody
      ? BasicBlock<Operation>([], label: ctx.label('loop_update'))
      : null;
  final continueTarget = updateBlock ?? header;
  ctx.flushBlock();
  final parent = ctx.builder;
  ctx.builder = ctx.builder.then(alwaysLoopOnce ? bodyBlock : header);

  if (!alwaysLoopOnce) {
    if (conditionExpression != null) {
      // Record the condition's promotions into an inference save state,
      // then restore them into the live state for the loop body — the
      // back edge merges any narrower types the body computed.
      ctx.enterTypeInferenceContext();
      ctx.builder = compileCondition(
        conditionExpression,
        ctx,
        bodyBlock,
        exit,
      ).$1
          .block(0);
      ctx.inferTypes();
    } else if (condition != null) {
      final value = convertForAssignment(
        ctx,
        condition(ctx),
        CoreTypes.bool.ref(ctx),
        representation: MachineRepresentation.boolean,
      );
      ctx.pushOp(JumpIfFalse(value.ssa, exit.label!));
      ctx.flushBlock();
      ctx.builder = ctx.builder.split(bodyBlock, exit).block(0);
    } else {
      ctx.builder = ctx.builder.then(bodyBlock);
    }
  }

  ctx.beginScope();
  if (updateBeforeBody) update?.call(ctx);
  final label = CompilerLabel(
    (ctx) {
      ctx.resolveBranchStateDiscontinuity(initialState);
      edgeStates.add(ctx.saveState());
    },
    exceptionDepth: ctx.exceptionDepth,
    breakTarget: exit,
    continueTarget: continueTarget,
    names: ctx.takePendingLabelNames(),
  );
  ctx.labels.add(label);
  final result = body(ctx, expectedReturnType);
  ctx.labels.removeLast();
  ctx.endScope();
  ContextSaveState? bodyExitState;
  if (!result.willAlwaysReturn &&
      !result.willAlwaysThrow &&
      !result.willAlwaysBreak &&
      !ctx.flowTerminated) {
    ctx.resolveBranchStateDiscontinuity(initialState);
    bodyExitState = ctx.saveState();
    ctx.pushOp(Jump(continueTarget.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, continueTarget);
  } else if (ctx.blockCode.isNotEmpty) {
    ctx.flushBlock();
  }
  // The body's promoted state joined the back edge already; the exit edge
  // computes its own from the pre-condition state.
  if (conditionExpression != null && !alwaysLoopOnce) ctx.uninferTypes();

  // A continue edge can reach the update/condition even if the body never
  // falls through. Emit these blocks independently of the body's exit flags.
  if (updateBlock?.id != null) {
    ctx.restoreState(initialState);
    ctx.mergeBranchState([?bodyExitState, ...edgeStates]);
    // The update runs only on the condition's true edge —
    // `for (; x is int; f(x))` sees `x` promoted.
    if (conditionExpression != null) {
      applyConditionPromotions(ctx, conditionExpression, true);
    }
    ctx.builder = BasicBlockBuilder(ctx.activeGraph, [updateBlock!], parent);
    update!.call(ctx);
    ctx.resolveBranchStateDiscontinuity(initialState);
    ctx.pushOp(Jump(header.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, header);
  }
  ContextSaveState? conditionExitState;
  if (alwaysLoopOnce && header.id != null) {
    ctx.restoreState(initialState);
    ctx.mergeBranchState([?bodyExitState, ...edgeStates]);
    ctx.builder = BasicBlockBuilder(ctx.activeGraph, [header], parent);
    if (conditionExpression != null) {
      ctx.enterTypeInferenceContext();
      compileCondition(conditionExpression, ctx, bodyBlock, exit);
      ctx.typeInferenceSaveStates.removeLast();
      applyConditionPromotions(ctx, conditionExpression, false);
      conditionExitState = ctx.saveState();
    } else if (condition != null) {
      final value = convertForAssignment(
        ctx,
        condition(ctx),
        CoreTypes.bool.ref(ctx),
        representation: MachineRepresentation.boolean,
      );
      ctx.pushOp(JumpIfFalse(value.ssa, exit.label!));
      final tail = ctx.flushBlock();
      ctx.builder.link(tail, exit);
      ctx.builder.link(tail, bodyBlock);
    } else {
      ctx.pushOp(Jump(bodyBlock.label!));
      final tail = ctx.flushBlock();
      ctx.builder.link(tail, bodyBlock);
    }
  }

  ctx.builder.float(exit);
  ctx.builder = BasicBlockBuilder(ctx.activeGraph, [exit], parent);
  ctx.restoreState(initialState);
  // `while (cond) {...}` reaches the exit with cond false, so its
  // false-edge promotions apply to post-loop code. (For `do {} while`,
  // they were already applied onto the merged back-edge state above.)
  if (conditionExpression != null && !alwaysLoopOnce) {
    applyConditionPromotions(ctx, conditionExpression, false);
  }
  ctx.mergeBranchState([
    ?conditionExitState,
    ?bodyExitState,
    ...edgeStates,
  ]);
  after?.call(ctx);
  ctx.endScope();
  // A break can reach the loop's exit even when the body expression has
  // type Never. Retain divergence only when no edge reaches that exit.
  return alwaysLoopOnce &&
          ctx.activeGraph.graph.predecessorsOf(exit.id!).isEmpty
      ? result.copyWith(willAlwaysBreak: false)
      : StatementInfo();
}
