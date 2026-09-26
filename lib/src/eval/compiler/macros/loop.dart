import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:analyzer/dart/ast/ast.dart';
import '../helpers/assigned_locals.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/expression/condition.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
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
  ctx.widenAssignedLocals(assignedLocalNames(assignedNamesScan));
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
      ctx.builder = compileCondition(
        conditionExpression,
        ctx,
        bodyBlock,
        exit,
      ).block(0);
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
      !ctx.blockEndsControlFlow) {
    ctx.resolveBranchStateDiscontinuity(initialState);
    bodyExitState = ctx.saveState();
    ctx.pushOp(Jump(continueTarget.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, continueTarget);
  } else if (ctx.blockCode.isNotEmpty) {
    ctx.flushBlock();
  }

  // A continue edge can reach the update/condition even if the body never
  // falls through. Emit these blocks independently of the body's exit flags.
  if (updateBlock?.id != null) {
    ctx.restoreState(initialState);
    ctx.mergeBranchState([?bodyExitState, ...edgeStates]);
    ctx.builder = BasicBlockBuilder(ctx.activeGraph, [updateBlock!], parent);
    update!.call(ctx);
    ctx.resolveBranchStateDiscontinuity(initialState);
    ctx.pushOp(Jump(header.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, header);
  }
  if (alwaysLoopOnce && header.id != null) {
    ctx.restoreState(initialState);
    ctx.mergeBranchState([?bodyExitState, ...edgeStates]);
    ctx.builder = BasicBlockBuilder(ctx.activeGraph, [header], parent);
    if (conditionExpression != null) {
      compileCondition(conditionExpression, ctx, bodyBlock, exit);
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
  ctx.mergeBranchState([?bodyExitState, ...edgeStates]);
  after?.call(ctx);
  ctx.endScope();
  return alwaysLoopOnce
      ? result.copyWith(willAlwaysBreak: false)
      : StatementInfo();
}
