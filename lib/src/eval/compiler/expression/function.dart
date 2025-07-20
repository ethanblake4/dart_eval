import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/model/function_type.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/util.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

enum CallingConvention { static, dynamic }

Variable compileFunctionExpression(FunctionExpression e, CompilerContext ctx,
    [TypeRef? bound]) {
  final jumpOver = ctx.pushOp(JumpConstant.make(-1), JumpConstant.LEN);

  final fnOffset = ctx.out.length;
  beginMethod(ctx, e, e.offset, '<anonymous closure>');

  final ctxSaveState = ctx.saveState();
  final sfo = ctx.scopeFrameOffset;
  ctx.resetStack();

  final existingAllocs = 1 + (e.parameters?.parameters.length ?? 0);
  ctx.beginAllocScope(existingAllocLen: existingAllocs, closure: true);

  final $prev = Variable(0, CoreTypes.list.ref(ctx), isFinal: true);

  ctx.setLocal('#prev', $prev);

  ctx.scopeFrameOffset += existingAllocs;
  final resolvedParams = resolveFPLDefaults(ctx, e.parameters, false,
      allowUnboxed: false, sortNamed: true);

  List<FunctionFormalParameter> boundNormalParams = [];
  List<FunctionFormalParameter> boundOptionalParams = [];
  List<FunctionFormalParameter> boundNamedParams = [];
  if (bound != null) {
    final functionType = bound.functionType;
    if (functionType != null) {
      boundNormalParams = functionType.normalParameters;
      boundOptionalParams = functionType.optionalParameters;
      boundNamedParams = functionType.namedParameters.entries
          .map((e) => e.value)
          .sorted((a, b) => a.name!.compareTo(b.name!));
    }
  }

  final boundPositionalParams = [...boundNormalParams, ...boundOptionalParams];
  final inorderBoundParams = [...boundPositionalParams, ...boundNamedParams];

  var i = 0;

  for (final param in resolvedParams) {
    final p = param.parameter;
    Variable vRep;

    p as SimpleFormalParameter;
    var type = CoreTypes.dynamic.ref(ctx);
    if (p.type != null) {
      type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
    } else if (i < inorderBoundParams.length) {
      final fType = inorderBoundParams[i].type;
      if (fType.type != null) {
        type = fType.type!;
      }
    }
    vRep = Variable(i + 1, type.copyWith(boxed: true))..name = p.name!.lexeme;

    ctx.setLocal(vRep.name!, vRep);

    i++;
  }

  final b = e.body;

  if (b.isAsynchronous) {
    setupAsyncFunction(ctx);
  }

  StatementInfo? stInfo;
  if (b is BlockFunctionBody) {
    stInfo = compileBlock(
        b.block,
        /*AlwaysReturnType.fromAnnotation(ctx, ctx.library, d.returnType, CoreTypes.dynamic.ref(ctx))*/
        AlwaysReturnType(CoreTypes.dynamic.ref(ctx), false),
        ctx,
        name: '(closure)');
  } else if (b is ExpressionFunctionBody) {
    ctx.beginAllocScope();
    final V = compileExpression(b.expression, ctx);
    stInfo = doReturn(
        ctx, AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true), V,
        isAsync: b.isAsynchronous);
    ctx.endAllocScope();
  } else {
    throw CompileError('Unsupported function body type: ${b.runtimeType}');
  }

  if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
    if (b.isAsynchronous) {
      asyncComplete(ctx, -1);
      ctx.endAllocScope(popValues: false);
    } else {
      ctx.endAllocScope();
      ctx.pushOp(Return.make(-1), Return.LEN);
    }
  }

  ctx.rewriteOp(jumpOver, JumpConstant.make(ctx.out.length), 0);

  ctx.restoreState(ctxSaveState);
  ctx.scopeFrameOffset = sfo;

  final positional =
      (e.parameters?.parameters.where((element) => element.isPositional) ?? []);
  final requiredPositionalArgCount =
      positional.where((element) => element.isRequired).length;

  final positionalArgTypes = positional
      .map((a) => a is NormalFormalParameter
          ? a
          : (a as DefaultFormalParameter).parameter)
      .cast<SimpleFormalParameter>()
      .mapIndexed((i, a) {
        if (a.type != null) {
          return TypeRef.fromAnnotation(ctx, ctx.library, a.type!);
        }
        if (i < boundPositionalParams.length) {
          final fType = boundPositionalParams[i].type;
          if (fType.type != null) {
            return fType.type!;
          }
        }
        return CoreTypes.dynamic.ref(ctx);
      })
      .map((t) => t.toRuntimeType(ctx))
      .map((rt) => rt.toJson())
      .toList();

  final named =
      (e.parameters?.parameters.where((element) => element.isNamed) ?? []);
  final sortedNamedArgs = named.toList()
    ..sort((e1, e2) => (e1.name!.lexeme).compareTo((e2.name!.lexeme)));
  final sortedNamedArgNames =
      sortedNamedArgs.map((e) => e.name!.lexeme).toList();

  final sortedNamedArgTypes = sortedNamedArgs
      .map((e) => e is DefaultFormalParameter ? e.parameter : e)
      .cast<SimpleFormalParameter>()
      .mapIndexed((i, a) {
        if (a.type != null) {
          return TypeRef.fromAnnotation(ctx, ctx.library, a.type!);
        }
        if (i < boundNamedParams.length) {
          final fType = boundNamedParams[i].type;
          if (fType.type != null) {
            return fType.type!;
          }
        }
        return CoreTypes.dynamic.ref(ctx);
      })
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
