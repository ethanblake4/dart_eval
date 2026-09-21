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
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/async.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';

StatementInfo compileForStatement(
  ForStatement s,
  CompilerContext ctx,
  AlwaysReturnType? expectedReturnType,
) {
  final parts = s.forLoopParts;

  if (parts is ForEachParts) {
    final iterable = compileExpression(parts.iterable, ctx).boxIfNeeded(ctx);
    final itype = iterable.type;
    if (s.awaitKeyword != null) {
      return compileAwaitForLoop(
        ctx,
        s,
        parts,
        iterable,
        expectedReturnType,
        (ctx, ert) => compileStatement(s.body, ert, ctx),
      );
    }
    if (!itype.isAssignableTo(ctx, CoreTypes.iterable.ref(ctx))) {
      throw CompileError(
        'Cannot iterate over ${iterable.type}',
        parts,
        ctx.library,
        ctx,
      );
    }

    var elementType = itype.specifiedTypeArgs.isEmpty
        ? CoreTypes.dynamic.ref(ctx)
        : itype.specifiedTypeArgs[0];

    var iterator = iterable.getProperty(ctx, 'iterator');
    late Reference loopVariable;

    return macroLoop(
      ctx,
      expectedReturnType,
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
      body: (ctx, ert) => compileStatement(s.body, ert, ctx),
    assignedNamesScan: [s],
      update: (ctx) {
        if (parts is ForEachPartsWithDeclaration) {
          ctx
              .lookupLocal(parts.loopVariable.name.lexeme)!
              .renewCaptureCell(ctx);
        }
        loopVariable.setValue(ctx, iterator.getProperty(ctx, 'current'));
      },
      updateBeforeBody: true,
    );
  }

  parts as ForParts;

  return macroLoop(
    ctx,
    expectedReturnType,
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
    body: (ctx, ert) => compileStatement(s.body, ert, ctx),
    assignedNamesScan: [s],
    update: (ctx) {
      if (parts is ForPartsWithDeclarations) {
        for (final variable in parts.variables.variables) {
          ctx.lookupLocal(variable.name.lexeme)!.renewCaptureCell(ctx);
        }
      }
      for (final u in parts.updaters) {
        compileExpressionAndDiscardResult(u, ctx);
      }
    },
  );
}

/// Compiles `await for (v in stream)` as a [StreamIterator] loop:
/// `while (await it.moveNext()) { v = it.current; body }`, cancelling the
/// subscription when the loop exits (including via `break`). [node] is the
/// enclosing statement or collection element, used to locate the enclosing
/// async function.
StatementInfo compileAwaitForLoop(
  CompilerContext ctx,
  AstNode node,
  ForEachParts parts,
  Variable stream,
  AlwaysReturnType? expectedReturnType,
  StatementInfo Function(CompilerContext, AlwaysReturnType?) body,
) {
  AstNode? enclosing = node;
  while (enclosing is! FunctionBody) {
    enclosing = enclosing?.parent;
    if (enclosing == null) {
      throw CompileError(
        'await for can only be used in an async function',
        node,
      );
    }
  }
  if (!enclosing.isAsynchronous) {
    throw CompileError(
      'await for can only be used in an async function',
      node,
    );
  }
  final itype = stream.type;
  if (!itype.isAssignableTo(ctx, CoreTypes.stream.ref(ctx))) {
    throw CompileError(
      'Cannot iterate over ${stream.type} as a Stream',
      parts,
      ctx.library,
      ctx,
    );
  }
  final elementType = itype.specifiedTypeArgs.isEmpty
      ? CoreTypes.dynamic.ref(ctx)
      : itype.specifiedTypeArgs[0];
  final itType = AsyncTypes.streamIterator.ref(ctx);
  final externalId =
      ctx.bridgeStaticFunctionIndices[itType.file]!['StreamIterator.']!;
  final ssa = ctx.svar('stream_iterator');
  ctx.pushOp(InvokeExternal(ssa, externalId, [stream.ssa]));
  final iterator = Variable.of(
    ctx,
    ssa,
    itType.copyWith(specifiedTypeArgs: [elementType], boxed: true),
  );
  final completer = ctx.lookupLocal('#completer')!;
  late Reference loopVariable;

  return macroLoop(
    ctx,
    expectedReturnType,
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
    condition: (ctx) {
      final moveNext = iterator.invoke(ctx, 'moveNext', []).result;
      return Variable.ssa(
        ctx,
        Await(
          ctx.svar('awaitfor_next'),
          completer.ssa,
          moveNext.boxIfNeeded(ctx).ssa,
        ),
        CoreTypes.bool.ref(ctx),
      );
    },
    body: body,
    assignedNamesScan: [node],
    update: (ctx) {
      if (parts is ForEachPartsWithDeclaration) {
        ctx
            .lookupLocal(parts.loopVariable.name.lexeme)!
            .renewCaptureCell(ctx);
      }
      loopVariable.setValue(ctx, iterator.getProperty(ctx, 'current'));
    },
    updateBeforeBody: true,
    after: (ctx) {
      iterator.invoke(ctx, 'cancel', []);
    },
  );
}
