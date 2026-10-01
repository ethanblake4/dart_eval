import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/collection/list.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/statement/for.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'element_result.dart';

CollectionElementResult compileForElementForList(
  ForElement e,
  Variable list,
  CompilerContext ctx,
  bool box,
) {
  return compileForElement(
    e,
    ctx,
    (element) => compileListElement(element, list, ctx, box),
  );
}

/// Compiles a collection `for` element, dispatching its body through
/// [compileBody] and returning every type it may produce.
CollectionElementResult compileForElement(
  ForElement e,
  CompilerContext ctx,
  CollectionElementResult Function(CollectionElement) compileBody,
) {
  final potentialReturnTypes = <TypeRef>[];
  final parts = e.forLoopParts;

  if (parts is ForEachParts) {
    final iterable = compileExpression(
      parts.iterable,
      ctx,
      forEachIterableBound(ctx, parts, await_: e.awaitKeyword != null),
    ).boxIfNeeded(ctx);
    if (e.awaitKeyword != null) {
      compileAwaitForLoop(ctx, e, parts, iterable, null, (ctx, ert) {
        potentialReturnTypes.addAll(compileBody(e.body).types);
        return StatementInfo();
      });
      return CollectionElementResult(potentialReturnTypes);
    }
    compileForEachLoop(
      ctx,
      parts,
      iterable,
      null,
      body: (ctx, ert) {
        potentialReturnTypes.addAll(compileBody(e.body).types);
        return StatementInfo();
      },
      assignedNamesScan: [e],
    );
    return CollectionElementResult(potentialReturnTypes);
  } else if (parts is ForParts) {
    compileForLoop(
      ctx,
      parts,
      null,
      body: (ctx, ert) {
        potentialReturnTypes.addAll(compileBody(e.body).types);
        return StatementInfo();
      },
      assignedNamesScan: [e],
    );
  }

  return CollectionElementResult(potentialReturnTypes);
}
