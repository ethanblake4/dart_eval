import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

extension TearOff on Variable {
  Variable tearOff(CompilerContext ctx) {
    if (type != CoreTypes.function.ref(ctx)) {
      throw CompileError('Cannot tear off non-function');
    }
    if (methodOffset == null) {
      throw CompileError('Invalid method offset for tearoff');
    }
    final Declaration dec;
    TypeRef? targetType;
    if (methodOffset!.className != null) {
      dec = ctx.instanceDeclarationsMap[methodOffset!.file]![
          methodOffset!.className!]![methodOffset!.name]! as MethodDeclaration;
      targetType =
          ctx.visibleTypes[methodOffset!.file!]![methodOffset!.className!]!;
    } else {
      final dec0 =
          ctx.topLevelDeclarationsMap[methodOffset!.file]![methodOffset!.name]!;
      if (dec0.isBridge) {
        throw CompileError('Cannot tear off bridged function');
      }
      dec = dec0.declaration as FunctionDeclaration;
    }

    final FormalParameterList? parameters;
    final String methodName;
    final TypeAnnotation? methodReturnType;
    if (dec is MethodDeclaration) {
      parameters = dec.parameters;
      methodName = dec.name.lexeme;
      methodReturnType = dec.returnType;
    } else {
      final e = (dec as FunctionDeclaration).functionExpression;
      parameters = e.parameters;
      methodName = dec.name.lexeme;
      methodReturnType = dec.returnType;
    }

    final jumpOver = ctx.pushOp(JumpConstant.make(-1), JumpConstant.LEN);

    final fnOffset = ctx.out.length;
    beginMethod(ctx, dec, dec.offset, '<$methodName() tearoff>');

    final ctxSaveState = ctx.saveState();
    final sfo = ctx.scopeFrameOffset;
    ctx.resetStack();

    final existingAllocs = 1 + (parameters?.parameters.length ?? 0);
    ctx.beginAllocScope(existingAllocLen: existingAllocs, closure: true);

    final $prev = Variable(0, CoreTypes.list.ref(ctx), isFinal: true);
    ctx.setLocal('#prev', $prev);

    ctx.scopeFrameOffset += existingAllocs;
    final resolvedParams = resolveFPLDefaults(ctx, parameters, false,
        allowUnboxed: true, sortNamed: true, ignoreDefaults: true);

    var i = 1;

    ctx.beginAllocScope();

    Variable? $target;
    if (dec is MethodDeclaration) {
      final targetOffset =
          BuiltinValue(intval: methodOffset!.targetScopeFrameOffset!).push(ctx);
      ctx.pushOp(
          IndexList.make(0, targetOffset.scopeFrameOffset), IndexList.LEN);
      $target = Variable.alloc(ctx, targetType!);
      ctx.pushOp(PushArg.make($target.scopeFrameOffset), PushArg.LEN);
    }

    for (final param in resolvedParams) {
      final p = param.parameter;
      Variable vRep;

      p as SimpleFormalParameter;
      var type = CoreTypes.dynamic.ref(ctx);
      if (p.type != null) {
        type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
      }
      vRep = Variable(i, type.copyWith(boxed: true));
      vRep = ctx.setLocal(p.name!.lexeme, vRep);
      if (type.isUnboxedAcrossFunctionBoundaries && dec is! MethodDeclaration) {
        vRep = vRep.unboxIfNeeded(ctx);
      }

      ctx.pushOp(PushArg.make(vRep.scopeFrameOffset), PushArg.LEN);

      ctx.setLocal(vRep.name!, vRep);

      i++;
    }

    if (dec is MethodDeclaration) {
      final targetOffset =
          BuiltinValue(intval: methodOffset!.targetScopeFrameOffset!).push(ctx);
      ctx.pushOp(
          IndexList.make(0, targetOffset.scopeFrameOffset), IndexList.LEN);
      final $target = Variable.alloc(ctx, targetType!);
      final invokeOp = InvokeDynamic.make(
          $target.scopeFrameOffset, ctx.constantPool.addOrGet(methodName));
      ctx.pushOp(invokeOp, InvokeDynamic.len(invokeOp));
    } else {
      final loc =
          ctx.pushOp(Call.make(methodOffset!.offset ?? -1), Call.length);
      if (methodOffset!.offset == null) {
        ctx.offsetTracker.setOffset(loc, methodOffset!);
      }
    }

    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

    var returnType = CoreTypes.dynamic.ref(ctx);
    if (methodReturnType != null) {
      returnType = TypeRef.fromAnnotation(ctx, ctx.library, methodReturnType);
      returnType = returnType.copyWith(
          boxed: dec is MethodDeclaration ||
              !returnType.isUnboxedAcrossFunctionBoundaries);
    }
    var rV = Variable.alloc(ctx, returnType);
    rV = rV.boxIfNeeded(ctx);

    ctx.pushOp(Return.make(rV.scopeFrameOffset), Return.LEN);
    ctx.endAllocScope();

    ctx.rewriteOp(jumpOver, JumpConstant.make(ctx.out.length), 0);

    ctx.restoreState(ctxSaveState);
    ctx.scopeFrameOffset = sfo;

    final positional = ((parameters?.parameters ?? [])
        .where((element) => element.isPositional));
    final requiredPositionalArgCount =
        positional.where((element) => element.isRequired).length;

    final positionalArgTypes = positional
        .map((a) => a is NormalFormalParameter
            ? a
            : (a as DefaultFormalParameter).parameter)
        .cast<SimpleFormalParameter>()
        .map((a) => a.type == null
            ? CoreTypes.dynamic.ref(ctx)
            : TypeRef.fromAnnotation(ctx, ctx.library, a.type!))
        .map((t) => t.toRuntimeType(ctx))
        .map((rt) => rt.toJson())
        .toList();

    final named = ((parameters?.parameters ?? <FormalParameter>[])
        .where((element) => element.isNamed));
    final sortedNamedArgs = named.toList()
      ..sort((e1, e2) => (e1.name!.lexeme).compareTo((e2.name!.lexeme)));
    final sortedNamedArgNames =
        sortedNamedArgs.map((e) => e.name!.lexeme).toList();

    final sortedNamedArgTypes = sortedNamedArgs
        .map((e) => e is DefaultFormalParameter ? e.parameter : e)
        .cast<SimpleFormalParameter>()
        .map((a) => a.type == null
            ? CoreTypes.dynamic.ref(ctx)
            : TypeRef.fromAnnotation(ctx, ctx.library, a.type!))
        .map((t) => t.toRuntimeType(ctx))
        .map((rt) => rt.toJson())
        .toList();

    BuiltinValue(intval: requiredPositionalArgCount).push(ctx).pushArg(ctx);
    BuiltinValue(intval: ctx.constantPool.addOrGet(positionalArgTypes))
        .push(ctx)
        .pushArg(ctx);
    BuiltinValue(intval: ctx.constantPool.addOrGet(sortedNamedArgNames))
        .push(ctx)
        .pushArg(ctx);
    BuiltinValue(intval: ctx.constantPool.addOrGet(sortedNamedArgTypes))
        .push(ctx)
        .pushArg(ctx);

    ctx.pushOp(PushFunctionPtr.make(fnOffset), PushFunctionPtr.LEN);

    return Variable.alloc(ctx, CoreTypes.function.ref(ctx),
        methodReturnType: AlwaysReturnType(CoreTypes.dynamic.ref(ctx), false),
        methodOffset: DeferredOrOffset(offset: fnOffset),
        callingConvention: CallingConvention.dynamic);
  }
}
