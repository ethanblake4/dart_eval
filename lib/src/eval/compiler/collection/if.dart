import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/collection/list.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

List<TypeRef> compileIfElementForList(
  IfElement e,
  Variable list,
  CompilerContext ctx,
  bool box,
) =>
    compileIfElement(
      e,
      ctx,
      (element) => compileListElement(element, list, ctx, box),
    );

/// Compiles a collection `if` element, dispatching its then/else elements
/// through [compileBody] and returning every type they may produce.
List<TypeRef> compileIfElement(
  IfElement e,
  CompilerContext ctx,
  List<TypeRef> Function(CollectionElement) compileBody,
) {
  final potentialReturnTypes = <TypeRef>[];
  final elseElement = e.elseElement;

  macroBranch(
    ctx,
    null,
    conditionExpression: e.expression,
    thenBranch: (ctx, _) {
      potentialReturnTypes.addAll(compileBody(e.thenElement));
      return StatementInfo();
    },
    elseBranch: elseElement == null
        ? null
        : (ctx, _) {
            potentialReturnTypes.addAll(compileBody(elseElement));
            return StatementInfo();
          },
  );

  return potentialReturnTypes;
}
