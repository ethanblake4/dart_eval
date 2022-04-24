import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compilePropertyAccess(PropertyAccess pa, CompilerContext ctx) {
  final L = compileExpression(pa.realTarget, ctx);

  final op = PushObjectProperty.make(L.scopeFrameOffset, pa.propertyName.name);
  ctx.pushOp(op, PushObjectProperty.len(op));

  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  final v = Variable.alloc(ctx, TypeRef.lookupFieldType(ctx, L.type, pa.propertyName.name) ?? EvalTypes.dynamicType);

  return v;
}
