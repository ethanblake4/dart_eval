// ignore_for_file: experimental_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

/// Whether a cascade section's operator is `?..` (null-aware). Only the first
/// section of a cascade may carry it — `a?..b..c` short-circuits them all.
bool _isNullAwareSection(Expression section) {
  return switch (section) {
    MethodInvocation m => m.isCascaded && m.isNullAware,
    PropertyAccess p => p.isCascaded && p.isNullAware,
    IndexExpression i => i.isCascaded && i.isNullAware,
    AnonymousMethodInvocation a => a.isCascaded && a.isNullAware,
    AssignmentExpression a => _isNullAwareSection(a.leftHandSide),
    _ => false,
  };
}

Variable compileCascadeExpression(
  CascadeExpression e,
  CompilerContext ctx,
  TypeRef? bound,
) {
  // A cascade evaluates to its target, so the context type flows into it.
  final target = compileExpression(e.target, ctx, bound).boxIfNeeded(ctx);

  void compileSections() {
    for (final s in e.cascadeSections) {
      if (s is MethodInvocation) {
        compileMethodInvocation(ctx, s, cascadeTarget: target);
      } else {
        compileExpressionAndDiscardResult(s, ctx, cascadeTarget: target);
      }
    }
  }

  if (e.cascadeSections.isNotEmpty &&
      _isNullAwareSection(e.cascadeSections.first)) {
    // `target?..section` — a null target skips every section.
    macroBranch(
      ctx,
      null,
      condition: (ctx) => compileNonNullCondition(ctx, target),
      thenBranch: (ctx, _) {
        compileSections();
        return StatementInfo();
      },
      source: e,
    );
  } else {
    compileSections();
  }
  return target;
}
