import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
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
import '../values/value_rep.dart';
import '../invocation/accessors.dart';
import '../invocation/resolver.dart';

StatementInfo compileForStatement(
  ForStatement s,
  CompilerContext ctx,
  TypeRef? expectedReturnType,
) {
  final parts = s.forLoopParts;

  if (parts is ForEachParts) {
    final iterable = compileExpression(
      parts.iterable,
      ctx,
      forEachIterableBound(ctx, parts, await_: s.awaitKeyword != null),
    ).boxIfNeeded(ctx);
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
    return compileForEachLoop(
      ctx,
      parts,
      iterable,
      expectedReturnType,
      body: (ctx, ert) => compileStatement(s.body, ert, ctx),
      assignedNamesScan: [s],
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
          ctx.lookupBinding(variable.name.lexeme)!.renewCaptureCell(ctx);
        }
      }
      for (final u in parts.updaters) {
        compileExpressionAndDiscardResult(u, ctx);
      }
    },
  );
}

/// The context type for the iterable expression of `for (v in it)`:
/// `Iterable<T>` — or `Stream<T>` for `await for` — where `T` is the loop
/// variable's declared type (`dynamic` for `var`), so `.member` shorthands
/// and untyped collection literals in the iterable position resolve.
TypeRef forEachIterableBound(
  CompilerContext ctx,
  ForEachParts parts, {
  bool await_ = false,
}) {
  final elementType = switch (parts) {
    ForEachPartsWithDeclaration p when p.loopVariable.type != null =>
      TypeRef.fromAnnotation(ctx, ctx.library, p.loopVariable.type!),
    ForEachPartsWithIdentifier p => compileExpressionAsReference(
      p.identifier,
      ctx,
    ).resolveType(ctx),
    _ => null,
  };
  return (await_ ? CoreTypes.stream : CoreTypes.iterable)
      .ref(ctx)
      .copyWith(arguments: [elementType ?? CoreTypes.dynamic.ref(ctx)]);
}

/// Compiles the non-`await` form of `for (v in iterable)`: iterable type
/// check, iterator pump (`moveNext`/`current`), and loop-variable binding.
/// Shared by statements and collection `for` elements — [body] produces the
/// loop body.
StatementInfo compileForEachLoop(
  CompilerContext ctx,
  ForEachParts parts,
  Variable iterable,
  TypeRef? expectedReturnType, {
  required StatementInfo Function(CompilerContext, TypeRef?) body,
  List<AstNode> assignedNamesScan = const [],
}) {
  final itype = iterable.type;
  if (!itype.isAssignableTo(ctx, CoreTypes.iterable.ref(ctx))) {
    throw CompileError(
      'Cannot iterate over ${iterable.type}',
      parts,
      ctx.library,
      ctx,
    );
  }

  final elementType = itype.typeArguments.isEmpty
      ? CoreTypes.dynamic.ref(ctx)
      : itype.typeArguments[0];

  var iterator = GetTarget.read(ctx, iterable, 'iterator');
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
          type: CoreTypes.iterator.ref(ctx).copyWith(arguments: [elementType]),
        );

        final name = parts.loopVariable.name.lexeme;
        final bindingType = parts.loopVariable.type == null
            ? elementType
            : declaredType;
        ctx
            .setLocal(
              name,
              BuiltinValue()
                  .push(ctx)
                  .copyWith(
                    type: elementType,
                    declaredType: bindingType,
                    rep: ValueRep.boxed,
                  ),
            )
            .captureBinding(ctx, parts.loopVariable);
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
    condition: (ctx) =>
        CallResolver(ctx).invokeOperator(iterator, 'moveNext', []).result,
    body: body,
    assignedNamesScan: assignedNamesScan,
    update: (ctx) {
      if (parts is ForEachPartsWithDeclaration) {
        ctx
            .lookupBinding(parts.loopVariable.name.lexeme)!
            .renewCaptureCell(ctx);
      }
      loopVariable.setValue(ctx, GetTarget.read(ctx, iterator, 'current'));
    },
    updateBeforeBody: true,
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
  TypeRef? expectedReturnType,
  StatementInfo Function(CompilerContext, TypeRef?) body,
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
    throw CompileError('await for can only be used in an async function', node);
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
  final elementType = itype.typeArguments.isEmpty
      ? CoreTypes.dynamic.ref(ctx)
      : itype.typeArguments[0];
  final itType = AsyncTypes.streamIterator.ref(ctx);
  final externalId =
      ctx.bridgeStaticFunctionIndices[itType.file]!['StreamIterator.']!;
  final ssa = ctx.svar('stream_iterator');
  ctx.pushOp(InvokeExternal(ssa, externalId, [stream.ssa]));
  final iterator = Variable.of(
    ctx,
    ssa,
    itType.copyWith(arguments: [elementType]),
    rep: ValueRep.boxed,
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
        ctx
            .setLocal(
              name,
              BuiltinValue()
                  .push(ctx)
                  .copyWith(
                    type: elementType,
                    declaredType: bindingType,
                    rep: ValueRep.boxed,
                  ),
            )
            .captureBinding(ctx, parts.loopVariable);
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
      final moveNext = CallResolver(
        ctx,
      ).invokeOperator(iterator, 'moveNext', []).result;
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
            .lookupBinding(parts.loopVariable.name.lexeme)!
            .renewCaptureCell(ctx);
      }
      loopVariable.setValue(ctx, GetTarget.read(ctx, iterator, 'current'));
    },
    updateBeforeBody: true,
    after: (ctx) {
      CallResolver(ctx).invokeOperator(iterator, 'cancel', []);
    },
  );
}
