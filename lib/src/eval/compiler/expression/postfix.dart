import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/null_aware.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import '../invocation/resolver.dart';
import 'index.dart';

Variable compilePostfixExpression(
  PostfixExpression e,
  CompilerContext ctx, [
  TypeRef? bound,
]) {
  Variable assertNonNull(Variable v) {
    if (v.type.hasNullableRepresentation) {
      final boxed = v.boxIfNeeded(ctx, e.operand);
      ctx.pushOp(
        AssertType(boxed.ssa, ctx.runtimeTypes.idOf(CoreTypes.object.ref(ctx))),
      );
    }
    return v.copyWith(
      type: v.type.isSpec(CoreTypes.nullType)
          ? CoreTypes.never.ref(ctx)
          : v.type.withNullable(false),
    );
  }

  if (e.operator.type == TokenType.BANG) {
    // Null assertion (!). On a null-shorted operand (`a?.b!`) the `!`
    // participates in shorting: `a?.b!` is `a == null ? null : (a.b)!` —
    // the assertion applies to `a.b` inside the non-null branch, not to the
    // chain's result (a null `a.b` throws, it does not yield null).
    final operand = e.operand;
    switch (operand) {
      case PropertyAccess pa when isNullShortedSelector(pa):
        final receiver = pa.isCascaded
            ? ValueReceiver(ctx.cascadeTarget!)
            : compileReceiver(ctx, pa.realTarget);
        return emitNullGuard(
          ctx,
          receiver.value!,
          (t) {
            final result = assertNonNull(
              IdentifierReference.receiver(
                receiver.withValue(t),
                pa.propertyName.name,
              ).getValue(ctx, pa, bound),
            );
            promoteNonNull(ctx, pa);
            return result;
          },
          source: e,
          narrow: pa.operator.type == TokenType.QUESTION_PERIOD,
        );
      case IndexExpression ie when isNullShortedSelector(ie):
        final target = ie.isCascaded
            ? ctx.cascadeTarget!
            : compileExpression(ie.realTarget, ctx);
        return emitNullGuard(
          ctx,
          target,
          (t) => assertNonNull(
            compileIndexReference(ie, ctx, t).getValue(ctx, ie),
          ),
          source: e,
        );
      case MethodInvocation mi
          when isNullShortedSelector(mi) && mi.target != null:
        final receiver = compileReceiver(ctx, mi.target!);
        if (receiver.value case final target?) {
          return emitNullGuard(
            ctx,
            target,
            (t) => assertNonNull(
              CallResolver(ctx).invokeMethod(
                t,
                mi,
                bound: bound,
                receiver: receiver.withValue(t),
              ),
            ),
            source: e,
            narrow: mi.operator?.type == TokenType.QUESTION_PERIOD,
          );
        }
    }
    final L = compileExpression(operand, ctx, bound);
    if (isNullShorted(operand)) {
      return emitNullGuard(ctx, L, assertNonNull, source: e);
    }
    // `x!` on a statically-`Null` operand always throws; on a `Never`
    // operand it never runs — either way nothing follows.
    final result = assertNonNull(L);
    if (L.type.isSpec(CoreTypes.nullType) || L.type.isSpec(CoreTypes.never)) {
      markNeverTerminates(ctx);
    }
    promoteNonNull(ctx, operand);
    return result;
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
      (t) =>
          _postfixOnReference(e, ctx, compileIndexReference(operand, ctx, t)),
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
  final out = L.copyIntoFreshSlot(ctx, 'operand');

  const opMap = {TokenType.PLUS_PLUS: '+', TokenType.MINUS_MINUS: '-'};

  if (!opMap.containsKey(e.operator.type)) {
    throw UnsupportedError('Unsupported postfix operator ${e.operator}');
  }

  V.setValue(
    ctx,
    CallResolver(ctx).invokeOperator(L, opMap[e.operator.type]!, [
      BuiltinValue(intval: 1).push(ctx),
    ]).result,
  );

  return out;
}
