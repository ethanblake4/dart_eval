import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'binder.dart';
import 'bound_call.dart';
import 'call.dart';
import 'targets.dart';

/// Turns a [CallSite] into a [CallTarget] and emits the call. Resolution
/// consults only the receiver's static type and facts plus the syntactic
/// shape; arguments are compiled by the [ArgumentBinder].
final class CallResolver {
  const CallResolver(this.ctx);

  final CompilerContext ctx;

  /// `value(args)` — a function-expression invocation. When [ref] is given
  /// a statically-known target short-circuits to a direct [Call] without
  /// materializing the callee.
  Variable invokeValue(
    CallSite site, {
    Reference? ref,
    Variable? callee,
  }) => invokeValueWithArgs(site, ref: ref, callee: callee).$1;

  /// [invokeValue] plus the bound call — callers needing the post-coercion
  /// argument values read them from the [BoundCall].
  (Variable, BoundCall) invokeValueWithArgs(
    CallSite site, {
    Reference? ref,
    Variable? callee,
  }) {
    final dispatch = ref?.getStaticDispatch(ctx, site.source);
    final callable = dispatch == null
        ? (ref?.getValue(ctx, site.source) ?? callee!)
        : null;
    final target = ClosureCall(callee: callable, known: dispatch);
    final bound = ArgumentBinder(
      ctx,
    ).bindSuppliedOnly(target, site, callee: callable);
    return (_emitValue(target, bound, callable, site), bound);
  }

  Variable _emitValue(
    ClosureCall target,
    BoundCall bound,
    Variable? callable,
    CallSite site,
  ) {
    if (target.known != null) {
      return target.emit(ctx, bound);
    }
    final callableVar = callable!;
    // `x(...)` where `x` isn't a function is an implicit `x.call(...)` — an
    // extension `call` member applies statically before the dynamic
    // fallback.
    if (!callableVar.type.isAssignableTo(ctx, CoreTypes.function.ref(ctx))) {
      if (!hasInstanceMethod(ctx, callableVar.type, 'call') &&
          resolveExtensionMember(
                ctx,
                callableVar.type,
                'call',
                arity: bound.positional.length,
              ) !=
              null) {
        return callableVar
            .invoke(
              ctx,
              'call',
              [for (final a in bound.positional) a.value],
              namedArgs: {for (final e in bound.named) e.$1: e.$2.value},
            )
            .result;
      }
    }
    return target.emit(ctx, bound);
  }
}
