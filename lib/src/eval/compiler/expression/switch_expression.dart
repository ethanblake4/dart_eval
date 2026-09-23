import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/assert.dart';
import 'package:dart_eval/src/eval/compiler/helpers/pattern.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import '../values/value_rep.dart';
import '../invocation/resolver.dart';

/// Compiles a `switch (e) { pattern => expr, ... }` expression: evaluates the
/// subject once, pattern-matches each case in order, and assigns the winning
/// case's value to a single result slot.
Variable compileSwitchExpression(
  CompilerContext ctx,
  SwitchExpression e, [
  TypeRef? bound,
]) {
  final expression = compileExpression(e.expression, ctx);
  // Evaluate once. Each case copies the subject into its own slot so
  // pattern-matching can freely box/unbox that copy without constraining
  // the shared subject's representation.
  final switchExpr = expression.copyIntoFreshSlot(ctx, 'switch_value');

  final resultSsa = ctx.svar('switch_result');
  final resultTypes = <TypeRef>[];

  StatementInfo compileCases(List<SwitchExpressionCase> cases, int index) {
    if (index >= cases.length) {
      // Switch expressions must be exhaustive; reaching here means the
      // scrutinee slipped past static exhaustiveness checking.
      doAssert(
        ctx,
        BuiltinValue(boolval: false).push(ctx),
        BuiltinValue(stringval: 'non-exhaustive switch expression').push(ctx),
      );
      return StatementInfo(willAlwaysThrow: true);
    }
    final currentCase = cases[index];
    return macroBranch(
      ctx,
      null,
      condition: (ctx) {
        final subject = switchExpr.copyIntoFreshSlot(ctx, 'case_value');
        final matches = patternMatchAndBind(
          ctx,
          currentCase.guardedPattern.pattern,
          subject,
        );
        final guard = currentCase.guardedPattern.whenClause;
        if (guard != null) {
          final guardExpr = compileExpression(
            guard.expression,
            ctx,
            CoreTypes.bool.ref(ctx),
          );
          return CallResolver(ctx).invokeOperator(matches, '&&', [guardExpr]).result;
        }
        return matches;
      },
      thenBranch: (ctx, _) {
        // Box into a fresh slot so an unboxed local's SSA keeps its primitive
        // representation on paths where the arm doesn't run.
        final value = compileExpression(
          currentCase.expression,
          ctx,
          bound,
        ).boxIntoFreshSlot(ctx);
        resultTypes.add(value.type);
        ctx.pushOp(Assign(resultSsa, value.ssa));
        return StatementInfo();
      },
      elseBranch: (ctx, _) => compileCases(cases, index + 1),
      source: e,
    );
  }

  compileCases(e.cases, 0);

  final resultType = resultTypes.isEmpty
      ? CoreTypes.dynamic.ref(ctx)
      : resultTypes.length == 1
      ? resultTypes.first
      : TypeRef.commonBaseType(ctx, resultTypes.toSet());
  return Variable.of(ctx, resultSsa, resultType, rep: ValueRep.boxed);
}
