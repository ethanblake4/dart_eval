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

StatementInfo compileYield(
  CompilerContext ctx,
  YieldStatement statement,
  TypeRef? expectedReturnType,
) {
  if (statement.star != null) {
    throw CompileError('yield* is not supported', statement, ctx.library, ctx);
  }
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
  final value = compileExpression(statement.expression, ctx, elementType);
  if (value.type.isSpec(CoreTypes.never)) return markNeverTerminates(ctx);

  if (node.parent is FunctionExpression &&
      ctx.asyncClosureReturnTypes.isNotEmpty) {
    ctx.asyncClosureReturnTypes.last.add(value.type);
  }
  final boxed = convertForAssignment(
    ctx,
    value,
    elementType,
    source: statement.expression,
    description: 'Cannot yield ${value.type} (expected: $elementType)',
  ).boxIfNeeded(ctx);
  ctx.pushOp(YieldSync(boxed.ssa));
  return StatementInfo();
}
