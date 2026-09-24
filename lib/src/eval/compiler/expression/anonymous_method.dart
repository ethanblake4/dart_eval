// ignore_for_file: experimental_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/expression/null_aware.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

/// Compiles an anonymous method invocation (`receiver.=> body`,
/// `receiver.(p) => body`, `receiver.{ ... }`): evaluates the receiver,
/// then runs the body with `this` and every declared parameter bound to the
/// receiver's value. The body's value is the result (`null` for a block body
/// that falls through or exits via `break`).
Variable compileAnonymousMethodInvocation(
  AnonymousMethodInvocation e,
  CompilerContext ctx, {
  TypeRef? boundType,
}) {
  final receiver =
      (e.isCascaded ? ctx.cascadeTarget! : compileExpression(e.realTarget, ctx))
          .boxIfNeeded(ctx);

  if (!e.isCascaded && (e.isNullAware || isNullShorted(e.target))) {
    // `target?.=> ...` and anonymous invocations continuing a null-shorted
    // chain: a null receiver produces null without running. Assigns straight
    // to [output] like a `?:` so the result picks up the common base type of
    // both branches.
    final output = BuiltinValue().push(ctx).boxIfNeeded(ctx);
    final nullResult = BuiltinValue().push(ctx).boxIfNeeded(ctx);
    final types = <TypeRef>{CoreTypes.nullType.ref(ctx)};
    macroBranch(
      ctx,
      null,
      condition: (ctx) => compileNonNullCondition(ctx, receiver),
      thenBranch: (ctx, _) {
        final v = _runBody(e, ctx, receiver, boundType);
        types.add(v.type);
        ctx.pushOp(Assign(output.ssa, v.boxIntoFreshSlot(ctx).ssa));
        return StatementInfo();
      },
      elseBranch: (ctx, _) {
        ctx.pushOp(Assign(output.ssa, nullResult.ssa));
        return StatementInfo();
      },
      source: e,
    );
    return output.copyWith(type: TypeRef.commonBaseType(ctx, types));
  }

  return _runBody(e, ctx, receiver, boundType);
}

Variable _runBody(
  AnonymousMethodInvocation e,
  CompilerContext ctx,
  Variable receiver,
  TypeRef? boundType,
) {
  final previousAnonymousThis = ctx.anonymousThisReceiver;
  ctx.beginScope();
  // A null-aware invocation filters the null case out before the body runs —
  // `this` and the parameter bind the non-nullable receiver type.
  final boundReceiver =
      (e.isNullAware || (!e.isCascaded && isNullShorted(e.target)))
      ? receiver.copyWith(type: receiver.type.withNullable(false))
      : receiver;
  ctx.anonymousThisReceiver = boundReceiver;
  ctx.setLocal('#this', boundReceiver);
  final parameters = e.parameters;
  if (parameters != null) {
    for (final parameter in parameters.parameters) {
      final name = parameter.name?.lexeme;
      if (name == null) continue;
      final annotation = parameter.type;
      final declared = annotation == null
          ? null
          : TypeRef.fromAnnotation(ctx, ctx.library, annotation);
      ctx.setLocal(
        name,
        boundReceiver.copyWith(type: declared ?? boundReceiver.type),
        declaredType: declared ?? boundReceiver.type,
      );
    }
  }

  final body = e.body;
  Variable result;
  if (body is AnonymousExpressionBody) {
    result = compileExpression(body.expression, ctx, boundType);
  } else {
    final block = (body as AnonymousBlockBody).block;
    // The result must outlive the body's scope, so it is stored on the
    // enclosing frame and survives the exit-block state merge. Declared
    // `Object?` for the same reason as the null-aware result local.
    final resultName = '#anonResult${ctx.svar('anon_result').name}';
    final resultType = CoreTypes.object.ref(ctx).withNullable(true);
    ctx.setLocal(
      resultName,
      BuiltinValue().push(ctx).boxIfNeeded(ctx).copyWith(type: resultType),
      declaredType: resultType,
      frame: ctx.locals.length - 2,
    );
    final exit = BasicBlock<Operation>([], label: ctx.label('anon_exit'));
    final initialState = ctx.saveState();
    final returnTarget = AnonymousMethodReturn(
      node: e,
      exit: exit,
      resultName: resultName,
      boundType: boundType,
      initialState: initialState,
      exceptionDepth: ctx.exceptionDepth,
    );
    ctx.anonymousMethodReturns.add(returnTarget);
    var info = StatementInfo();
    for (final statement in block.statements) {
      info = compileStatement(statement, null, ctx);
      if (info.willAlwaysBreak ||
          info.willAlwaysReturn ||
          info.willAlwaysThrow) {
        break;
      }
    }
    ctx.anonymousMethodReturns.removeLast();
    final parent = ctx.builder;
    if (!info.willAlwaysBreak &&
        !info.willAlwaysReturn &&
        !info.willAlwaysThrow &&
        !ctx.blockEndsControlFlow) {
      ctx.resolveBranchStateDiscontinuity(initialState);
      ctx.pushOp(Jump(exit.label!));
      final tail = ctx.flushBlock();
      ctx.builder.link(tail, exit);
      // Falling off the end of the block produces null.
      returnTarget.types.add(CoreTypes.nullType.ref(ctx));
    } else if (ctx.blockCode.isNotEmpty) {
      ctx.flushBlock();
    }
    ctx.builder.float(exit);
    ctx.builder = BasicBlockBuilder(ctx.activeGraph, [exit], parent);
    result = ctx
        .lookupLocal(resultName)!
        .copyWith(type: TypeRef.commonBaseType(ctx, returnTarget.types));
  }
  ctx.anonymousThisReceiver = previousAnonymousThis;
  ctx.endScope();
  return result;
}
