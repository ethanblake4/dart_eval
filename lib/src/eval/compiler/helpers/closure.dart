import '../../ir/memory.dart' show Assign;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
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
  final closure = callable == null
      ? null
      : Variable.ssa(
          ctx,
          Assign(ctx.svar('closure_target'), callable.ssa),
          callable.type,
        );
  Variable snapshot(Variable argument) => Variable.ssa(
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
    ctx.pushOp(
      InvokeClosure(
        target,
        closure!.ssa,
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
  final argTypes = positionalArgs.map((arg) => arg.type).toList();
  final namedArgTypes = namedArgs.map((key, arg) => MapEntry(key, arg.type));
  // Prefer the statically dispatched callee's signature, then the closure's
  // own callable metadata (tear-off or function-typed expression).
  final resultType =
      (dispatch != null
          ? dispatch.returnType
                .toAlwaysReturnType(ctx, null, argTypes, namedArgTypes)
                ?.type
          : callable!.methodReturnType
                    ?.toAlwaysReturnType(
                      ctx,
                      callable.type,
                      argTypes,
                      namedArgTypes,
                    )
                    ?.type ??
                callable.type
                    .resolveTypeChain(ctx)
                    .functionType
                    ?.returnType
                    .type) ??
      CoreTypes.dynamic.ref(ctx);
  // A 'void' signature is unusable as a value; dynamic keeps the permissive
  // semantics of consuming the runtime result anyway.
  final typedResult = resultType == CoreTypes.voidType.ref(ctx)
      ? CoreTypes.dynamic.ref(ctx)
      : resultType;
  return InvokeResult(
    null,
    Variable.of(ctx, target, typedResult.copyWith(boxed: true)),
    positionalArgs,
    namedArgs: namedArgs,
  );
}

/// Whether the runtime can skip per-argument checks for a closure invocation:
/// true when the closure's static signature is known and every supplied
/// argument is provably assignable without a runtime check. Runtime closures
/// assignable to the static type have parameter types that are supertypes of
/// the static signature's parameters, so a statically-safe argument always
/// satisfies them.
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
        entry.value.type
                .resolveTypeChain(ctx)
                .assignmentConversionTo(ctx, paramType) !=
            AssignmentConversion.none) {
      return false;
    }
  }
  return true;
}
