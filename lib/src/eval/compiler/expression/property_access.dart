import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/dot_shorthand.dart';
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
  final receiver = pa.isCascaded
      ? ValueReceiver(ctx.cascadeTarget!)
      : compileReceiver(
          ctx,
          pa.realTarget,
          // `.member.rest` — the chain's context type reaches the leading
          // shorthand through its selector targets.
          bound: containsLeadingShorthand(pa.realTarget) ? bound : null,
        );

  // `a?.b` and selectors continuing a null-shorted chain (`a?.b.c`): a null
  // receiver nulls the whole expression.
  if (isNullShortedSelector(pa)) {
    return emitNullGuard(
      ctx,
      receiver.value!,
      (t) => IdentifierReference.receiver(
        receiver.withValue(t),
        pa.propertyName.name,
      ).getValue(ctx, pa),
      source: pa,
    );
  }

  return IdentifierReference.receiver(
    receiver,
    pa.propertyName.name,
  ).getValue(ctx, pa);
}

Reference compilePropertyAccessAsReference(
  PropertyAccess pa,
  CompilerContext ctx,
) {
  final receiver = pa.isCascaded
      ? ValueReceiver(ctx.cascadeTarget!)
      : compileReceiver(ctx, pa.realTarget);
  return IdentifierReference.receiver(receiver, pa.propertyName.name);
}
