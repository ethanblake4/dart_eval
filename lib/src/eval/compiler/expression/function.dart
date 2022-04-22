import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/util.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

enum CallingConvention {
  static,
  dynamic
}

Variable compileFunctionExpression(FunctionExpression e, CompilerContext ctx) {

  final jumpOver = ctx.pushOp(JumpConstant.make(-1), JumpConstant.LEN);

  final fnOffset = ctx.out.length;
  beginMethod(ctx, e, e.offset, '<anonymous closure>');

  final ctxSaveState = ctx.saveState();
  final sfo = ctx.scopeFrameOffset;
  ctx.resetStack();

  final _existingAllocs = 1 + (e.parameters?.parameters.length ?? 0);
  ctx.beginAllocScope(existingAllocLen: _existingAllocs);

  ctx.scopeFrameOffset += _existingAllocs;
  final resolvedParams = resolveFPLDefaults(ctx, e.parameters!, false, allowUnboxed: true, sortNamed: true);

  var i = 0;

  for (final param in resolvedParams) {
    final p = param.parameter;
    Variable Vrep;

    p as SimpleFormalParameter;
    var type = EvalTypes.dynamicType;
    if (p.type != null) {
      type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
    }
    Vrep = Variable(i, type.copyWith(boxed: !unboxedAcrossFunctionBoundaries.contains(type)))
      ..name = p.identifier!.name;

    ctx.setLocal(Vrep.name!, Vrep);

    i++;
  }

  //ctx.pushOp(PushCaptureScope.make(), PushCaptureScope.LEN);
  //final $prev = Variable.alloc(ctx, EvalTypes.listType, isFinal: true);

  final b = e.body;

  if (b.isAsynchronous) {
    setupAsyncFunction(ctx);
  }

  StatementInfo? stInfo;
  if (b is BlockFunctionBody) {
    stInfo = compileBlock(
        b.block,
        /*AlwaysReturnType.fromAnnotation(ctx, ctx.library, d.returnType, EvalTypes.dynamicType)*/
        AlwaysReturnType(EvalTypes.dynamicType, false),
        ctx,
        name: '(closure)');
  }

  ctx.endAllocScope();
  if (stInfo == null || !(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
    if (b.isAsynchronous) {
      asyncComplete(ctx);
    }
    ctx.pushOp(Return.make(-1), Return.LEN);
  }

  ctx.rewriteOp(jumpOver, JumpConstant.make(ctx.out.length), 0);

  ctx.restoreState(ctxSaveState);
  ctx.scopeFrameOffset = sfo;

  final positional = (e.parameters?.parameters.where((element) => element.isPositional) ?? []);
  final requiredPositionalArgCount = positional.where((element) => element.isRequired).length;

  final positionalArgTypes = positional.cast<SimpleFormalParameter>()
        .map((a) => a.type == null ? EvalTypes.dynamicType : TypeRef.fromAnnotation(ctx, ctx.library, a.type!))
        .map((t) => t.toRuntimeType(ctx))
        .map((rt) => rt.toJson())
        .toList();

  final named = (e.parameters?.parameters.where((element) => element.isNamed) ?? []);
  final sortedNamedArgs = named.toList()..sort((e1, e2) => e1.identifier!.name.compareTo(e2.identifier!.name));
  final sortedNamedArgNames = sortedNamedArgs.map((e) => e.identifier!.name).toList();

  final sortedNamedArgTypes = sortedNamedArgs
      .map((e) => e is DefaultFormalParameter ? e.parameter : e)
      .cast<SimpleFormalParameter>()
      .map((a) => a.type == null ? EvalTypes.dynamicType : TypeRef.fromAnnotation(ctx, ctx.library, a.type!))
      .map((t) => t.toRuntimeType(ctx))
      .map((rt) => rt.toJson())
      .toList();

  BuiltinValue(intval: requiredPositionalArgCount).push(ctx).pushArg(ctx);
  BuiltinValue(intval: ctx.constantPool.addOrGet(positionalArgTypes)).push(ctx).pushArg(ctx);
  BuiltinValue(intval: ctx.constantPool.addOrGet(sortedNamedArgNames)).push(ctx).pushArg(ctx);
  BuiltinValue(intval: ctx.constantPool.addOrGet(sortedNamedArgTypes)).push(ctx).pushArg(ctx);

  ctx.pushOp(PushFunctionPtr.make(fnOffset), PushFunctionPtr.LEN);

  return Variable.alloc(ctx, EvalTypes.functionType, methodReturnType: AlwaysReturnType(EvalTypes.dynamicType, false),
      methodOffset: DeferredOrOffset(offset: fnOffset), callingConvention: CallingConvention.dynamic);
}
