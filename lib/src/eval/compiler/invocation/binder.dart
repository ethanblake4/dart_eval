import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import 'bound_call.dart';
import 'call.dart';
import 'targets.dart';

/// Maps a [CallSite]'s argument shape onto a [CallTarget]'s signature:
/// match, seed the substitution, compile and coerce, solve inference, fill
/// omitted arguments per the target's [BindingPolicy].
final class ArgumentBinder {
  const ArgumentBinder(this.ctx);

  final CompilerContext ctx;

  /// `calleeBinds` — supplied arguments only. Every unboxed argument is
  /// snapshotted into a fresh slot so boxing never rewrites the SSA an
  /// unboxed local still uses.
  BoundCall bindSuppliedOnly(
    CallTarget target,
    CallSite site, {
    required Variable? callee,
    BindingOptions options = BindingOptions.legacy,
  }) {
    Variable snapshot(Variable argument) => argument.boxed
        ? argument
        : Variable.ssa(
            ctx,
            Assign(ctx.svar('closure_argument'), argument.ssa),
            argument.type,
          ).boxIfNeeded(ctx);

    final positional = List<BoundArgument?>.filled(
      site.shape.positional.length,
      null,
    );
    final named = List<(String, BoundArgument)?>.filled(
      site.shape.named.length,
      null,
    );
    // Arguments evaluate in source order — the interleave matters.
    for (final i in site.shape.sourceOrder) {
      if (i >= 0) {
        positional[i] = BoundArgument(
          snapshot(_compileArg(ctx, site.shape.positional[i])),
        );
      } else {
        final (name, source) = site.shape.named[-1 - i];
        named[-1 - i] = (name, BoundArgument(snapshot(_compileArg(ctx, source))));
      }
    }
    final positionalArgs = positional.cast<BoundArgument>();
    final namedArgs = named.cast<(String, BoundArgument)>();

    final runtimeTypeArguments =
        site.shape.typeArguments
            ?.map((type) => TypeRef.fromAnnotation(ctx, ctx.library, type))
            .map((type) => ctx.runtimeTypes.idOf(type))
            .toList() ??
        const <int>[];

    final dispatch = target is ClosureCall ? target.known : null;
    final argTypes = [for (final a in positionalArgs) a.value.type];
    final namedArgTypes = {
      for (final e in namedArgs) e.$1: e.$2.value.type,
    };
    final resultType =
        resolveCallResultType(
          ctx,
          callee: callee,
          dispatch: dispatch,
          argTypes: argTypes,
          namedArgTypes: namedArgTypes,
        ) ??
        CoreTypes.dynamic.ref(ctx);
    return BoundCall(
      positional: positionalArgs,
      named: namedArgs,
      runtimeTypeArguments: runtimeTypeArguments,
      returnType: resultType,
      trusted: _closureArgumentsProven(
        ctx,
        callee?.type,
        [for (final a in positionalArgs) a.value],
        {for (final e in namedArgs) e.$1: e.$2.value},
      ),
    );
  }

  Variable _compileArg(CompilerContext ctx, ArgSource source) {
    return switch (source) {
      ExpressionArg(:final expression) => compileExpression(expression, ctx),
      ValueArg(:final value) => value,
      ForwardedLocal(:final localName) =>
        ctx.lookupBinding(localName)?.read(ctx) ??
            (throw StateError('missing forwarded local $localName')),
    };
  }
}

/// Resolves the result type of calling a function-typed value with the
/// given argument types, or null when it can't be determined.
///
/// A statically dispatched [dispatch] signature wins over the [callee]'s
/// own callable metadata (tear-off `methodReturnType`), and both win over
/// the callee's declared function type. A resolved `void` result is
/// unusable as a value, so null is returned and callers fall back to
/// dynamic — preserving the permissive semantics of consuming the runtime
/// result anyway.
TypeRef? resolveCallResultType(
  CompilerContext ctx, {
  required Variable? callee,
  required DirectCall? dispatch,
  required List<TypeRef> argTypes,
  required Map<String, TypeRef> namedArgTypes,
}) {
  final voidType = CoreTypes.voidType.ref(ctx);
  final signature = dispatch?.returnType ?? callee?.methodReturnType;
  if (signature != null) {
    final resolved = signature.toAlwaysReturnType(
      ctx,
      dispatch == null ? callee?.type : null,
      argTypes,
      namedArgTypes,
    );
    if (resolved != null && resolved.type != voidType) return resolved.type;
  }
  final calleeType = callee?.type;
  final declared =
      calleeType is FunctionTypeRef ? calleeType.signature.returnType : null;
  return declared == voidType ? null : declared;
}

/// Whether the runtime can skip per-argument checks for a closure
/// invocation: every supplied argument provably assignable to the closure's
/// static signature without a runtime check.
bool _closureArgumentsProven(
  CompilerContext ctx,
  TypeRef? closureType,
  List<Variable> positionalArgs,
  Map<String, Variable> namedArgs,
) {
  if (closureType is! FunctionTypeRef) return false;
  final signature = closureType.signature;
  final positional = signature.positional;
  for (var i = 0; i < positionalArgs.length; i++) {
    if (i >= positional.length) return false;
    final paramType = positional[i];
    if (paramType.isSpec(CoreTypes.dynamic) ||
        positionalArgs[i].type.assignmentConversionTo(ctx, paramType) !=
            AssignmentConversion.none) {
      return false;
    }
  }
  for (final entry in namedArgs.entries) {
    final parameter = signature.named[entry.key];
    if (parameter == null ||
        parameter.type.isSpec(CoreTypes.dynamic) ||
        entry.value.type.assignmentConversionTo(ctx, parameter.type) !=
            AssignmentConversion.none) {
      return false;
    }
  }
  return true;
}
