import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

Variable compileAssignmentExpression(AssignmentExpression e, CompilerContext ctx) {
  final L = compileExpression(e.leftHandSide, ctx);
  final R = compileExpression(e.rightHandSide, ctx);

  if (!R.type.isAssignableTo(L.type)) {
    throw CompileError('Syntax error: cannot assign value of type ${R.type} to ${L.type}');
  }

  ctx.pushOp(CopyValue.make(L.scopeFrameOffset, R.scopeFrameOffset), CopyValue.LEN);
  return L;
}