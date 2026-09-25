import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

import 'dot_shorthand.dart';
import '../reference.dart';
import 'null_aware.dart';
import '../invocation/call.dart';
import '../invocation/resolver.dart';

Variable compileMethodInvocation(
  CompilerContext ctx,
  MethodInvocation e, {
  TypeRef? bound,
}) {
  if (e.target is SuperExpression) {
    final folded = CallResolver(ctx).invokeLexicalSuper(
      CallSite(
        shape: CallShape.fromArgumentList(
          e.argumentList,
          e.typeArguments?.arguments,
        ),
        source: e,
        inConstContext: e.inConstantContext,
      ),
      bound: bound,
    );
    if (folded != null) return folded;
  }
  Receiver? receiver;
  if (e.isCascaded) {
    receiver = ValueReceiver(ctx.cascadeTarget!);
  } else if (e.target != null) {
    receiver = compileReceiver(
      ctx,
      e.target!,
      bound: containsLeadingShorthand(e.target!) ? bound : null,
    );
    if (receiver case SuperReceiver(:final self)) {
      final (owner, dispatched) = resolveSuperReceiver(ctx, e, self);
      if (dispatched != null) return dispatched;
      receiver = SuperReceiver(owner);
    }
  }

  if (receiver is ExtensionNamespaceReceiver) {
    return CallResolver(
      ctx,
    ).invokeExtensionNamespace(receiver, e, bound: bound);
  }
  final L = receiver?.value;
  if (L != null) {
    final compiledReceiver = receiver!;
    // `a?.m()` and calls continuing a null-shorted chain (`a?.b.m()`): a
    // null receiver nulls the whole expression — argument evaluation is
    // skipped.
    if (isNullShortedSelector(e)) {
      return emitNullGuard(
        ctx,
        L,
        (t) => CallResolver(ctx).invokeMethod(
          t,
          e,
          bound: bound,
          receiver: compiledReceiver.withValue(t),
        ),
        source: e,
      );
    }
    return CallResolver(
      ctx,
    ).invokeMethod(L, e, bound: bound, receiver: compiledReceiver);
  }
  return CallResolver(ctx).invokeBare(
    e.methodName.name,
    CallSite(
      shape: CallShape.fromArgumentList(
        e.argumentList,
        e.typeArguments?.arguments,
      ),
      source: e,
      inConstContext: e.inConstantContext,
    ),
    prefix: receiver is PrefixReceiver ? receiver.prefix.prefix : null,
    bound: bound,
  );
}
