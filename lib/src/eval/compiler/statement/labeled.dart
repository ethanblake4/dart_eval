import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable/binding.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

/// Compiles a `label:`-prefixed statement.
///
/// Loops and switches push their own [CompilerLabel], so we hand our names to
/// the next label pushed via [CompilerContext.pendingLabelNames]. For any
/// other labeled statement (`lbl: { ... }`, `lbl: if (...) ...`, ...) we
/// synthesize a break target that continues right after the statement; such
/// labels answer `break name` but never `continue name`.
StatementInfo compileLabeledStatement(
  LabeledStatement s,
  CompilerContext ctx,
  TypeRef? expectedReturnType,
) {
  final inner = s.statement;
  ctx.pendingLabelNames.addAll(s.labels.map((l) => l.name.lexeme));

  if (inner is WhileStatement ||
      inner is DoStatement ||
      inner is ForStatement ||
      inner is SwitchStatement ||
      inner is LabeledStatement) {
    try {
      return compileStatement(inner, expectedReturnType, ctx);
    } finally {
      ctx.pendingLabelNames.removeAll(s.labels.map((l) => l.name.lexeme));
    }
  }

  final exit = BasicBlock<Operation>([], label: ctx.label('labeled_exit'));
  final initialState = ctx.saveState();
  ctx.labels.add(
    CompilerLabel(
      (ctx) => ctx.resolveBranchStateDiscontinuity(initialState),
      exceptionDepth: ctx.exceptionDepth,
      breakTarget: exit,
      names: ctx.takePendingLabelNames(),
    ),
  );
  final result = compileStatement(inner, expectedReturnType, ctx);
  ctx.labels.removeLast();
  final parent = ctx.builder;
  if (!result.willAlwaysReturn &&
      !result.willAlwaysThrow &&
      !result.willAlwaysBreak &&
      !ctx.blockEndsControlFlow) {
    ctx.resolveBranchStateDiscontinuity(initialState);
    ctx.pushOp(Jump(exit.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, exit);
  } else if (ctx.blockCode.isNotEmpty) {
    ctx.flushBlock();
  }
  ctx.builder.float(exit);
  ctx.builder = BasicBlockBuilder(ctx.activeGraph, [exit], parent);
  // Declarations inside the labeled statement belong to the enclosing
  // block's scope, so they must survive restoring the pre-statement state.
  final declaredInside = <int, Map<String, LocalBinding>>{};
  for (var i = 0; i < ctx.locals.length; i++) {
    for (final entry in ctx.locals[i].entries) {
      final prior = i < initialState.locals.length
          ? initialState.locals[i][entry.key]
          : null;
      if (prior == null || !identical(prior.binding, entry.value)) {
        (declaredInside[i] ??= {})[entry.key] = entry.value;
      }
    }
  }
  ctx.restoreState(initialState);
  declaredInside.forEach((i, declared) {
    if (i < ctx.locals.length) {
      ctx.locals[i].addAll(declared);
    }
  });
  // A break to this label reaches the following statement even when another
  // path returns or throws. Breaks to an outer label still leave this block.
  return ctx.activeGraph.graph.predecessorsOf(exit.id!).isNotEmpty
      ? StatementInfo()
      : result;
}
