import 'package:control_flow_graph/control_flow_graph.dart' show Assign;
// ignore_for_file: experimental_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

import '../variable.dart';

/// Whether [e]'s leftmost receiver chain contains `?.` or `?[`. The walk
/// follows receiver positions only (targets of property/method/index access
/// and `!` operands, which continue the chain) — arguments and parenthesized
/// subexpressions break the chain.
bool isNullShorted(Expression? e) {
  var node = e;
  while (node != null) {
    if (node is PropertyAccess) {
      if (node.operator.type == TokenType.QUESTION_PERIOD) return true;
      node = node.target;
    } else if (node is MethodInvocation) {
      if (node.operator?.type == TokenType.QUESTION_PERIOD) return true;
      node = node.target;
    } else if (node is IndexExpression) {
      if (node.question != null) return true;
      node = node.target;
    } else if (node is PostfixExpression &&
        node.operator.type == TokenType.BANG) {
      node = node.operand;
    } else if (node is AnonymousMethodInvocation) {
      if (node.isNullAware) return true;
      node = node.target;
    } else if (node is FunctionExpressionInvocation) {
      node = node.function;
    } else {
      return false;
    }
  }
  return false;
}

/// Whether [e] is an `?.`-guarded selector: a `?.`/`?[` access, or an
/// ordinary member access (`a.b`, `a[i]`, `a.m()`) whose own receiver sits
/// on a null-shorted chain (`a?.b.c` nulls the `.c` too).
bool isNullShortedSelector(Expression e) => switch (e) {
  IndexExpression() => e.question != null || isNullShorted(e.target),
  PropertyAccess() =>
    e.operator.type == TokenType.QUESTION_PERIOD || isNullShorted(e.target),
  MethodInvocation() =>
    e.operator?.type == TokenType.QUESTION_PERIOD || isNullShorted(e.target),
  _ => false,
};

/// Emits `target == null ? null : body(target)` — the shared shape of every
/// null-aware selector (`?.`, `?[`, `!` on a shorted chain, and continuations
/// like `.c` in `a?.b.c`). When [target] is statically known-null the branch
/// is skipped entirely.
Variable emitNullGuard(
  CompilerContext ctx,
  Variable target,
  Variable Function(Variable target) body, {
  AstNode? source,
  // `x?.m()` narrows `x` itself inside the guard; a chain continuation
  // (`x?.y.m()`) instead guards on the *result* of `x?.y`, whose declared
  // member type (`x.y`'s, which may be nullable) the selector still sees.
  bool narrow = true,
}) {
  var out = BuiltinValue().push(ctx).boxIfNeeded(ctx);
  // A `Null`-typed target is statically always null — the branch is dead.
  // (concreteTypes isn't consulted: `[null]` also propagates onto copies
  // that have since been reassigned.)
  if (target.type.isSpec(CoreTypes.nullType)) {
    return out;
  }
  macroBranch(
    ctx,
    null,
    // `x?.y` with a statically non-nullable `x` never takes the null path;
    // that edge still compiles but contributes nothing to the flow join.
    elseEdgeUnreachable: () =>
        ctx.soundFlowAnalysis(source) && !target.type.hasNullableRepresentation,
    condition: (ctx) => compileNonNullCondition(ctx, target),
    thenBranch: (ctx, rt) {
      // The receiver is provably non-null here: promote it so member and
      // extension resolution (`c1n?.ext` on `extension on C1`) see the
      // non-nullable view.
      final V = body(
        narrow
            ? target.copyWith(type: target.type.withNullable(false))
            : target,
      ).boxIfNeeded(ctx);
      // `x?.m` can yield null only when `x` itself can be null — on a
      // statically non-nullable receiver the result is `m`'s own type, which
      // also lets a chained `?.` see its null edge is statically dead.
      final canBeNull = target.type.hasNullableRepresentation;
      out = out.copyWith(
        type: canBeNull ? V.type.withNullable(true) : V.type,
        possibleClasses: {
          ...V.concreteTypes,
          if (canBeNull) CoreTypes.nullType.ref(ctx),
        }.toList(),
      );
      ctx.pushOp(Assign(out.ssa, V.ssa));
      return StatementInfo();
    },
    source: source,
  );
  return out;
}
