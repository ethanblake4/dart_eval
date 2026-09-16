import 'identifier.dart' show resolveInstanceDeclaration;
import '../helpers/captures.dart';
import '../helpers/default_value.dart';
import '../../ir/function.dart' as function_ir;
import '../../ir/representation.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/model/function_type.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/util.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/closures.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

enum CallingConvention { static, dynamic }

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
  final sfo = ctx.scopeFrameOffset;
  final outerGraph = ctx.activeGraph;
  final outerFunctionId = ctx.currentFunctionId;
  final outerFunctionLabel = ctx.funcLabel;
  final outerAsyncFrame = ctx.nearestAsyncFrame;
  final outerEntrypoint = ctx.entrypoint;
  final outerExceptionDepth = ctx.exceptionDepth;
  final captures = <String, Variable>{};
  final analysis = capturesFor(e);
  final freeNames = {...?analysis.free[e]};
  if (ctx.currentClass != null && ctx.lookupLocal('#this') != null) {
    for (final name in analysis.unresolved[e] ?? <String>{}) {
      if (resolveInstanceDeclaration(
            ctx,
            ctx.library,
            ctx.currentClass!.name.lexeme,
            name,
          ) !=
          null) {
        freeNames.add('#this');
      }
    }
  }
  for (final name in freeNames) {
    final binding = ctx.lookupLocal(name);
    if (binding != null) captures[name] = binding;
  }
  ctx.finishMethod();
  final outerBuilder = ctx.builder;
  final fnOffset = beginMethod(ctx, e, e.offset, '<anonymous closure>');
  ctx.resetStack();
  ctx.locals = [];
  ctx.nearestAsyncFrame = -1;
  ctx.exceptionDepth = 0;
  final existingAllocs = e.parameters?.parameters.length ?? 0;
  ctx.beginAllocScope(existingAllocLen: existingAllocs, closure: true);
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
    final binding = Variable.of(
      ctx,
      loaded,
      capture.value.type,
      isFinal: capture.value.isFinal,
      callingConvention: capture.value.callingConvention,
      methodReturnType: capture.value.methodReturnType,
    );
    if (capture.value.captureCell != null) binding.captureCell = loaded;
    ctx.setLocal(capture.key, binding);
  }
  ctx.scopeFrameOffset += existingAllocs;
  final resolvedParams = resolveFPLDefaults(
    ctx,
    e.parameters,
    false,
    allowUnboxed: false,
    sortNamed: true,
    parameterOffset: 1,
  );

  List<FunctionFormalParameter> boundNormalParams = [];
  List<FunctionFormalParameter> boundOptionalParams = [];
  List<FunctionFormalParameter> boundNamedParams = [];
  if (bound != null) {
    final functionType = bound.functionType;
    if (functionType != null) {
      boundNormalParams = functionType.normalParameters;
      boundOptionalParams = functionType.optionalParameters;
      boundNamedParams = functionType.namedParameters.entries
          .map((e) => e.value)
          .sorted((a, b) => a.name!.compareTo(b.name!));
    }
  }

  final boundPositionalParams = [...boundNormalParams, ...boundOptionalParams];
  final inorderBoundParams = [...boundPositionalParams, ...boundNamedParams];

  var i = 0;

  for (final param in resolvedParams) {
    final p = param.parameter;
    Variable vRep;

    p as SimpleFormalParameter;
    var type = CoreTypes.dynamic.ref(ctx);
    if (p.type != null) {
      type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
    } else if (i < inorderBoundParams.length) {
      final fType = inorderBoundParams[i].type;
      if (fType.type != null) {
        type = fType.type!;
      }
    }
    vRep = Variable.of(ctx, SSA('arg_${i + 1}'), type.copyWith(boxed: true));

    ctx.setLocal(p.name!.lexeme, vRep.captureBinding(ctx, p));

    i++;
  }

  ctx.functionSignatures[fnOffset] = MachineFunctionSignature(
    List.filled(resolvedParams.length + 1, MachineRepresentation.object),
    MachineRepresentation.object,
  );
  final b = e.body;

  if (b.isAsynchronous) {
    setupAsyncFunction(ctx);
  }

  StatementInfo? stInfo;
  if (b is BlockFunctionBody) {
    stInfo = compileBlock(
      b.block,
      /*AlwaysReturnType.fromAnnotation(ctx, ctx.library, d.returnType, CoreTypes.dynamic.ref(ctx))*/
      AlwaysReturnType(CoreTypes.dynamic.ref(ctx), false),
      ctx,
      name: '(closure)',
    );
  } else if (b is ExpressionFunctionBody) {
    ctx.beginAllocScope();
    final V = compileExpression(b.expression, ctx);
    stInfo = doReturn(
      ctx,
      AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true),
      V,
      isAsync: b.isAsynchronous,
    );
    ctx.endAllocScope();
  } else {
    throw CompileError('Unsupported function body type: ${b.runtimeType}');
  }

  if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
    if (b.isAsynchronous) {
      asyncComplete(ctx, null);
      ctx.endAllocScope(popValues: false);
    } else {
      ctx.endAllocScope();
      ctx.pushOp(Return(null));
    }
  }

  ctx.finishMethod();
  ctx.activeGraph = outerGraph;
  ctx.builder = outerBuilder;
  ctx.currentFunctionId = outerFunctionId;
  ctx.funcLabel = outerFunctionLabel;
  ctx.hasBegunMethod = true;
  ctx.nearestAsyncFrame = outerAsyncFrame;
  ctx.entrypoint = outerEntrypoint;
  ctx.exceptionDepth = outerExceptionDepth;

  ctx.labels.addAll(outerLabels);
  ctx.caughtExceptionTargets.addAll(outerExceptions);
  ctx.restoreState(ctxSaveState);
  ctx.scopeFrameOffset = sfo;

  final positional =
      (e.parameters?.parameters.where((element) => element.isPositional) ?? []);
  final requiredPositionalArgCount = positional
      .where((element) => element.isRequired)
      .length;

  final positionalArgTypes = positional
      .map(
        (a) => a is NormalFormalParameter
            ? a
            : (a as DefaultFormalParameter).parameter,
      )
      .cast<SimpleFormalParameter>()
      .mapIndexed((i, a) {
        if (a.type != null) {
          return TypeRef.fromAnnotation(ctx, ctx.library, a.type!);
        }
        if (i < boundPositionalParams.length) {
          final fType = boundPositionalParams[i].type;
          if (fType.type != null) {
            return fType.type!;
          }
        }
        return CoreTypes.dynamic.ref(ctx);
      })
      .map((t) => t.toRuntimeType(ctx))
      .map((rt) => rt.toJson())
      .toList();

  final named =
      (e.parameters?.parameters.where((element) => element.isNamed) ?? []);
  final sortedNamedArgs = named.toList()
    ..sort((e1, e2) => (e1.name!.lexeme).compareTo((e2.name!.lexeme)));
  final sortedNamedArgNames = sortedNamedArgs
      .map((e) => e.name!.lexeme)
      .toList();

  final sortedNamedArgTypes = sortedNamedArgs
      .map((e) => e is DefaultFormalParameter ? e.parameter : e)
      .cast<SimpleFormalParameter>()
      .mapIndexed((i, a) {
        if (a.type != null) {
          return TypeRef.fromAnnotation(ctx, ctx.library, a.type!);
        }
        if (i < boundNamedParams.length) {
          final fType = boundNamedParams[i].type;
          if (fType.type != null) {
            return fType.type!;
          }
        }
        return CoreTypes.dynamic.ref(ctx);
      })
      .map((t) => t.toRuntimeType(ctx))
      .map((rt) => rt.toJson())
      .toList();

  Object? parameterDefault(FormalParameter parameter) {
    final value = evaluateDefaultValue(
      ctx,
      ctx.library,
      parameter is DefaultFormalParameter ? parameter.defaultValue : null,
    );
    final normal = parameter is DefaultFormalParameter
        ? parameter.parameter
        : parameter;
    if (value is int &&
        normal is SimpleFormalParameter &&
        normal.type != null &&
        TypeRef.fromAnnotation(ctx, ctx.library, normal.type!) ==
            CoreTypes.double.ref(ctx)) {
      return value.toDouble();
    }
    return value;
  }

  final target = DeferredOrOffset(offset: fnOffset);
  return Variable.ssa(
    ctx,
    CreateClosure(
      ctx.svar('closure'),
      target,
      captures.values.map((v) => v.captureCell ?? v.ssa).toList(),
      requiredPositional: requiredPositionalArgCount,
      positionalTypes: positionalArgTypes,
      namedNames: sortedNamedArgNames,
      namedTypes: sortedNamedArgTypes,
      positionalDefaults: positional.map(parameterDefault).toList(),
      namedDefaults: sortedNamedArgs.map(parameterDefault).toList(),
      requiredNamed: [
        for (final parameter in sortedNamedArgs)
          if (parameter.isRequired) parameter.name!.lexeme,
      ],
    ),
    CoreTypes.function.ref(ctx),
    methodReturnType: AlwaysReturnType(CoreTypes.dynamic.ref(ctx), false),
    methodOffset: target,
    callingConvention: CallingConvention.dynamic,
  );
}
