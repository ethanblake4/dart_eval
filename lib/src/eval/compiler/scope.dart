import 'package:analyzer/dart/ast/ast.dart';

import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'context.dart';

int beginMethod(CompilerContext ctx, AstNode scopeHost, int offset, String name) {
  final position = ctx.out.length;
  var op = PushScope.make(ctx.library, offset, name);
  ctx.pushOp(op, PushScope.len(op));
  return position;
}
