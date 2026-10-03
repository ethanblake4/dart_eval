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
import '../helpers/promotion.dart';

StatementInfo compileYield(
  CompilerContext ctx,
  YieldStatement statement,
  TypeRef? expectedReturnType,
) {
  AstNode? node = statement.parent;
  while (node != null && node is! FunctionBody) {
    node = node.parent;
  }
  if (node is! FunctionBody || !node.isGenerator) {
    throw CompileError(
      'yield requires a generator body',
      statement,
      ctx.library,
      ctx,
    );
  }

  final container = node.isAsynchronous ? CoreTypes.stream : CoreTypes.iterable;
  final elementType = _generatorElementType(ctx, expectedReturnType, container);
  final delegated = statement.star != null;
  final expectedType = delegated
      ? container.ref(ctx).copyWith(arguments: [elementType])
      : elementType;
  // `yield*` has no downward context when the generator's return context
  // is dynamic or its element context is still unknown.
  final yieldContext =
      delegated &&
          (expectedReturnType == null ||
              expectedReturnType.isSpec(CoreTypes.dynamic) ||
              expectedReturnType.hasSchemaHoles ||
              expectedReturnType.hasInferenceVariables)
      ? null
      : expectedType;
  final value = compileExpression(statement.expression, ctx, yieldContext);
  if (value.type.isSpec(CoreTypes.never)) return markNeverTerminates(ctx);

  if (node.parent is FunctionExpression &&
      ctx.asyncClosureReturnTypes.isNotEmpty) {
    ctx.asyncClosureReturnTypes.last.add(
      delegated
          ? _generatorElementType(ctx, value.type, container)
          : value.type,
    );
  }
  final boxed = convertForAssignment(
    ctx,
    value,
    ctx.typeSystem.closeSchemaHoles(expectedType),
    source: statement.expression,
    description: 'Cannot yield ${value.type} (expected: $expectedType)',
  ).boxIfNeeded(ctx);
  if (delegated && !node.isAsynchronous) {
    final iterator = GetTarget.read(ctx, boxed, 'iterator').copyWith(
      type: CoreTypes.iterator.ref(ctx).copyWith(arguments: [elementType]),
    );
    ctx.pushOp(YieldGenerator(iterator.ssa, delegate: true));
    demoteAfterSuspension(ctx, statement);
    return StatementInfo();
  }
  ctx.pushOp(
    YieldGenerator(
      boxed.ssa,
      delegate: delegated,
      asynchronous: node.isAsynchronous,
    ),
  );
  demoteAfterSuspension(ctx, statement);
  return StatementInfo();
}

TypeRef _generatorElementType(
  CompilerContext ctx,
  TypeRef? type,
  BridgeTypeSpec container,
) {
  final iterable = type == null
      ? null
      : ctx.typeSystem.asInstanceOf(type, ctx.types.bySpec(container));
  final arguments = iterable == null
      ? const <TypeRef>[]
      : interfaceArgumentsOf(iterable);
  return arguments.isEmpty ? CoreTypes.dynamic.ref(ctx) : arguments.first;
}
