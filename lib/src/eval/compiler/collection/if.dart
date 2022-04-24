import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/collection/list.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

List<TypeRef> compileIfElementForList(
    IfElement e, Variable list, CompilerContext ctx, bool box) {
  final potentialReturnTypes = <TypeRef>[];
  final elseElement = e.elseElement;

  macroBranch(ctx, null,
      condition: (_ctx) => compileExpression(e.condition, _ctx),
      thenBranch: (_ctx, _) {
        potentialReturnTypes
            .addAll(compileListElement(e.thenElement, list, _ctx, box));
        return StatementInfo(-1);
      },
      elseBranch: elseElement == null
          ? null
          : (_ctx, _) {
              potentialReturnTypes
                  .addAll(compileListElement(elseElement, list, _ctx, box));
              return StatementInfo(-1);
            });

  return potentialReturnTypes;
}
