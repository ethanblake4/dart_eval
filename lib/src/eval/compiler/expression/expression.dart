import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/assignment.dart';
import 'package:dart_eval/src/eval/compiler/expression/await.dart';
import 'package:dart_eval/src/eval/compiler/expression/binary.dart';
import 'package:dart_eval/src/eval/compiler/expression/funcexpr_invocation.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart';
import 'package:dart_eval/src/eval/compiler/expression/index.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/expression/keywords.dart';
import 'package:dart_eval/src/eval/compiler/expression/literal.dart';
import 'package:dart_eval/src/eval/compiler/expression/postfix.dart';
import 'package:dart_eval/src/eval/compiler/expression/property_access.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileExpression(Expression e, CompilerContext ctx) {
  if (e is Literal) {
    return parseLiteral(e, ctx);
  } else if (e is AssignmentExpression) {
    return compileAssignmentExpression(e, ctx);
  } else if (e is Identifier) {
    return compileIdentifier(e, ctx);
  } else if (e is MethodInvocation) {
    return compileMethodInvocation(ctx, e);
  } else if (e is BinaryExpression) {
    return compileBinaryExpression(ctx, e);
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
    return compileFunctionExpression(e, ctx);
  } else if (e is FunctionExpressionInvocation) {
    return compileFunctionExpressionInvocation(e, ctx);
  } else if (e is AwaitExpression) {
    return compileAwaitExpression(e, ctx);
  }

  throw CompileError('Unknown expression type ${e.runtimeType}');
}

Reference compileExpressionAsReference(Expression e, CompilerContext ctx) {
  if (e is Identifier) {
    return compileIdentifierAsReference(e, ctx);
  } else if (e is AssignmentExpression) {
    return compileAssignmentExpressionAsReference(e, ctx);
  } else if (e is IndexExpression) {
    return compileIndexExpressionAsReference(e, ctx);
  }

  throw NotReferencableError(
      "Unknown expression type or can't reference ${e.runtimeType}");
}

bool canReference(Expression e) {
  return e is Identifier || e is AssignmentExpression || e is IndexExpression;
}

void compileExpressionAndDiscardResult(Expression e, CompilerContext ctx) {
  if (canReference(e)) {
    compileExpressionAsReference(e, ctx);
  } else {
    compileExpression(e, ctx);
  }
}
