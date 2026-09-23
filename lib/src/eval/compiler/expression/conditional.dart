import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

import 'expression.dart';

/// Compile a [ConditionalExpression] to EVC bytecode
Variable compileConditionalExpression(
  CompilerContext ctx,
  ConditionalExpression e, [
  TypeRef? boundType,
]) {
  final output = BuiltinValue().push(ctx).boxIfNeeded(ctx);
  // The bound constrains the branches but never joins the result type:
  // `t ? c : c` under `Function` is still `C` (the branches' join).
  final types = <TypeRef>{};

  macroBranch(
    ctx,
    boundType == null ? null : AlwaysReturnType(boundType, false),
    conditionExpression: e.condition,
    thenBranch: (ctx, rt) {
      final v = compileExpression(e.thenExpression, ctx, boundType);
      types.add(v.type);
      // Box into a fresh slot: boxing in place would re-version the source
      // variable with an object representation, leaving the outer phi that
      // merges it across scopes with mixed representations.
      ctx.pushOp(Assign(output.ssa, v.boxIntoFreshSlot(ctx).ssa));
      return StatementInfo();
    },
    elseBranch: (ctx, rt) {
      final v = compileExpression(e.elseExpression, ctx, boundType);
      types.add(v.type);
      ctx.pushOp(Assign(output.ssa, v.boxIntoFreshSlot(ctx).ssa));
      return StatementInfo();
    },
    resolveStateToThen: true,
    source: e,
  );

  return output.copyWith(
    type: TypeRef.commonBaseType(ctx, types),
  );
}
