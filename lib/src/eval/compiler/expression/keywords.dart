import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileThisExpression(ThisExpression e, CompilerContext ctx) {
  if (ctx.currentClass == null) {
    throw CompileError("Cannot use 'this' outside of a class context");
  }
  return Variable(0, ctx.visibleTypes[ctx.library]![ctx.currentClass!.name.name]!);
}