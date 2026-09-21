import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/async.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/model/function_type.dart';

import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart'
    show representationForType;

int compileMethodDeclaration(
  MethodDeclaration d,
  CompilerContext ctx,
  Declaration parent,
) {
  final b = d.body;
  final parentName = declarationName(parent);
  final methodName = d.name.lexeme;
  final pos = ctx.beginFunction('$parentName.$methodName()');
  final previousTypes = {...?ctx.temporaryTypes[ctx.library]};
  TypeRef.loadTemporaryTypes(
    ctx,
    d.typeParameters?.typeParameters,
    owner: 'method:${ctx.library}:$parentName.$methodName:$pos',
  );
  final typeParameters =
      d.typeParameters?.typeParameters ?? const <TypeParameter>[];
  ctx.functionTypeParameterBounds[pos] = [
    for (final parameter in typeParameters)
      ctx
              .temporaryTypes[ctx.library]![parameter.name.lexeme]!
              .typeParameterBound ??
          CoreTypes.dynamic.ref(ctx),
  ];
  ctx.functionRuntimeTypes[pos] = declaredFunctionType(
    ctx,
    ctx.library,
    d.parameters,
    d.returnType,
    d.typeParameters,
  );

  ctx.beginScope();
  if (!d.isStatic) {
    ctx.pushOp(Parameter(SSA('arg_0'), 0));
    ctx.setLocal('#this', Variable.of(ctx, SSA('arg_0'), TypeRef.$this(ctx)!));
  }
  final resolvedParams = d.parameters == null
      ? <FormalParameter>[]
      : resolveFPLDefaults(ctx, d.parameters, !d.isStatic, allowUnboxed: false);

  if (b.isAsynchronous) {
    setupAsyncFunction(
      ctx,
      returnType: d.returnType == null
          ? null
          : TypeRef.fromAnnotation(ctx, ctx.library, d.returnType!),
    );
  }

  var i = d.isStatic ? 0 : 1;

  for (final p in resolvedParams) {
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

    // `_` parameters are wildcards: non-binding and repeatable.
    if (p.name!.lexeme != '_') {
      ctx.setLocal(
        p.name!.lexeme,
        Variable.of(ctx, SSA('arg_$i'), type).captureBinding(ctx, p),
      );
    }

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
    returnType == CoreTypes.voidType.ref(ctx) && !b.isAsynchronous
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
    ctx.beginScope();
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
    ctx.endScope();
  } else if (b is EmptyFunctionBody) {
    ctx.endScope();
    ctx.temporaryTypes[ctx.library] = previousTypes;
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

  ctx.endScope();
  ctx.temporaryTypes[ctx.library] = previousTypes;

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
            .enclosingLibrary ??
                ctx.library]![parentName]![mapIndex][ctx.memberNameKey(methodName)] =
        pos;
  }

  return pos;
}
