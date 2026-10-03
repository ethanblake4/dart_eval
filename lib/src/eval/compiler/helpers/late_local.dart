import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:dart_eval/dart_eval_bridge.dart';
import '../context.dart';
import '../invocation/deferred.dart';
import '../expression/expression.dart';
import '../type.dart';
import '../variable.dart';
import '../variable/binding.dart';
import '../values/abi.dart';
import '../../ir/closures.dart';
import '../../ir/flow.dart';
import '../../ir/function.dart';
import '../../ir/representation.dart';
import 'captures.dart';
import 'conversion.dart';

/// A late initializer retains the original AST and lexical captures, just
/// like a source closure, while exposing a boxed zero-argument result.
(Variable, TypeRef, TypeRef) compileLateLocalInitializer(
  CompilerContext ctx,
  VariableDeclaration declaration,
  TypeRef? bound,
) {
  final analysis = capturesFor(declaration);
  final names = {...?analysis.free[declaration]};
  if (ctx.lookupBinding('#this') != null &&
      (analysis.unresolved[declaration]?.isNotEmpty ?? false)) {
    names.add('#this');
  }
  final captures = <String, LocalBinding>{
    for (final name in names)
      if (ctx.lookupBinding(name) case final binding?) name: binding,
  };
  final values = <String, Variable>{
    for (final entry in captures.entries)
      entry.key: entry.value.captureCell == null
          ? entry.value.current.boxIntoFreshSlot(ctx)
          : entry.value.current,
  };
  for (final name in analysis.writes[declaration] ?? const <String>{}) {
    ctx.applyWriteCapture(name);
  }
  final outer = NestedFunctionState(ctx);
  late int target;
  late TypeRef resultType;
  late TypeRef initializerType;
  try {
    ctx.labels.clear();
    ctx.caughtExceptionTargets.clear();
    ctx.finishMethod();
    outer.resumeAfterFlush();
    target = ctx.beginFunction('<late ${declaration.name.lexeme}>');
    ctx.locals = [];
    ctx.exceptionDepth = 0;
    ctx.beginScope();
    ctx.pushOp(
      Parameter(SSA('arg_0'), 0, representation: MachineRepresentation.object),
    );
    var index = 0;
    for (final entry in captures.entries) {
      final loaded = ctx.svar('late_capture');
      ctx.pushOp(LoadCapture(loaded, index++));
      final original = entry.value;
      final local = ctx.setLocal(
        entry.key,
        Variable.of(
          ctx,
          loaded,
          analysis.assignedDeclarations.contains(original.captureDeclaration)
              ? original.declaredType
              : original.current.type,
          rep: values[entry.key]!.rep,
          facts: original.current.facts,
        ),
        declaredType: original.declaredType,
        isFinal: original.isFinal,
        initialized: original.initialized,
      );
      local.current.writeEpoch = original.current.writeEpoch;
      local.writeCaptured = original.writeCaptured;
      local.captureDeclaration = original.captureDeclaration;
      if (original.isLateLocal) {
        local.storage = LateLocalStorage(loaded);
      } else if (original.captureCell != null) {
        local.storage = CaptureCellStorage(loaded);
      }
    }
    ctx.functionSignatures[target] = CallableAbi.closure(0).machine;
    ctx.lateInitializerDepth++;
    Variable result;
    try {
      result = compileExpression(declaration.initializer!, ctx, bound);
      initializerType = result.type;
      resultType = bound ?? ctx.typeFactory.widenedInferredType(result.type);
      result = convertForAssignment(
        ctx,
        result,
        resultType,
        representation: MachineRepresentation.object,
        source: declaration,
      );
    } finally {
      ctx.lateInitializerDepth--;
    }
    ctx.pushOp(Return(result.boxIfNeeded(ctx).ssa));
    ctx.endScope();
    ctx.finishMethod();
  } finally {
    outer.restore();
  }
  final closure = Variable.ssa(
    ctx,
    CreateClosure(
      ctx.svar('late_initializer'),
      DeferredOrOffset(offset: target),
      [
        for (final entry in captures.entries)
          entry.value.captureCell ?? values[entry.key]!.ssa,
      ],
    ),
    CoreTypes.function.ref(ctx),
    rep: ValueRep.boxed,
  );
  return (closure, resultType, initializerType);
}
