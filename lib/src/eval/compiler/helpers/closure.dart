import '../../ir/memory.dart' show Assign;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/closures.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

InvokeResult invokeClosure(
  CompilerContext ctx,
  Reference? closureRef,
  Variable? closureVar,
  ArgumentList? argumentList, {
  List<Variable>? positional,
  Map<String, Variable>? named,
  List<TypeAnnotation>? typeArguments,
}) {
  final dispatch = closureRef?.getStaticDispatch(ctx);
  final callable = dispatch == null
      ? (closureRef?.getValue(ctx) ?? closureVar!)
      : null;
  // The callable sits in object position at the call boundary — box
  // unboxed results into a fresh slot (e.g. `only()` where `only` is
  // an `int` getter); boxing in place would double-define the SSA.
  final callableBoxed = callable == null
      ? null
      : callable.boxed
      ? callable
      : callable.boxIntoFreshSlot(ctx);
  final closure = callableBoxed == null
      ? null
      : Variable.ssa(
          ctx,
          Assign(ctx.svar('closure_target'), callableBoxed.ssa),
          callableBoxed.type,
        );
  // Arguments bound to the call read from a fresh slot so boxing never
  // rewrites the SSA an unboxed local still uses; already-boxed values pass
  // straight through.
  Variable snapshot(Variable argument) => argument.boxed
      ? argument
      : Variable.ssa(
            ctx,
            Assign(ctx.svar('closure_argument'), argument.ssa),
            argument.type,
          ).boxIfNeeded(ctx);
  final positionalArgs = [
    for (final argument in positional ?? <Variable>[]) snapshot(argument),
  ];
  final namedArgs = {
    for (final entry in (named ?? <String, Variable>{}).entries)
      entry.key: snapshot(entry.value),
  };
  for (final arg in argumentList?.arguments ?? <Argument>[]) {
    if (arg is NamedArgument) {
      namedArgs[arg.name.lexeme] = snapshot(
        compileExpression(arg.argumentExpression, ctx),
      );
    } else {
      positionalArgs.add(
        snapshot(compileExpression(arg.argumentExpression, ctx)),
      );
    }
  }
  final target = ctx.svar('closure_result');
  final positionalSsa = positionalArgs.map((arg) => arg.ssa).toList();
  final namedSsa = namedArgs.map((key, arg) => MapEntry(key, arg.ssa));
  final runtimeTypeArguments =
      typeArguments
          ?.map((type) => TypeRef.fromAnnotation(ctx, ctx.library, type))
          .map((type) => type.runtimeTypeId(ctx))
          .toList() ??
      const <int>[];
  if (dispatch != null) {
    ctx.pushOp(
      Call(
        dispatch.offset,
        [...positionalSsa, ...namedSsa.values],
        result: target,
        typeArguments: runtimeTypeArguments,
      ),
    );
  } else {
    // `x(...)` where `x` isn't a function is an implicit `x.call(...)` — an
    // extension `call` member applies statically before the dynamic fallback.
    final callableVar = closure!;
    if (!callableVar.type.isAssignableTo(
      ctx,
      CoreTypes.function.ref(ctx),
    )) {
      if (!hasInstanceMethod(ctx, callableVar.type, 'call') &&
          resolveExtensionMember(
                ctx,
                callableVar.type,
                'call',
                arity: positionalArgs.length,
              ) !=
              null) {
        return callableVar.invoke(
          ctx,
          'call',
          positionalArgs,
          namedArgs: namedArgs,
        );
      }
    }
    ctx.pushOp(
      InvokeClosure(
        target,
        callableVar.ssa,
        positionalSsa,
        namedSsa,
        typeArguments: runtimeTypeArguments,
        trusted: _closureArgumentsProven(
          ctx,
          callable!.type,
          positionalArgs,
          namedArgs,
        ),
      ),
    );
  }
  final resultType =
      resolveCallResultType(
        ctx,
        callee: callable,
        dispatch: dispatch,
        argTypes: positionalArgs.map((arg) => arg.type).toList(),
        namedArgTypes: namedArgs.map((key, arg) => MapEntry(key, arg.type)),
      ) ??
      CoreTypes.dynamic.ref(ctx);
  return InvokeResult(
    null,
    Variable.of(ctx, target, resultType.copyWith(boxed: true)),
    positionalArgs,
    namedArgs: namedArgs,
  );
}

/// Resolves the result type of calling a function-typed value with the given
/// argument types, or null when it can't be determined.
///
/// A statically dispatched [dispatch] signature wins over the [callee]'s own
/// callable metadata (tear-off `methodReturnType`), and both win over the
/// callee's declared function type. A resolved 'void' result is unusable as a
/// value, so null is returned and callers fall back to dynamic — preserving
/// the permissive semantics of consuming the runtime result anyway.
TypeRef? resolveCallResultType(
  CompilerContext ctx, {
  required Variable? callee,
  required StaticDispatch? dispatch,
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
  final declared = callee?.type
      .resolveTypeChain(ctx)
      .functionType
      ?.returnType
      .type;
  return declared == voidType ? null : declared;
}

/// Whether the runtime can skip per-argument checks for a closure invocation:
/// true when the closure's static signature is known and every supplied
/// argument is provably assignable without a runtime check. Runtime closures
/// assignable to the static type have parameter types that are supertypes of
/// the static signature's parameters — except a `dynamic` parameter admits
/// narrower closures (`(int)->void` is assignable to `(dynamic)->void`), so
/// the callee's own parameter check must still run.
bool _closureArgumentsProven(
  CompilerContext ctx,
  TypeRef closureType,
  List<Variable> positionalArgs,
  Map<String, Variable> namedArgs,
) {
  final signature = closureType.resolveTypeChain(ctx).functionType;
  if (signature == null) return false;
  final positional = [
    ...signature.normalParameters,
    ...signature.optionalParameters,
  ];
  for (var i = 0; i < positionalArgs.length; i++) {
    if (i >= positional.length) return false;
    final paramType = positional[i].type.type;
    if (paramType == null ||
        paramType == CoreTypes.dynamic.ref(ctx) ||
        positionalArgs[i].type
                .resolveTypeChain(ctx)
                .assignmentConversionTo(ctx, paramType) !=
            AssignmentConversion.none) {
      return false;
    }
  }
  for (final entry in namedArgs.entries) {
    final paramType = signature.namedParameters[entry.key]?.type.type;
    if (paramType == null ||
        paramType == CoreTypes.dynamic.ref(ctx) ||
        entry.value.type
                .resolveTypeChain(ctx)
                .assignmentConversionTo(ctx, paramType) !=
            AssignmentConversion.none) {
      return false;
    }
  }
  return true;
}
