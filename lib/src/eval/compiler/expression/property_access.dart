import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compilePropertyAccess(PropertyAccess pa, CompilerContext ctx, {Variable? cascadeTarget}) {
  final L = cascadeTarget ?? compileExpression(pa.realTarget, ctx);
  return L.getProperty(ctx, pa.propertyName.name);
}

Reference compilePropertyAccessAsReference(PropertyAccess pa, CompilerContext ctx, {Variable? cascadeTarget}) {
  final L = cascadeTarget ?? compileExpression(pa.realTarget, ctx);
  return IdentifierReference(L, pa.propertyName.name);
}
