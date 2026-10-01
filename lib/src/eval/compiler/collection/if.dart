import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/collection/list.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/pattern_condition.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'element_result.dart';

CollectionElementResult compileIfElementForList(
  IfElement e,
  Variable list,
  CompilerContext ctx,
  bool box,
) => compileIfElement(
  e,
  ctx,
  (element) => compileListElement(element, list, ctx, box),
);

/// Compiles a collection `if` element, dispatching its then/else elements
/// through [compileBody] and returning every type they may produce.
CollectionElementResult compileIfElement(
  IfElement e,
  CompilerContext ctx,
  CollectionElementResult Function(CollectionElement) compileBody,
) {
  final potentialReturnTypes = <TypeRef>[];
  final elseElement = e.elseElement;
  final caseClause = e.caseClause;
  final subject = caseClause == null
      ? null
      : compileExpression(e.expression, ctx);
  final caseValue = subject?.copyIntoFreshSlot(ctx, 'case_value');
  var thenCompletes = true;
  var elseCompletes = true;

  macroBranch(
    ctx,
    null,
    conditionExpression: caseClause == null ? e.expression : null,
    conditionGraph: caseClause == null
        ? null
        : (ctx, yes, no) => compilePatternCondition(
            ctx,
            caseClause.guardedPattern,
            caseValue!,
            yes,
            no,
            source: e.expression,
          ),
    thenBranch: (ctx, _) {
      final result = compileBody(e.thenElement);
      potentialReturnTypes.addAll(result.types);
      thenCompletes = result.completesNormally;
      return StatementInfo();
    },
    elseBranch: elseElement == null
        ? null
        : (ctx, _) {
            final result = compileBody(elseElement);
            potentialReturnTypes.addAll(result.types);
            elseCompletes = result.completesNormally;
            return StatementInfo();
          },
  );

  return CollectionElementResult(
    potentialReturnTypes,
    completesNormally: thenCompletes || elseCompletes,
  );
}
