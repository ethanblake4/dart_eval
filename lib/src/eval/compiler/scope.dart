import 'package:analyzer/dart/ast/ast.dart';

import '../../../dart_eval.dart';
import 'context.dart';

int enterScope(CompilerContext ctx, AstNode scopeHost, int offset, String name) {
  final position = ctx.out.length;
  var op = PushScope.make(ctx.library, offset, name);
  ctx.pushOp(op, PushScope.len(op));
  ctx.locals.add({});
  return position;
}

void exitScope(CompilerContext ctx) {
  ctx.locals.removeLast();
}