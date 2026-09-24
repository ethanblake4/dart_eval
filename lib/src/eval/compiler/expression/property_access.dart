import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/dot_shorthand.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/null_aware.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import '../invocation/accessors.dart';

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
      (t) => GetTarget.read(ctx, t, pa.propertyName.name),
      source: pa,
    );
  }

  // `p.C.member` parses as PropertyAccess over the class identifier — static
  // member access lives in IdentifierReference, same as MethodInvocation.
  final pin = extensionPinOf(ctx, pa.realTarget, L.type);
  if (receiverOf(ctx, L, pin: pin) is TypeLiteralReceiver) {
    return IdentifierReference(
      L,
      pa.propertyName.name,
      pin: pin,
    ).getValue(ctx, pa);
  }

  return GetTarget.read(ctx, L, pa.propertyName.name, extensionPin: pin);
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
  return IdentifierReference(
    L,
    pa.propertyName.name,
    pin: extensionPinOf(ctx, pa.realTarget, L.type),
  );
}
