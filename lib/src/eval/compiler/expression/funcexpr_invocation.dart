import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/type.dart';

/// Compile a [FunctionExpressionInvocation]
Variable compileFunctionExpressionInvocation(
    FunctionExpressionInvocation e, CompilerContext ctx) {
  Reference? target;
  Variable? fallback;

  // Using a reference allows us to potentially optimize to static dispatch, if the exact function
  // is known at compile-time
  if (canReference(e.function)) {
    target = compileExpressionAsReference(e.function, ctx);
  } else {
    fallback = compileExpression(e.function, ctx);
  }

  return invokeClosure(ctx, target, fallback, e.argumentList);
}

Variable invokeClosure(CompilerContext ctx, Reference? closureRef,
    Variable? closureVar, ArgumentList argumentList) {
  ctx.pushOp(PushList.make(), PushList.LEN);
  final csPosArgTypes = Variable.alloc(
      ctx,
      CoreTypes.list
          .ref(ctx)
          .copyWith(specifiedTypeArgs: [CoreTypes.int.ref(ctx)]));

  final positionalArgs = <Variable>[];

  ctx.pushOp(PushList.make(), PushList.LEN);
  final csNamedArgTypes = Variable.alloc(
      ctx,
      CoreTypes.list
          .ref(ctx)
          .copyWith(specifiedTypeArgs: [CoreTypes.int.ref(ctx)]));

  final namedArgs = <String, Variable>{};
  final namedArgsRttiMap = <String, int>{};
  final namedArgNames = <String>[];

  for (final arg in argumentList.arguments) {
    if (arg is NamedExpression) {
      final nName = arg.name.label.name;
      namedArgNames.add(nName);

      var argVar = compileExpression(arg.expression, ctx);
      argVar = argVar.boxIfNeeded(ctx);

      final type = argVar.type.resolveTypeChain(ctx);
      final rtti = type.getRuntimeIndices(ctx);

      final rttiIndex = ctx.runtimeTypes
          .addOrGet(RuntimeTypeSet(type.toRuntimeType(ctx).type, rtti, []));
      namedArgsRttiMap[nName] = rttiIndex;
      namedArgs[nName] = argVar;
    } else {
      var argVar = compileExpression(arg, ctx);
      argVar = argVar.boxIfNeeded(ctx);

      final type = argVar.type.resolveTypeChain(ctx);
      final rtti = type.getRuntimeIndices(ctx);

      final rttiIndex = ctx.runtimeTypes
          .addOrGet(RuntimeTypeSet(type.toRuntimeType(ctx).type, rtti, []));
      final la = ListAppend.make(csPosArgTypes.scopeFrameOffset,
          BuiltinValue(intval: rttiIndex).push(ctx).scopeFrameOffset);

      ctx.pushOp(la, ListAppend.LEN);

      positionalArgs.add(argVar);
    }
  }

  namedArgNames.sort();

  for (final name in namedArgNames) {
    final la = ListAppend.make(
        csNamedArgTypes.scopeFrameOffset,
        BuiltinValue(intval: namedArgsRttiMap[name])
            .push(ctx)
            .scopeFrameOffset);
    ctx.pushOp(la, ListAppend.LEN);
  }

  ctx.pushOp(PushConstant.make(ctx.constantPool.addOrGet(namedArgNames)),
      PushConstant.LEN);
  final alConstVar = Variable.alloc(
      ctx,
      CoreTypes.list
          .ref(ctx)
          .copyWith(specifiedTypeArgs: [CoreTypes.string.ref(ctx)]));

  ctx.pushOp(PushArg.make(csPosArgTypes.scopeFrameOffset), PushArg.LEN);
  ctx.pushOp(PushArg.make(alConstVar.scopeFrameOffset), PushArg.LEN);
  ctx.pushOp(PushArg.make(csNamedArgTypes.scopeFrameOffset), PushArg.LEN);

  for (final arg in positionalArgs) {
    arg.pushArg(ctx);
  }

  for (final name in namedArgNames) {
    namedArgs[name]!.pushArg(ctx);
  }

  final sd = closureRef?.getStaticDispatch(ctx);
  if (sd != null) {
    // Use static dispatch
    final loc = ctx.pushOp(Call.make(sd.offset.offset ?? -1), Call.length);
    ctx.offsetTracker.setOffset(loc, sd.offset);
    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    return Variable.alloc(
        ctx, CoreTypes.dynamic.ref(ctx).copyWith(boxed: true));
  } else {
    // Fallback to dynamic dispatch
    final dd = closureRef?.getValue(ctx) ?? closureVar!;

    final res = dd.invoke(ctx, 'call', []);
    return res.result;
  }
}
