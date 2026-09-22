import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/dot_shorthand.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/null_aware.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';


Variable compilePropertyAccess(
  PropertyAccess pa,
  CompilerContext ctx, [
  TypeRef? bound,
]) {
  // A cascaded selector (`..x`) reads its receiver from the ambient cascade
  // target; its own `target` is null.
  final L = pa.isCascaded
      ? ctx.cascadeTarget!
      : compileExpression(
          pa.realTarget,
          ctx,
          // `.member.rest` — the chain's context type reaches the leading
          // shorthand through its selector targets.
          containsLeadingShorthand(pa.realTarget) ? bound : null,
        );
  if (pa.realTarget is SuperExpression) {
    return SuperPropertyReference(L, pa.propertyName.name).getValue(ctx, pa);
  }

  // `a?.b` and selectors continuing a null-shorted chain (`a?.b.c`): a null
  // receiver nulls the whole expression.
  if (isNullShortedSelector(pa)) {
    return emitNullGuard(
      ctx,
      L,
      (t) => t.getProperty(ctx, pa.propertyName.name),
      source: pa,
    );
  }

  // `p.C.member` parses as PropertyAccess over the class identifier — static
  // member access lives in IdentifierReference, same as MethodInvocation.
  if (L.type == CoreTypes.type.ref(ctx) && L.concreteTypes.length == 1) {
    return IdentifierReference(L, pa.propertyName.name).getValue(ctx, pa);
  }

  return L.getProperty(ctx, pa.propertyName.name);
}

Reference compilePropertyAccessAsReference(
  PropertyAccess pa,
  CompilerContext ctx,
) {
  final L = pa.isCascaded
      ? ctx.cascadeTarget!
      : compileExpression(pa.realTarget, ctx);
  if (pa.realTarget is SuperExpression) {
    return SuperPropertyReference(L, pa.propertyName.name);
  }
  return IdentifierReference(L, pa.propertyName.name);
}
