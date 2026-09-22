// ignore_for_file: experimental_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
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

/// Emits `target == null ? null : body(target)` — the shared shape of every
/// null-aware selector (`?.`, `?[`, `!` on a shorted chain, and continuations
/// like `.c` in `a?.b.c`). When [target] is statically known-null the branch
/// is skipped entirely.
Variable emitNullGuard(
  CompilerContext ctx,
  Variable target,
  Variable Function(Variable target) body, {
  AstNode? source,
}) {
  var out = BuiltinValue().push(ctx).boxIfNeeded(ctx);
  // A `Null`-typed target is statically always null — the branch is dead.
  // (concreteTypes isn't consulted: `[null]` also propagates onto copies
  // that have since been reassigned.)
  if (target.type == CoreTypes.nullType.ref(ctx)) {
    return out;
  }
  macroBranch(
    ctx,
    null,
    condition: (ctx) => compileNonNullCondition(ctx, target),
    thenBranch: (ctx, rt) {
      // The receiver is provably non-null here: promote it so member and
      // extension resolution (`c1n?.ext` on `extension on C1`) see the
      // non-nullable view.
      final V = body(
        target.copyWith(type: target.type.copyWith(nullable: false)),
      ).boxIfNeeded(ctx);
      out = out.copyWith(
        type: V.type.copyWith(nullable: true),
        concreteTypes: {
          ...V.concreteTypes,
          CoreTypes.nullType.ref(ctx),
        }.toList(),
      );
      ctx.pushOp(Assign(out.ssa, V.ssa));
      return StatementInfo();
    },
    source: source,
  );
  return out;
}
