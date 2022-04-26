import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import 'statement.dart';

StatementInfo compileReturn(CompilerContext ctx, ReturnStatement s, AlwaysReturnType? expectedReturnType) {
  if (s.expression == null) {
    ctx.pushOp(Return.make(-1), Return.LEN);
  } else {
    AstNode? _e = s;
    while (_e != null) {
      if (_e is FunctionBody) {
        break;
      }
      _e = _e.parent;
    }

    _e as FunctionBody;
    if (_e.isAsynchronous) {
      final ta = expectedReturnType?.type?.specifiedTypeArgs;
      final expected = (ta?.isEmpty ?? true) ? EvalTypes.dynamicType : ta![0];
      var value = compileExpression(s.expression!, ctx);
      if (!value.type.isAssignableTo(ctx, expected)) {
        throw CompileError('Cannot return ${value.type} (expected: $expected)');
      }
      final _completer = ctx.lookupLocal('#completer');
      _completer!.invoke(ctx, 'complete', [value]);
      ctx.pushOp(Return.make(-1), Return.LEN);
      return StatementInfo(-1, willAlwaysReturn: true);
    }

    final expected = expectedReturnType?.type ?? EvalTypes.dynamicType;
    var value = compileExpression(s.expression!, ctx);
    if (!value.type.isAssignableTo(ctx, expected)) {
      throw CompileError('Cannot return ${value.type} (expected: $expected)');
    }
    if (unboxedAcrossFunctionBoundaries.contains(expected) && ctx.currentClass == null) {
      value = value.unboxIfNeeded(ctx);
    } else {
      value = value.boxIfNeeded(ctx);
    }
    ctx.pushOp(Return.make(value.scopeFrameOffset), Return.LEN);
  }

  return StatementInfo(-1, willAlwaysReturn: true);
}
