import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/null_aware.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

Variable compilePostfixExpression(PostfixExpression e, CompilerContext ctx) {
  Variable assertNonNull(Variable v) {
    if (v.type.nullable ||
        v.type.resolveTypeChain(ctx) == CoreTypes.dynamic.ref(ctx)) {
      final boxed = v.boxIfNeeded(ctx, e.operand);
      ctx.pushOp(
        AssertType(boxed.ssa, CoreTypes.object.ref(ctx).runtimeTypeId(ctx)),
      );
    }
    return v.copyWith(type: v.type.copyWith(nullable: false));
  }

  if (e.operator.type == TokenType.BANG) {
    // Null assertion (!). On a null-shorted operand (`a?.b!`) the `!` runs
    // only when the receiver is non-null — the whole expression is null
    // otherwise.
    final operand = e.operand;
    final L = compileExpression(operand, ctx);
    if (isNullShorted(operand)) {
      return emitNullGuard(ctx, L, assertNonNull, source: e);
    }
    return assertNonNull(L);
  }

  // `e1?[e2]++`, `a?.b++`: a null target nulls the whole expression; the
  // index, increment, and store are all skipped.
  final operand = e.operand;
  if (operand is IndexExpression && isNullShortedSelector(operand)) {
    final target = operand.isCascaded
        ? ctx.cascadeTarget!
        : compileExpression(operand.realTarget, ctx);
    return emitNullGuard(
      ctx,
      target,
      (t) => _postfixOnReference(
        e,
        ctx,
        IndexedReference(t, compileExpression(operand.index, ctx)),
      ),
      source: e,
    );
  }
  if (operand is PropertyAccess && isNullShortedSelector(operand)) {
    final target = operand.isCascaded
        ? ctx.cascadeTarget!
        : compileExpression(operand.realTarget, ctx);
    return emitNullGuard(
      ctx,
      target,
      (t) => _postfixOnReference(
        e,
        ctx,
        IdentifierReference(t, operand.propertyName.name),
      ),
      source: e,
    );
  }
  final V = compileExpressionAsReference(e.operand, ctx);
  return _postfixOnReference(e, ctx, V);
}

Variable _postfixOnReference(
  PostfixExpression e,
  CompilerContext ctx,
  Reference V,
) {
  final L = V.getValue(ctx);
  final out = Variable.ssa(ctx, Assign(ctx.svar('operand'), L.ssa), L.type);

  const opMap = {TokenType.PLUS_PLUS: '+', TokenType.MINUS_MINUS: '-'};

  if (!opMap.containsKey(e.operator.type)) {
    throw UnsupportedError('Unsupported postfix operator ${e.operator}');
  }

  V.setValue(
    ctx,
    L.invoke(ctx, opMap[e.operator.type]!, [
      BuiltinValue(intval: 1).push(ctx),
    ]).result,
  );

  return out;
}
