import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/assert.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

StatementInfo compileAssertStatement(
  AssertStatement s,
  CompilerContext ctx,
  TypeRef? expectedReturnType,
) {
  final cond = compileExpression(s.condition, ctx);
  final message = s.message;
  doAssert(
    ctx,
    cond,
    message: message == null
        ? (ctx) => BuiltinValue().push(ctx)
        : (ctx) => compileExpression(message, ctx),
  );

  return StatementInfo();
}
