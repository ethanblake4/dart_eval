import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/macros/loop.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/statement/variable_declaration.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

StatementInfo compileForStatement(ForStatement s, CompilerContext ctx, AlwaysReturnType? expectedReturnType) {
  final parts = s.forLoopParts;

  if (parts is! ForParts) {
    throw UnimplementedError('For-each is not supported yet');
  }

  return macroLoop(ctx, expectedReturnType,
      initialization: (_ctx) {
        if (parts is ForPartsWithDeclarations) {
          compileVariableDeclarationList(parts.variables, _ctx);
        } else if (parts is ForPartsWithExpression) {
          if (parts.initialization != null) {
            compileExpressionAndDiscardResult(parts.initialization!, _ctx);
          }
        }
      },
      condition: parts.condition == null ? null : (_ctx) => compileExpression(parts.condition!, _ctx),
      body: (_ctx, ert) => compileStatement(s.body, ert, _ctx),
      update: (_ctx) {
        for (final u in parts.updaters) {
          compileExpressionAndDiscardResult(u, _ctx);
        }
      });
}
