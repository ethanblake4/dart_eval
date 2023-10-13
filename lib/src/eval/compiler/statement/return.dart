import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

import 'statement.dart';

StatementInfo compileReturn(CompilerContext ctx, ReturnStatement s,
    AlwaysReturnType? expectedReturnType) {
  AstNode? _e = s;
  while (_e != null) {
    if (_e is FunctionBody) {
      break;
    }
    _e = _e.parent;
  }

  final value = compileExpression(s.expression!, ctx, expectedReturnType?.type);
  return doReturn(
      ctx,
      expectedReturnType ?? AlwaysReturnType(EvalTypes.dynamicType, true),
      value,
      isAsync: (_e as FunctionBody).isAsynchronous);
}
