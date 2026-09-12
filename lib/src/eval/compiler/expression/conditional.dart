import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

import '../errors.dart';
import 'expression.dart';

/// Compile a [ConditionalExpression] to EVC bytecode
Variable compileConditionalExpression(
  CompilerContext ctx,
  ConditionalExpression e, [
  TypeRef? boundType,
]) {
  final output = BuiltinValue().push(ctx).boxIfNeeded(ctx);
  final types = <TypeRef>{?boundType};

  macroBranch(
    ctx,
    boundType == null ? null : AlwaysReturnType(boundType, false),
    condition: (ctx) {
      var c = compileExpression(e.condition, ctx);
      if (!c.type.isAssignableTo(ctx, CoreTypes.bool.ref(ctx))) {
        throw CompileError('Condition must be a boolean');
      }

      return c;
    },
    thenBranch: (ctx, rt) {
      final v = compileExpression(e.thenExpression, ctx, boundType);
      types.add(v.type);
      ctx.pushOp(Assign(output.ssa, v.boxIfNeeded(ctx).ssa));
      return StatementInfo(-1);
    },
    elseBranch: (ctx, rt) {
      final v = compileExpression(e.elseExpression, ctx, boundType);
      types.add(v.type);
      ctx.pushOp(Assign(output.ssa, v.boxIfNeeded(ctx).ssa));
      return StatementInfo(-1);
    },
    resolveStateToThen: true,
    source: e,
  );

  return output.copyWith(
    type: TypeRef.commonBaseType(ctx, types).copyWith(boxed: true),
  );
}
