import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

/// Compile a [FunctionExpressionInvocation]
Variable compileFunctionExpressionInvocation(FunctionExpressionInvocation e, CompilerContext ctx) {
  Reference? target;
  Variable? fallback;

  // Using a reference allows us to potentially optimize to static dispatch, if the exact function
  // is known at compile-time
  if (canReference(e.function)) {
    target = compileExpressionAsReference(e.function, ctx);
  } else {
    fallback = compileExpression(e.function, ctx);
  }

  var posArgCount = 0;
  final namedArgs = <String>[];
  for (final arg in e.argumentList.arguments) {
    if (arg is NamedExpression) {
      namedArgs.add(arg.name.label.name);
    } else {
      posArgCount++;
    }
  }

  namedArgs.sort();


  ctx.pushOp(PushList.make(), PushList.LEN);
  final list = Variable.alloc(ctx, EvalTypes.listType);

  ctx.pushOp(PushConstant.make(ctx.constantPool.addOrGet(namedArgs)), PushConstant.LEN);
  final alConstVar = Variable.alloc(ctx, EvalTypes.listType.copyWith(specifiedTypeArgs: [EvalTypes.stringType]));

  ctx.pushOp(PushArg.make(list.scopeFrameOffset), PushArg.LEN);
  ctx.pushOp(PushArg.make(alConstVar.scopeFrameOffset), PushArg.LEN);
  ctx.pushOp(PushArg.make(list.scopeFrameOffset), PushArg.LEN);

  final sd = target?.getStaticDispatch(ctx);
  if (sd != null) {
    // Use static dispatch
    final loc = ctx.pushOp(Call.make(sd.offset.offset ?? -1), Call.LEN);
    ctx.offsetTracker.setOffset(loc, sd.offset);
    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    return Variable.alloc(ctx, EvalTypes.dynamicType.copyWith(boxed: true));
  } else {
    // Fallback to dynamic dispatch
    final dd = target?.getValue(ctx) ?? fallback!;


    final res = dd.invoke(ctx, 'call', []);
    return res.result;
  }

}
