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
import 'package:dart_eval/src/eval/ir/alu.dart';
import 'package:dart_eval/src/eval/ir/async.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import '../values/value_rep.dart';
import '../variable/binding.dart';
import '../macros/branch.dart';
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

  return compileForLoop(
    ctx,
    parts as ForParts,
    expectedReturnType,
    body: (ctx, ert) => compileStatement(s.body, ert, ctx),
    assignedNamesScan: [s],
  );
}

/// Shares loop-variable capture renewal between statements and collections.
StatementInfo compileForLoop(
  CompilerContext ctx,
  ForParts parts,
  TypeRef? expectedReturnType, {
  required StatementInfo Function(CompilerContext, TypeRef?) body,
  required Iterable<AstNode> assignedNamesScan,
}) {
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
    body: body,
    assignedNamesScan: assignedNamesScan,
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

  final elementType = interfaceArgumentsOf(itype).isEmpty
      ? CoreTypes.dynamic.ref(ctx)
      : interfaceArgumentsOf(itype)[0];

  // Index pump for natively-held collections: each element is an index
  // read instead of `moveNext` + `current` bridge calls. Mutation during
  // iteration follows index semantics, not the iterator protocol's
  // concurrent-modification check.
  final iterableRep = unboxedRepOf(itype);
  if (iterableRep == ValueRep.nativeList || iterableRep == ValueRep.nativeSet) {
    StatementInfo indexForEach(CompilerContext ctx, TypeRef? ert) =>
        _compileIndexForEach(
          ctx,
          parts,
          iterable,
          elementType,
          ert,
          body: body,
          assignedNamesScan: assignedNamesScan,
        );
    if (iterable.boxed) {
      // A boxed value promoted to `List`/`Set` can still be an
      // evaluated-class implementation — VM-check the storage once and
      // fall back to the iterator protocol for non-natives.
      return macroBranch(
        ctx,
        expectedReturnType,
        condition: (ctx) => Variable.ssa(
          ctx,
          iterableRep == ValueRep.nativeSet
              ? IsNativeSet(ctx.svar('is_native'), iterable.ssa)
              : IsNativeList(ctx.svar('is_native'), iterable.ssa),
          CoreTypes.bool.ref(ctx),
          rep: ValueRep.bool,
        ),
        thenBranch: indexForEach,
        elseBranch: (ctx, ert) => _compileIteratorForEach(
          ctx,
          parts,
          iterable,
          elementType,
          ert,
          body: body,
          assignedNamesScan: assignedNamesScan,
        ),
      );
    }
    return indexForEach(ctx, expectedReturnType);
  }

  return _compileIteratorForEach(
    ctx,
    parts,
    iterable,
    elementType,
    expectedReturnType,
    body: body,
    assignedNamesScan: assignedNamesScan,
  );
}

/// `for-in` through the `iterator`/`moveNext`/`current` protocol — the
/// generic path for iterables that aren't provably native collections.
StatementInfo _compileIteratorForEach(
  CompilerContext ctx,
  ForEachParts parts,
  Variable iterable,
  TypeRef elementType,
  TypeRef? expectedReturnType, {
  required StatementInfo Function(CompilerContext, TypeRef?) body,
  List<AstNode> assignedNamesScan = const [],
}) {
  var iterator = GetTarget.read(ctx, iterable, 'iterator');
  late Reference loopVariable;

  return macroLoop(
    ctx,
    expectedReturnType,
    initialization: (ctx) {
      loopVariable = _declareForEachVariable(ctx, parts, elementType);
      if (parts is ForEachPartsWithDeclaration) {
        iterator = iterator.copyWith(
          type: CoreTypes.iterator.ref(ctx).copyWith(arguments: [elementType]),
        );
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
  final elementType = interfaceArgumentsOf(itype).isEmpty
      ? CoreTypes.dynamic.ref(ctx)
      : interfaceArgumentsOf(itype)[0];
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
                  .copyWith(type: elementType, rep: ValueRep.boxed),
              declaredType: bindingType,
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

/// Declares the `for-in` loop variable (or resolves the assignment target
/// for an identifier loop) and returns the reference each iteration writes.
Reference _declareForEachVariable(
  CompilerContext ctx,
  ForEachParts parts,
  TypeRef elementType,
) {
  if (parts is ForEachPartsWithDeclaration) {
    final declaredType = parts.loopVariable.type == null
        ? CoreTypes.dynamic.ref(ctx)
        : TypeRef.fromAnnotation(ctx, ctx.library, parts.loopVariable.type!);
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
              .copyWith(type: elementType, rep: ValueRep.boxed),
          declaredType: bindingType,
        )
        .captureBinding(ctx, parts.loopVariable);
    return IdentifierReference(null, name);
  }
  if (parts is ForEachPartsWithIdentifier) {
    final loopVariable = compileExpressionAsReference(parts.identifier, ctx);
    final type = loopVariable.resolveType(ctx);
    if (!elementType.isAssignableTo(ctx, type)) {
      throw CompileError(
        'Cannot assign $elementType to $type',
        parts,
        ctx.library,
        ctx,
      );
    }
    return loopVariable;
  }
  throw StateError('Unsupported for-in parts $parts');
}

/// `for-in` over a natively-held `List`/`Set`: an index pump in place of
/// the `iterator`/`moveNext`/`current` protocol calls.
StatementInfo _compileIndexForEach(
  CompilerContext ctx,
  ForEachParts parts,
  Variable iterable,
  TypeRef elementType,
  TypeRef? expectedReturnType, {
  required StatementInfo Function(CompilerContext, TypeRef?) body,
  List<AstNode> assignedNamesScan = const [],
}) {
  final intType = CoreTypes.int.ref(ctx);
  final unboxed = iterable.unboxIfNeeded(ctx, false);
  // A set's elements aren't indexable — pump a materialized list instead.
  final elements = unboxedRepOf(iterable.type) == ValueRep.nativeSet
      ? Variable.ssa(
          ctx,
          SetToList(ctx.svar('for_each_set'), unboxed.ssa),
          iterable.type,
        )
      : unboxed;
  final length = Variable.ssa(
    ctx,
    ListLength(ctx.svar('for_each_length'), elements.ssa),
    intType,
    rep: ValueRep.int,
  );
  late LocalBinding index;
  late Reference loopVariable;

  return macroLoop(
    ctx,
    expectedReturnType,
    initialization: (ctx) {
      loopVariable = _declareForEachVariable(ctx, parts, elementType);
      index = ctx.setLocal(
        '#forIndex',
        BuiltinValue().push(ctx).copyWith(type: intType, rep: ValueRep.int),
        declaredType: intType,
      );
      index.write(
        ctx,
        Variable.ssa(
          ctx,
          LoadInt(ctx.svar('for_index_init'), 0),
          intType,
          rep: ValueRep.int,
        ),
      );
    },
    condition: (ctx) => Variable.ssa(
      ctx,
      IntLessThan(ctx.svar('for_each_cond'), index.read(ctx).ssa, length.ssa),
      CoreTypes.bool.ref(ctx),
      rep: ValueRep.bool,
    ),
    body: (ctx, ert) {
      if (parts is ForEachPartsWithDeclaration) {
        ctx
            .lookupBinding(parts.loopVariable.name.lexeme)!
            .renewCaptureCell(ctx);
      }
      loopVariable.setValue(
        ctx,
        Variable.ssa(
          ctx,
          IndexList(
            ctx.svar('for_each_element'),
            elements.ssa,
            index.read(ctx).ssa,
          ),
          elementType,
          rep: ValueRep.boxed,
        ),
      );
      return body(ctx, ert);
    },
    update: (ctx) {
      index.write(
        ctx,
        Variable.ssa(
          ctx,
          Increment(ctx.svar('for_index_next'), index.read(ctx).ssa),
          intType,
          rep: ValueRep.int,
        ),
      );
    },
    assignedNamesScan: assignedNamesScan,
  );
}
