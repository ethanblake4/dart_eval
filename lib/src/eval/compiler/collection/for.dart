import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
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
    ForElement e, Variable list, CompilerContext ctx, bool box) {
  final potentialReturnTypes = <TypeRef>[];
  final parts = e.forLoopParts;

  if (parts is ForEachParts) {
    final iterable = compileExpression(parts.iterable, ctx).boxIfNeeded(ctx);
    final itype = iterable.type;
    if (!itype.isAssignableTo(ctx, CoreTypes.iterable.ref(ctx))) {
      throw CompileError(
          'Cannot iterate over ${iterable.type}', parts, ctx.library, ctx);
    }

    final elementType = itype.specifiedTypeArgs.isEmpty
        ? CoreTypes.dynamic.ref(ctx)
        : itype.specifiedTypeArgs[0];

    final iterator = iterable.getProperty(ctx, 'iterator');
    late Reference loopVariable;

    macroLoop(ctx, null,
        initialization: (_ctx) {
          if (parts is ForEachPartsWithDeclaration) {
            if (parts.loopVariable.type != null &&
                !elementType.isAssignableTo(
                    ctx,
                    TypeRef.fromAnnotation(
                        ctx, ctx.library, parts.loopVariable.type!))) {
              throw CompileError(
                  'Cannot assign $elementType to ${parts.loopVariable.type}',
                  parts,
                  ctx.library,
                  ctx);
            }
            final name = parts.loopVariable.name.lexeme;
            ctx.setLocal(
                name,
                BuiltinValue()
                    .push(ctx, SSA(name))
                    .copyWith(type: elementType));
            loopVariable = IdentifierReference(null, name);
          } else if (parts is ForEachPartsWithIdentifier) {
            loopVariable = compileExpressionAsReference(parts.identifier, ctx);
            final type = loopVariable.resolveType(ctx);
            if (!elementType.isAssignableTo(_ctx, type)) {
              throw CompileError('Cannot assign $elementType to $type', parts,
                  ctx.library, ctx);
            }
          }
        },
        condition: (_ctx) => iterator.invoke(_ctx, 'moveNext', []).result,
        body: (_ctx, ert) {
          potentialReturnTypes
              .addAll(compileListElement(e.body, list, _ctx, box));
          return StatementInfo(-1);
        },
        update: (ctx) =>
            loopVariable.setValue(ctx, iterator.getProperty(ctx, 'current')),
        updateBeforeBody: true);
  }

  parts as ForParts;

  macroLoop(ctx, null,
      initialization: (_ctx) {
        if (parts is ForPartsWithDeclarations) {
          compileVariableDeclarationList(parts.variables, _ctx);
        } else if (parts is ForPartsWithExpression) {
          if (parts.initialization != null) {
            compileExpressionAndDiscardResult(parts.initialization!, _ctx);
          }
        }
      },
      condition: parts.condition == null
          ? null
          : (_ctx) => compileExpression(parts.condition!, _ctx),
      body: (_ctx, ert) {
        potentialReturnTypes
            .addAll(compileListElement(e.body, list, _ctx, box));
        return StatementInfo(-1);
      },
      update: (_ctx) {
        for (final u in parts.updaters) {
          compileExpressionAndDiscardResult(u, _ctx);
        }
      });

  return potentialReturnTypes;
}
