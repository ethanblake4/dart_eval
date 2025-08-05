import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/macros/loop.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/statement/variable_declaration.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

StatementInfo compileForStatement(
    ForStatement s, CompilerContext ctx, AlwaysReturnType? expectedReturnType) {
  final parts = s.forLoopParts;

  if (parts is ForEachParts) {
    final iterable = compileExpression(parts.iterable, ctx).boxIfNeeded(ctx);
    final itype = iterable.type;
    if (!itype.isAssignableTo(ctx, CoreTypes.iterable.ref(ctx))) {
      throw CompileError(
          'Cannot iterate over ${iterable.type}', parts, ctx.library, ctx);
    }

    var elementType = itype.specifiedTypeArgs.isEmpty
        ? CoreTypes.dynamic.ref(ctx)
        : itype.specifiedTypeArgs[0];

    var iterator = iterable.getProperty(ctx, 'iterator');
    late Reference loopVariable;

    return macroLoop(ctx, expectedReturnType,
        initialization: (ctx) {
          if (parts is ForEachPartsWithDeclaration) {
            final declaredType = parts.loopVariable.type == null
                ? CoreTypes.dynamic.ref(ctx)
                : TypeRef.fromAnnotation(
                    ctx, ctx.library, parts.loopVariable.type!);
            if (parts.loopVariable.type != null &&
                !elementType.isAssignableTo(ctx, declaredType)) {
              throw CompileError(
                  'Cannot assign $elementType to ${parts.loopVariable.type}',
                  parts,
                  ctx.library,
                  ctx);
            }

            if (itype.specifiedTypeArgs.isEmpty) {
              elementType = declaredType.copyWith(boxed: true);
            }

            iterator = iterator.copyWith(
                type: CoreTypes.iterator.ref(ctx).copyWith(
                    specifiedTypeArgs: [elementType.copyWith(boxed: true)]));

            final name = parts.loopVariable.name.lexeme;
            ctx.setLocal(
                name, BuiltinValue().push(ctx).copyWith(type: elementType));
            loopVariable = IdentifierReference(null, name);
          } else if (parts is ForEachPartsWithIdentifier) {
            loopVariable = compileExpressionAsReference(parts.identifier, ctx);
            final type = loopVariable.resolveType(ctx);
            if (!elementType.isAssignableTo(ctx, type)) {
              throw CompileError('Cannot assign $elementType to $type', parts,
                  ctx.library, ctx);
            }
          }
        },
        condition: (ctx) => iterator.invoke(ctx, 'moveNext', []).result,
        body: (ctx, ert) => compileStatement(s.body, ert, ctx),
        update: (ctx) =>
            loopVariable.setValue(ctx, iterator.getProperty(ctx, 'current')),
        updateBeforeBody: true);
  }

  parts as ForParts;

  return macroLoop(ctx, expectedReturnType,
      initialization: (ctx) {
        if (parts is ForPartsWithDeclarations) {
          compileVariableDeclarationList(parts.variables, ctx);
        } else if (parts is ForPartsWithExpression) {
          if (parts.initialization != null) {
            compileExpressionAndDiscardResult(parts.initialization!, ctx);
          }
        }
      },
      condition: parts.condition == null
          ? null
          : (ctx) => compileExpression(parts.condition!, ctx),
      body: (ctx, ert) => compileStatement(s.body, ert, ctx),
      update: (ctx) {
        for (final u in parts.updaters) {
          compileExpressionAndDiscardResult(u, ctx);
        }
      });
}
