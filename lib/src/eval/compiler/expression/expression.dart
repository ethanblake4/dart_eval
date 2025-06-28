import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/as.dart';
import 'package:dart_eval/src/eval/compiler/expression/assignment.dart';
import 'package:dart_eval/src/eval/compiler/expression/await.dart';
import 'package:dart_eval/src/eval/compiler/expression/binary.dart';
import 'package:dart_eval/src/eval/compiler/expression/cascade.dart';
import 'package:dart_eval/src/eval/compiler/expression/conditional.dart';
import 'package:dart_eval/src/eval/compiler/expression/funcexpr_invocation.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart';
import 'package:dart_eval/src/eval/compiler/expression/index.dart';
import 'package:dart_eval/src/eval/compiler/expression/instance_creation.dart';
import 'package:dart_eval/src/eval/compiler/expression/is.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/expression/keywords.dart';
import 'package:dart_eval/src/eval/compiler/expression/literal.dart';
import 'package:dart_eval/src/eval/compiler/expression/parenthesized.dart';
import 'package:dart_eval/src/eval/compiler/expression/pattern_assignment.dart';
import 'package:dart_eval/src/eval/compiler/expression/postfix.dart';
import 'package:dart_eval/src/eval/compiler/expression/prefix.dart';
import 'package:dart_eval/src/eval/compiler/expression/property_access.dart';
import 'package:dart_eval/src/eval/compiler/expression/rethrow.dart';
import 'package:dart_eval/src/eval/compiler/expression/throw.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileExpression(Expression e, CompilerContext ctx,
    [TypeRef? bound]) {
  if (e is Literal) {
    return parseLiteral(e, ctx, bound);
  } else if (e is AssignmentExpression) {
    return compileAssignmentExpression(e, ctx);
  } else if (e is Identifier) {
    return compileIdentifier(e, ctx);
  } else if (e is MethodInvocation) {
    return compileMethodInvocation(ctx, e, bound: bound);
  } else if (e is BinaryExpression) {
    return compileBinaryExpression(ctx, e, bound);
  } else if (e is PrefixExpression) {
    return compilePrefixExpression(ctx, e);
  } else if (e is PropertyAccess) {
    return compilePropertyAccess(e, ctx);
  } else if (e is ThisExpression) {
    return compileThisExpression(e, ctx);
  } else if (e is SuperExpression) {
    return compileSuperExpression(e, ctx);
  } else if (e is PostfixExpression) {
    return compilePostfixExpression(e, ctx);
  } else if (e is IndexExpression) {
    return compileIndexExpression(e, ctx);
  } else if (e is FunctionExpression) {
    return compileFunctionExpression(e, ctx, bound);
  } else if (e is FunctionExpressionInvocation) {
    return compileFunctionExpressionInvocation(e, ctx);
  } else if (e is AwaitExpression) {
    return compileAwaitExpression(e, ctx);
  } else if (e is InstanceCreationExpression) {
    return compileInstanceCreation(ctx, e);
  } else if (e is ParenthesizedExpression) {
    return compileParenthesizedExpression(e, ctx);
  } else if (e is ThrowExpression) {
    return compileThrowExpression(ctx, e);
  } else if (e is ConditionalExpression) {
    return compileConditionalExpression(ctx, e);
  } else if (e is IsExpression) {
    return compileIsExpression(e, ctx);
  } else if (e is CascadeExpression) {
    return compileCascadeExpression(e, ctx);
  } else if (e is AsExpression) {
    return compileAsExpression(e, ctx);
  } else if (e is RethrowExpression) {
    return compileRethrowExpression(ctx, e);
  } else if (e is PatternAssignment) {
    return compilePatternAssignment(ctx, e);
  }

  throw CompileError('Unknown expression type ${e.runtimeType}');
}

Reference compileExpressionAsReference(Expression e, CompilerContext ctx,
    {Variable? cascadeTarget}) {
  if (e is Identifier) {
    return compileIdentifierAsReference(e, ctx);
  } else if (e is IndexExpression) {
    return compileIndexExpressionAsReference(e, ctx,
        cascadeTarget: cascadeTarget);
  } else if (e is PropertyAccess) {
    return compilePropertyAccessAsReference(e, ctx,
        cascadeTarget: cascadeTarget);
  }

  throw NotReferencableError(
      "Unknown expression type or can't reference ${e.runtimeType}");
}

bool canReference(Expression e) {
  return e is Identifier || e is IndexExpression || e is PropertyAccess;
}

Variable? compileExpressionAndDiscardResult(Expression e, CompilerContext ctx,
    {TypeRef? bound, Variable? cascadeTarget}) {
  if (canReference(e)) {
    compileExpressionAsReference(e, ctx, cascadeTarget: cascadeTarget);
    return null;
  } else {
    return compileExpression(e, ctx, bound);
  }
}
