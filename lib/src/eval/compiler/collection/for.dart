import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/collection/list.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/macros/loop.dart';
import 'package:dart_eval/src/eval/compiler/statement/for.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/statement/variable_declaration.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

List<TypeRef> compileForElementForList(
  ForElement e,
  Variable list,
  CompilerContext ctx,
  bool box,
) =>
    compileForElement(
      e,
      ctx,
      (element) => compileListElement(element, list, ctx, box),
    );

/// Compiles a collection `for` element, dispatching its body through
/// [compileBody] and returning every type it may produce.
List<TypeRef> compileForElement(
  ForElement e,
  CompilerContext ctx,
  List<TypeRef> Function(CollectionElement) compileBody,
) {
  final potentialReturnTypes = <TypeRef>[];
  final parts = e.forLoopParts;

  if (parts is ForEachParts) {
    final iterable = compileExpression(parts.iterable, ctx).boxIfNeeded(ctx);
    if (e.awaitKeyword != null) {
      compileAwaitForLoop(ctx, e, parts, iterable, null, (ctx, ert) {
        potentialReturnTypes.addAll(compileBody(e.body));
        return StatementInfo();
      });
      return potentialReturnTypes;
    }
    compileForEachLoop(
      ctx,
      parts,
      iterable,
      null,
      body: (ctx, ert) {
        potentialReturnTypes.addAll(compileBody(e.body));
        return StatementInfo();
      },
    );
    return potentialReturnTypes;
  } else if (parts is ForParts) {
    macroLoop(
      ctx,
      null,
      initialization: (ctx) {
        if (parts is ForPartsWithDeclarations) {
          compileVariableDeclarationList(parts.variables, ctx);
        } else if (parts is ForPartsWithExpression) {
          if (parts.initialization != null) {
            compileExpressionAndDiscardResult(parts.initialization!, ctx);
          }
        }
      },
      conditionExpression: parts.condition,
      body: (ctx, ert) {
        potentialReturnTypes.addAll(compileBody(e.body));
        return StatementInfo();
      },
      update: (ctx) {
        for (final u in parts.updaters) {
          compileExpressionAndDiscardResult(u, ctx);
        }
      },
    );
  }

  return potentialReturnTypes;
}
