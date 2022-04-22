import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'context.dart';

int beginMethod(CompilerContext ctx, AstNode scopeHost, int offset, String name) {
  final position = ctx.out.length;
  var op = PushScope.make(ctx.library, offset, name);
  ctx.pushOp(op, PushScope.len(op));
  return position;
}

void setupAsyncFunction(CompilerContext ctx) {
  ctx.pushOp(InvokeExternal.make(ctx.bridgeStaticFunctionIndices[ctx.libraryMap['dart:async']!]!['Completer.']!),
      InvokeExternal.LEN);
  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  ctx.setLocal('#completer', Variable.alloc(ctx, TypeRef.stdlib(ctx, 'dart:async', 'Completer')));
  ctx.nearestAsyncFrame = ctx.locals.length - 1;
}
