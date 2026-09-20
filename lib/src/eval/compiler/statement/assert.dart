import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/assert.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

StatementInfo compileAssertStatement(
  AssertStatement s,
  CompilerContext ctx,
  AlwaysReturnType? expectedReturnType,
) {
  final cond = compileExpression(s.condition, ctx);
  final msg = s.message != null
      ? compileExpression(s.message!, ctx)
      : BuiltinValue().push(ctx);

  // A Never-typed message already threw while evaluating (e.g.
  // `assert(cond, throw e)`), so the assert itself always diverges.
  if (msg.type == CoreTypes.never.ref(ctx)) {
    return StatementInfo(willAlwaysThrow: true);
  }

  doAssert(ctx, cond, msg);

  return StatementInfo();
}
