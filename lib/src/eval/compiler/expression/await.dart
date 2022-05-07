import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

Variable compileAwaitExpression(AwaitExpression e, CompilerContext ctx) {
  AstNode? _e = e;
  while (_e != null) {
    if (_e is FunctionBody) {
      if (!_e.isAsynchronous) {
        throw CompileError('Cannot use await in a non-async context');
      } else {
        break;
      }
    }
    _e = _e.parent;
  }

  final subject = compileExpression(e.expression, ctx);

  if (!subject.type.resolveTypeChain(ctx).isAssignableTo(ctx, TypeRef.stdlib(ctx, 'dart:core', 'Future'))) {
    throw CompileError("Cannot await something that isn't a Future");
  }

  var _completer = ctx.lookupLocal('#completer');

  final awaitOp = Await.make(_completer!.scopeFrameOffset, subject.scopeFrameOffset);
  ctx.pushOp(awaitOp, Await.LEN);

  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

  return Variable.alloc(ctx, EvalTypes.dynamicType);
}
