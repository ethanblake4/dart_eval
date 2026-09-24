import '../helpers/captures.dart';
import '../member/call_signature.dart';
import '../member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/variable/binding.dart';
import '../helpers/default_value.dart';
import '../../ir/function.dart' as function_ir;
import '../../ir/representation.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/async.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import '../invocation/deferred.dart';

import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/closures.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import '../values/abi.dart';

Variable compileFunctionExpression(
  FunctionExpression e,
  CompilerContext ctx, [
  TypeRef? bound,
]) {
  final ctxSaveState = ctx.saveState();
  final outerLabels = [...ctx.labels];
  final outerExceptions = [...ctx.caughtExceptionTargets];
  ctx.labels.clear();
  ctx.caughtExceptionTargets.clear();
  final outerGraph = ctx.activeGraph;
  final outerFunctionId = ctx.currentFunctionId;
  final outerFunctionLabel = ctx.funcLabel;
  final outerExceptionDepth = ctx.exceptionDepth;
  final captures = <String, Variable>{};
  final analysis = capturesFor(e);
  final freeNames = {...?analysis.free[e]};
  if (ctx.currentClass != null && ctx.lookupLocal('#this') != null) {
    for (final name in analysis.unresolved[e] ?? <String>{}) {
      final selfDecl = ctx.types.find(ctx.library, ctx.currentClassName!);
      if (selfDecl != null &&
          (ctx.memberLookup.tryInterfaceMember(
                    selfDecl.thisType,
                    MemberName(name, MemberKind.getter),
                  ) !=
                  null ||
              ctx.memberLookup.tryInterfaceMember(
                    selfDecl.thisType,
                    MemberName(name, MemberKind.setter),
                  ) !=
                  null)) {
        freeNames.add('#this');
      }
    }
  }
  if (ctx.anonymousThisReceiver != null && ctx.lookupLocal('#this') != null) {
    // Inside an anonymous-method body any unresolved name may be a member
    // of the anonymous receiver, which lives in `#this`.
    if ((analysis.unresolved[e] ?? const <String>{}).isNotEmpty) {
      freeNames.add('#this');
    }
  }
  if (ctx.currentExtension != null && ctx.lookupLocal('#this') != null) {
    // Inside an extension body any unresolved name may be an instance
    // member of the extension itself, which is invoked on `#this`.
    if ((analysis.unresolved[e] ?? const <String>{}).isNotEmpty) {
      freeNames.add('#this');
    }
  }
  for (final name in freeNames) {
    final binding = ctx.lookupLocal(name);
    if (binding != null) captures[name] = binding;
  }
  ctx.finishMethod();
  final outerBuilder = ctx.builder;
  final fnOffset = ctx.beginFunction('<anonymous closure>');
  TypeRef? inferredClosureReturnType;
  final typeParameters =
      e.typeParameters?.typeParameters ?? const <TypeParameter>[];
  ctx.withTypeParameters(
    ctx.library,
    TypeParameterOwner(
      TypeParameterOwnerKind.closure,
      ctx.library,
      '<anonymous>',
      fnOffset,
    ),
    typeParameters,
    () {
      ctx.functionTypeParameterBounds[fnOffset] = [
        for (final parameter in typeParameters)
          (ctx.typeScopes[ctx.library]![parameter.name.lexeme]!
                      as TypeParameterTypeRef)
                  .parameter
                  .bound ??
              CoreTypes.dynamic.ref(ctx),
      ];

      ctx.locals = [];
      ctx.exceptionDepth = 0;
      ctx.beginScope();
      ctx.pushOp(
        function_ir.Parameter(
          SSA('arg_0'),
          0,
          representation: MachineRepresentation.object,
        ),
      );
      var captureIndex = 0;
      for (final capture in captures.entries) {
        final loaded = ctx.svar('capture');
        ctx.pushOp(LoadCapture(loaded, captureIndex++));
        final lb = ctx.setLocal(
          capture.key,
          Variable.of(
            ctx,
            loaded,
            capture.value.type,
            rep: capture.value.rep,
            isFinal: capture.value.isFinal,
            callable: capture.value.callable,
          ),
        );
        if (capture.value.binding?.captureCell != null) {
          lb.storage = CaptureCellStorage(loaded);
        }
      }
      final resolvedParams = resolveFPLDefaults(
        ctx,
        e.parameters,
        false,
        allowUnboxed: false,
        sortNamed: true,
        parameterOffset: 1,
      );

      var boundPositionalParams = const <TypeRef>[];
      var boundNamedParams = const <TypeRef>[];
      if (bound is FunctionTypeRef) {
        boundPositionalParams = bound.signature.positional;
        boundNamedParams = [
          for (final entry in bound.signature.named.entries.sorted(
            (a, b) => a.key.compareTo(b.key),
          ))
            entry.value.type,
        ];
      }
      final inorderBoundParams = [
        ...boundPositionalParams,
        ...boundNamedParams,
      ];

      var i = 0;

      for (final p in resolvedParams) {
        Variable vRep;

        TypeRef type = CoreTypes.dynamic.ref(ctx);
        if (p.type != null) {
          type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
        } else if (i < inorderBoundParams.length) {
          type = inorderBoundParams[i];
        }
        vRep = Variable.of(
          ctx,
          SSA('arg_${i + 1}'),
          type,
          rep: Abi.parameter(type, CallableKind.closure),
        );

        // `_` parameters are wildcards: non-binding and repeatable.
        if (p.name!.lexeme != '_') {
          ctx.setLocal(p.name!.lexeme, vRep).captureBinding(ctx, p);
        }

        i++;
      }

      ctx.functionSignatures[fnOffset] = MachineFunctionSignature(
        List.filled(resolvedParams.length + 1, MachineRepresentation.object),
        MachineRepresentation.object,
      );
      final b = e.body;

      // The closure body's context type is the bound function type's return
      // type — `Color Function() f = () => .red` resolves `.red` under `Color`.
      // Local function declarations (`Color f() => ...`) carry the return type
      // on their parent declaration instead.
      final declaredReturnType = switch (e.parent) {
        FunctionDeclaration(:final returnType?) => TypeRef.fromAnnotation(
          ctx,
          ctx.library,
          returnType,
        ),
        _ => null,
      };
      final boundSignature = bound is FunctionTypeRef ? bound.signature : null;
      final boundReturnType = boundSignature?.returnType ?? declaredReturnType;

      // Block-bodied closures collect the static type of each `return` so the
      // closure's return type can be inferred (`asyncClosureReturnTypes` serves
      // sync closures too despite the name).
      final collectsReturns = b.isAsynchronous || b is BlockFunctionBody;
      if (b.isAsynchronous) {
        setupAsyncFunction(ctx, returnType: boundReturnType);
      }
      if (collectsReturns) {
        ctx.asyncClosureReturnTypes.add(<TypeRef>[]);
      }

      StatementInfo? stInfo;
      ctx.closureDepth++;
      try {
        if (b is BlockFunctionBody) {
          stInfo = compileBlock(
            b.block,
            boundReturnType ?? CoreTypes.dynamic.ref(ctx),
            ctx,
            name: '(closure)',
          );
        } else if (b is ExpressionFunctionBody) {
          ctx.beginScope();
          final V = compileExpression(b.expression, ctx, boundReturnType);
          inferredClosureReturnType = V.type;
          stInfo = doReturn(
            ctx,
            CoreTypes.dynamic.ref(ctx),
            V,
            isAsync: b.isAsynchronous,
          );
          ctx.endScope();
        } else {
          throw CompileError(
            'Unsupported function body type: ${b.runtimeType}',
          );
        }
      } finally {
        ctx.closureDepth--;
      }

      if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
        if (b.isAsynchronous) {
          asyncComplete(ctx, null);
          ctx.endScope();
        } else {
          ctx.endScope();
          ctx.pushOp(Return(null));
        }
        // Implicit fall-through contributes `Null` to the inferred return type.
        if (collectsReturns) {
          ctx.asyncClosureReturnTypes.last.add(CoreTypes.nullType.ref(ctx));
        }
      }

      if (collectsReturns) {
        final returns = ctx.asyncClosureReturnTypes.removeLast();
        final inferred =
            inferredClosureReturnType ??
            (returns.isEmpty
                ? CoreTypes.nullType.ref(ctx)
                : returns.every((t) => t == returns.first)
                ? returns.first
                : TypeRef.commonBaseType(ctx, returns.toSet()));
        inferredClosureReturnType = b.isAsynchronous
            ? CoreTypes.future
                  .ref(ctx)
                  .copyWith(arguments: [ctx.typeSystem.flatten(inferred)])
            : inferred;
      }

      ctx.finishMethod();
      ctx.activeGraph = outerGraph;
      ctx.builder = outerBuilder;
      ctx.currentFunctionId = outerFunctionId;
      ctx.funcLabel = outerFunctionLabel;
      ctx.hasBegunMethod = true;
      ctx.exceptionDepth = outerExceptionDepth;

      ctx.labels.addAll(outerLabels);
      ctx.caughtExceptionTargets.addAll(outerExceptions);
      ctx.restoreState(ctxSaveState);
    },
  );

  final positional =
      (e.parameters?.parameters.where((element) => element.isPositional) ?? []);
  final requiredPositionalArgCount = positional
      .where((element) => element.isRequired)
      .length;

  final named =
      (e.parameters?.parameters.where((element) => element.isNamed) ?? []);
  final sortedNamedArgs = named.toList()
    ..sort((e1, e2) => (e1.name!.lexeme).compareTo((e2.name!.lexeme)));
  final sortedNamedArgNames = sortedNamedArgs
      .map((e) => e.name!.lexeme)
      .toList();

  (Object?, int) parameterDefault(FormalParameter parameter) {
    final (value, thunk) = compileParameterDefault(ctx, ctx.library, parameter);
    final annotation = parameter.type;
    if (value is int &&
        annotation != null &&
        TypeRef.fromAnnotation(
          ctx,
          ctx.library,
          annotation,
        ).isSpec(CoreTypes.double)) {
      return (value.toDouble(), thunk);
    }
    return (value, thunk);
  }

  final target = DeferredOrOffset(offset: fnOffset);
  // A function literal's own type is never nullable, even when its context
  // type is (for example when assigned to `void Function(int)?`). Reifying
  // the context's nullability would poison every later subtype check.
  TypeRef literalParameterType(FormalParameter parameter) {
    final annotation = parameter.type;
    return annotation == null
        ? CoreTypes.dynamic.ref(ctx)
        : TypeRef.fromAnnotation(ctx, ctx.library, annotation);
  }

  // A context signature still holding type-parameter refs (`void
  // Function(X)` inside a generic call's binding) can't stand in as the
  // closure's own type: the literal's annotated parameters decide the
  // argument type upward inference sees.
  bool boundContainsTypeParameter(TypeRef t) =>
      t.isTypeParameter ||
      (t is FunctionTypeRef &&
          (t.signature.positional.any(boundContainsTypeParameter) ||
              t.signature.named.values.any(
                (e) => boundContainsTypeParameter(e.type),
              ) ||
              boundContainsTypeParameter(t.signature.returnType))) ||
      interfaceArgumentsOf(t).any(boundContainsTypeParameter);
  final boundIsParametricSignature =
      bound is FunctionTypeRef && boundContainsTypeParameter(bound);

  var closureType = bound is! FunctionTypeRef || boundIsParametricSignature
      ? e.typeParameters == null
            ? FunctionTypeRef(
                FunctionSignature(
                  positional: [
                    for (final p in positional)
                      if (p.isRequired) literalParameterType(p),
                    for (final p in positional)
                      if (!p.isRequired) literalParameterType(p),
                  ],
                  requiredPositional: requiredPositionalArgCount,
                  named: {
                    for (final p in sortedNamedArgs)
                      p.name!.lexeme: (
                        type: literalParameterType(p),
                        required: p.isRequired,
                      ),
                  },
                  returnType:
                      inferredClosureReturnType ?? CoreTypes.dynamic.ref(ctx),
                ),
                decl: ctx.types.bySpec(CoreTypes.function),
              )
            : CoreTypes.function.ref(ctx)
      : bound.withNullable(false);
  if (closureType is FunctionTypeRef && inferredClosureReturnType != null) {
    // Replace a placeholder return — `dynamic`, or a type parameter (a
    // bridge `S Function(E)` gives the closure a param-typed return) —
    // with the inferred type.
    final signature = closureType.signature;
    final shouldInfer =
        signature.returnType.isSpec(CoreTypes.dynamic) ||
        signature.returnType.isTypeParameter;
    if (shouldInfer) {
      closureType = FunctionTypeRef(
        FunctionSignature(
          typeParameters: signature.typeParameters,
          positional: signature.positional,
          requiredPositional: signature.requiredPositional,
          named: signature.named,
          returnType: inferredClosureReturnType!,
        ),
        decl: closureType.decl,
        nullable: closureType.nullable,
      );
    }
  }
  final positionalDefaults = positional.map(parameterDefault).toList();
  final namedDefaults = sortedNamedArgs.map(parameterDefault).toList();
  return Variable.ssa(
    ctx,
    CreateClosure(
      ctx.svar('closure'),
      target,
      captures.values.map((v) => v.binding?.captureCell ?? v.ssa).toList(),
      requiredPositional: requiredPositionalArgCount,
      positionalCount: positional.length,
      namedNames: sortedNamedArgNames,
      positionalDefaults: [for (final d in positionalDefaults) d.$1],
      namedDefaults: [for (final d in namedDefaults) d.$1],
      defaultThunks: [
        for (final d in positionalDefaults) d.$2,
        for (final d in namedDefaults) d.$2,
      ],
      requiredNamed: [
        for (final parameter in sortedNamedArgs)
          if (parameter.isRequired) parameter.name!.lexeme,
      ],
      runtimeTypeId: ctx.runtimeTypes.idOf(closureType),
    ),
    closureType,
    callable: CallableValue(
      offset: target,
      signature: CallSignature.returnOnly(
        inferredClosureReturnType ?? CoreTypes.dynamic.ref(ctx),
      ),
      convention: CallingConvention.dynamic,
      materialized: true,
    ),
  );
}
