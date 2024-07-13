import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/macros/macro.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

StatementInfo macroBranch(
    CompilerContext ctx, AlwaysReturnType? expectedReturnType,
    {required MacroVariableClosure condition,
    required MacroStatementClosure thenBranch,
    MacroStatementClosure? elseBranch,
    bool resolveStateToThen = false,
    AstNode? source,
    bool testNullish = false}) {
  ctx.beginAllocScope();
  ctx.enterTypeInferenceContext();

  final conditionResult = condition(ctx).unboxIfNeeded(ctx);

  if (!testNullish &&
      !conditionResult.type.isAssignableTo(ctx, CoreTypes.bool.ref(ctx))) {
    throw CompileError("Conditions must have a static type of 'bool'", source);
  }

  final trueLabel = ctx.label(testNullish ? 'if_true' : 'if_null');
  final falseLabel = ctx.label(testNullish ? 'if_false' : 'if_nonnull');
  final endLabel = ctx.label('if_end');

  if (testNullish) {
    ctx.pushOp(JumpIfNonNull(conditionResult.ssa, falseLabel));
  } else {
    ctx.pushOp(JumpIfFalse(conditionResult.ssa, falseLabel));
  }

  final condBlock = BasicBlock(ctx.commit());
  ctx.builder = ctx.builder.merge(condBlock);

  final trueBlock = BasicBlock<Operation>([], label: trueLabel);
  final falseBlock = BasicBlock<Operation>([], label: falseLabel);
  final endBlock = BasicBlock<Operation>([], label: endLabel);

  if (elseBranch != null) {
    ctx.builder = ctx.builder.split(trueBlock, falseBlock).block(0);
  } else {
    ctx.builder = ctx.builder.then(trueBlock);
    ctx.builder.link(condBlock, endBlock);
  }

  var _initialState = ctx.saveState();
  ctx.inferTypes();
  ctx.beginAllocScope();
  final label = CompilerLabel(trueLabel, LabelType.branch, (_ctx) {
    _ctx.endAllocScopeQuiet();
    if (!resolveStateToThen) {
      _ctx.resolveBranchStateDiscontinuity(_initialState);
    }
    _ctx.endAllocScopeQuiet();
    return -1;
  });
  ctx.labels.add(label);
  final thenResult = thenBranch(ctx, expectedReturnType);
  ctx.labels.removeLast();
  ctx.endAllocScope();
  ctx.uninferTypes();

  if (!resolveStateToThen) {
    ctx.resolveBranchStateDiscontinuity(_initialState);
  } else {
    _initialState = ctx.saveState();
  }

  if (elseBranch != null) {
    ctx.pushOp(Jump(endLabel));
  }

  ctx.builder = ctx.builder.then(BasicBlock(ctx.commit())).commit();

  if (elseBranch != null) {
    ctx.builder = ctx.builder.block(1);
    ctx.beginAllocScope();
    final label = CompilerLabel(falseLabel, LabelType.branch, (_ctx) {
      ctx.endAllocScope();
      ctx.resolveBranchStateDiscontinuity(_initialState);
      ctx.endAllocScope();
      return -1;
    });
    ctx.labels.add(label);
    final elseResult = elseBranch(ctx, expectedReturnType);
    ctx.labels.removeLast();
    ctx.endAllocScope();
    ctx.resolveBranchStateDiscontinuity(_initialState);
    ctx.builder =
        ctx.builder.then(BasicBlock(ctx.commit())).commit().merge(endBlock);
    ctx.endAllocScope();
    endBlock.code.addAll(ctx.commit());
    return thenResult | elseResult;
  }

  ctx.endAllocScope();
  endBlock.code.addAll(ctx.commit());

  return thenResult |
      StatementInfo(thenResult.position,
          willAlwaysThrow: false, willAlwaysReturn: false);
}
