import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/assignment.dart';
import 'package:dart_eval/src/eval/compiler/expression/binary.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart';
import 'package:dart_eval/src/eval/compiler/expression/invocation.dart';
import 'package:dart_eval/src/eval/compiler/expression/literal.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileExpression(Expression e, CompilerContext ctx) {
  if (e is Literal) {
    return parseLiteral(e, ctx).push(ctx);
  } else if (e is AssignmentExpression) {
    return compileAssignmentExpression(e, ctx);
  } else if (e is Identifier) {
    return compileIdentifier(e, ctx);
  } else if (e is MethodInvocation) {
    return compileMethodInvocation(ctx, e);
  } else if (e is BinaryExpression) {
    return compileBinaryExpression(ctx, e);
  }

  throw CompileError('Unknown expression type ${e.runtimeType}');
}