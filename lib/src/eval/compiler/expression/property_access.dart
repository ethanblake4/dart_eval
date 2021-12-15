import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compilePropertyAccess(PropertyAccess pa, CompilerContext ctx) {
  final L = compileExpression(pa.realTarget, ctx);

  final op = PushObjectProperty.make(L.scopeFrameOffset, pa.propertyName.name);
  ctx.pushOp(op, PushObjectProperty.len(op));

  return Variable.alloc(ctx, TypeRef.lookupFieldType(ctx, L.type, pa.propertyName.name));
}