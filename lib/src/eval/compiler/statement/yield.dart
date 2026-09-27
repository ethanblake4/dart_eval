import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/generators.dart';
import '../invocation/accessors.dart';

StatementInfo compileYield(
  CompilerContext ctx,
  YieldStatement statement,
  TypeRef? expectedReturnType,
) {
  AstNode? node = statement.parent;
  while (node != null && node is! FunctionBody) {
    node = node.parent;
  }
  if (node is! FunctionBody || !node.isGenerator || node.isAsynchronous) {
    throw CompileError(
      'yield requires a sync* body',
      statement,
      ctx.library,
      ctx,
    );
  }

  final iterable = expectedReturnType == null
      ? null
      : ctx.typeSystem.asInstanceOf(
          expectedReturnType,
          ctx.types.bySpec(CoreTypes.iterable),
        );
  final arguments = iterable == null
      ? const <TypeRef>[]
      : interfaceArgumentsOf(iterable);
  final elementType = arguments.isEmpty
      ? CoreTypes.dynamic.ref(ctx)
      : arguments.first;
  final delegated = statement.star != null;
  final expectedType = delegated
      ? CoreTypes.iterable.ref(ctx).copyWith(arguments: [elementType])
      : elementType;
  final value = compileExpression(statement.expression, ctx, expectedType);
  if (value.type.isSpec(CoreTypes.never)) return markNeverTerminates(ctx);

  if (node.parent is FunctionExpression &&
      ctx.asyncClosureReturnTypes.isNotEmpty) {
    final yieldedIterable = delegated
        ? ctx.typeSystem.asInstanceOf(
            value.type,
            ctx.types.bySpec(CoreTypes.iterable),
          )
        : null;
    ctx.asyncClosureReturnTypes.last.add(
      delegated
          ? (yieldedIterable == null ||
                    interfaceArgumentsOf(yieldedIterable).isEmpty
                ? CoreTypes.dynamic.ref(ctx)
                : interfaceArgumentsOf(yieldedIterable).first)
          : value.type,
    );
  }
  final boxed = convertForAssignment(
    ctx,
    value,
    expectedType,
    source: statement.expression,
    description: 'Cannot yield ${value.type} (expected: $expectedType)',
  ).boxIfNeeded(ctx);
  if (delegated) {
    final iterator = GetTarget.read(ctx, boxed, 'iterator').copyWith(
      type: CoreTypes.iterator.ref(ctx).copyWith(arguments: [elementType]),
    );
    ctx.pushOp(YieldSync(iterator.ssa, delegate: true));
    return StatementInfo();
  }
  ctx.pushOp(YieldSync(boxed.ssa));
  return StatementInfo();
}
