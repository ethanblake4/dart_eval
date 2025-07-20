import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

Variable compileAwaitExpression(AwaitExpression e, CompilerContext ctx) {
  AstNode? e0 = e;
  while (e0 != null) {
    if (e0 is FunctionBody) {
      if (!e0.isAsynchronous) {
        throw CompileError('Cannot use await in a non-async context');
      } else {
        break;
      }
    }
    e0 = e0.parent;
  }

  final subject = compileExpression(e.expression, ctx);
  final type = subject.type.resolveTypeChain(ctx);

  if (!type.isAssignableTo(ctx, CoreTypes.future.ref(ctx))) {
    throw CompileError("Cannot await something that isn't a Future");
  }

  var completer = ctx.lookupLocal('#completer');

  final awaitOp =
      Await.make(completer!.scopeFrameOffset, subject.scopeFrameOffset);
  ctx.pushOp(awaitOp, Await.LEN);

  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

  return Variable.alloc(
      ctx,
      type.specifiedTypeArgs.isNotEmpty
          ? type.specifiedTypeArgs[0]
          : CoreTypes.dynamic.ref(ctx));
}
