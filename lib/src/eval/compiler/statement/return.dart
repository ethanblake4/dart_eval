// ignore_for_file: experimental_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/statement/break.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

import 'statement.dart';

StatementInfo compileReturn(
  CompilerContext ctx,
  ReturnStatement s,
  AlwaysReturnType? expectedReturnType, {
  bool skipClassBoxing = false,
}) {
  AstNode? e = s;
  AnonymousMethodReturn? anonymousReturn;
  while (e != null) {
    if (e is AnonymousMethodInvocation &&
        (anonymousReturn = ctx.anonymousMethodReturns
            .where((t) => identical(t.node, e))
            .firstOrNull) !=
            null) {
      break;
    }
    if (e is FunctionBody) {
      break;
    }
    e = e.parent;
  }

  final expression = s.expression;

  final value = expression == null
      ? null
      : compileExpression(
          s.expression!,
          ctx,
          anonymousReturn?.boundType ?? expectedReturnType?.type,
        );

  // `return` inside an anonymous-method body returns from the invocation,
  // not the enclosing function: store the value and jump to the body's end.
  if (anonymousReturn != null) {
    final target = anonymousReturn;
    target.types.add(value?.type ?? CoreTypes.nullType.ref(ctx));
    IdentifierReference(null, target.resultName).setValue(
      ctx,
      value?.boxIfNeeded(ctx) ?? BuiltinValue().push(ctx).boxIfNeeded(ctx),
    );
    jumpToLabel(
      ctx,
      CompilerLabel(
        (ctx) => ctx.resolveBranchStateDiscontinuity(target.initialState),
        exceptionDepth: target.exceptionDepth,
        breakTarget: target.exit,
      ),
      target.exit,
    );
    return StatementInfo(willAlwaysBreak: true);
  }
  final body = e as FunctionBody;
  if (body.parent is FunctionExpression &&
      ctx.asyncClosureReturnTypes.isNotEmpty) {
    ctx.asyncClosureReturnTypes.last.add(
      value?.type ?? CoreTypes.nullType.ref(ctx),
    );
  }
  return doReturn(
    ctx,
    expectedReturnType ?? AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true),
    value,
    isAsync: body.isAsynchronous,
    skipClassBoxing: skipClassBoxing,
  );
}
