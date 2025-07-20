import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

import 'statement.dart';

StatementInfo compileReturn(CompilerContext ctx, ReturnStatement s,
    AlwaysReturnType? expectedReturnType) {
  AstNode? e = s;
  while (e != null) {
    if (e is FunctionBody) {
      break;
    }
    e = e.parent;
  }

  final expression = s.expression;

  final value = expression == null
      ? null
      : compileExpression(s.expression!, ctx, expectedReturnType?.type);
  return doReturn(
      ctx,
      expectedReturnType ?? AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true),
      value,
      isAsync: (e as FunctionBody).isAsynchronous);
}
