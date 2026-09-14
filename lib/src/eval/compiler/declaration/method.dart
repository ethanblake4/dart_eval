import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/util.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart'
    show representationForType;

int compileMethodDeclaration(
  MethodDeclaration d,
  CompilerContext ctx,
  NamedCompilationUnitMember parent,
) {
  ///ctx.runPrescan(d);
  final b = d.body;
  final parentName = parent.name.lexeme;
  final methodName = d.name.lexeme;
  final pos = beginMethod(ctx, d, d.offset, '$parentName.$methodName()');

  ctx.beginAllocScope(existingAllocLen: (d.parameters?.parameters.length ?? 0));
  ctx.scopeFrameOffset += d.parameters?.parameters.length ?? 0;
  if (!d.isStatic) {
    ctx.pushOp(Parameter(SSA('arg_0'), 0));
    ctx.setLocal('#this', Variable.of(ctx, SSA('arg_0'), TypeRef.$this(ctx)!));
  }
  final resolvedParams = d.parameters == null
      ? <PossiblyValuedParameter>[]
      : resolveFPLDefaults(ctx, d.parameters, !d.isStatic, allowUnboxed: false);

  if (b.isAsynchronous) {
    setupAsyncFunction(ctx);
  }

  var i = d.isStatic ? 0 : 1;

  for (final param in resolvedParams) {
    final p = param.parameter;

    p as SimpleFormalParameter;
    var type = CoreTypes.dynamic.ref(ctx);
    if (p.type != null) {
      // Method args are always boxed to allow for bridge interop to have a
      // consistent interface
      type = TypeRef.fromAnnotation(
        ctx,
        ctx.library,
        p.type!,
      ).copyWith(boxed: true);
    }

    ctx.setLocal(p.name!.lexeme, Variable.of(ctx, SSA('arg_$i'), type));

    i++;
  }

  final expectedReturnType = AlwaysReturnType.fromAnnotation(
    ctx,
    ctx.library,
    d.returnType,
    CoreTypes.dynamic.ref(ctx),
  );
  final returnType = expectedReturnType.type;
  final unboxedOperatorReturn =
      b is ExpressionFunctionBody &&
      !b.isAsynchronous &&
      (methodName == '==' || methodName == '!=') &&
      (returnType?.isUnboxedAcrossFunctionBoundaries ?? false);
  ctx.functionSignatures[pos] = MachineFunctionSignature(
    List.filled(
      resolvedParams.length + (d.isStatic ? 0 : 1),
      MachineRepresentation.object,
    ),
    returnType == CoreTypes.voidType.ref(ctx)
        ? null
        : unboxedOperatorReturn
        ? representationForType(returnType!.copyWith(boxed: false))
        : MachineRepresentation.object,
  );

  StatementInfo? stInfo;
  if (b is BlockFunctionBody) {
    stInfo = compileBlock(
      b.block,
      expectedReturnType,
      ctx,
      name: '$methodName()',
    );
  } else if (b is ExpressionFunctionBody) {
    ctx.beginAllocScope();
    final V = compileExpression(b.expression, ctx);
    stInfo = doReturn(
      ctx,
      expectedReturnType,
      V,
      isAsync: b.isAsynchronous,
      // == and != operators are statically guaranteed to return bools,
      // so we can optimize boxing away here.
      skipClassBoxing: d.name.lexeme == '==' || d.name.lexeme == '!=',
    );
    ctx.endAllocScope();
  } else if (b is EmptyFunctionBody) {
    ctx.endAllocScope();
    return -1;
  } else {
    throw CompileError('Unknown function body type ${b.runtimeType}');
  }

  if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
    if (b.isAsynchronous) {
      asyncComplete(ctx, null);
    } else {
      ctx.pushOp(Return(null));
    }
  }

  ctx.endAllocScope();

  if (d.isStatic) {
    ctx.topLevelDeclarationPositions[ctx.library]!['$parentName.$methodName'] =
        pos;
  } else {
    final mapIndex = d.isGetter
        ? 0
        : d.isSetter
        ? 1
        : 2;
    ctx.instanceDeclarationPositions[ctx
            .library]![parentName]![mapIndex][methodName] =
        pos;
  }

  return pos;
}
