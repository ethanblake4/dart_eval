import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/macros/loop.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

StatementInfo compileDoStatement(
    DoStatement s, CompilerContext ctx, AlwaysReturnType? expectedReturnType) {
  return macroLoop(ctx, expectedReturnType,
      condition: (ctx) => compileExpression(s.condition, ctx),
      body: (ctx, ert) => compileStatement(s.body, ert, ctx),
      alwaysLoopOnce: true);
}
