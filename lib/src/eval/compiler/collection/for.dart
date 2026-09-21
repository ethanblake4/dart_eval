import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/collection/list.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/macros/loop.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
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
    final itype = iterable.type;
    if (!itype.isAssignableTo(ctx, CoreTypes.iterable.ref(ctx))) {
      throw CompileError(
        'Cannot iterate over ${iterable.type}',
        parts,
        ctx.library,
        ctx,
      );
    }

    final elementType = itype.specifiedTypeArgs.isEmpty
        ? CoreTypes.dynamic.ref(ctx)
        : itype.specifiedTypeArgs[0];

    var iterator = iterable.getProperty(ctx, 'iterator');
    late Reference loopVariable;

    macroLoop(
      ctx,
      null,
      initialization: (ctx) {
        if (parts is ForEachPartsWithDeclaration) {
          final declaredType = parts.loopVariable.type == null
              ? CoreTypes.dynamic.ref(ctx)
              : TypeRef.fromAnnotation(
                  ctx,
                  ctx.library,
                  parts.loopVariable.type!,
                );
          if (parts.loopVariable.type != null &&
              !elementType.isAssignableTo(ctx, declaredType)) {
            throw CompileError(
              'Cannot assign $elementType to ${parts.loopVariable.type}',
              parts,
              ctx.library,
              ctx,
            );
          }
          iterator = iterator.copyWith(
            type: CoreTypes.iterator
                .ref(ctx)
                .copyWith(
                  specifiedTypeArgs: [elementType.copyWith(boxed: true)],
                ),
          );
          final name = parts.loopVariable.name.lexeme;
          final bindingType = parts.loopVariable.type == null
              ? elementType
              : declaredType;
          ctx.setLocal(
            name,
            BuiltinValue()
                .push(ctx)
                .copyWith(type: elementType, declaredType: bindingType)
                .captureBinding(ctx, parts.loopVariable),
          );
          loopVariable = IdentifierReference(null, name);
        } else if (parts is ForEachPartsWithIdentifier) {
          loopVariable = compileExpressionAsReference(parts.identifier, ctx);
          final type = loopVariable.resolveType(ctx);
          if (!elementType.isAssignableTo(ctx, type)) {
            throw CompileError(
              'Cannot assign $elementType to $type',
              parts,
              ctx.library,
              ctx,
            );
          }
        }
      },
      condition: (ctx) => iterator.invoke(ctx, 'moveNext', []).result,
      body: (ctx, ert) {
        potentialReturnTypes.addAll(compileBody(e.body));
        return StatementInfo();
      },
      update: (ctx) =>
          loopVariable.setValue(ctx, iterator.getProperty(ctx, 'current')),
      updateBeforeBody: true,
    );
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
