import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/async.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';

import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart'
    show representationForType;

void compileFunctionDeclaration(FunctionDeclaration d, CompilerContext ctx) {
  final pos = ctx.beginFunction('${d.name.lexeme}()');
  ctx.topLevelDeclarationPositions[ctx.library]![d.name.lexeme] = pos;

  final overrideAnno = d.metadata.firstWhereOrNull(
    (element) => element.name.name == 'RuntimeOverride',
  );
  if (overrideAnno != null) {
    final oArgs = overrideAnno.arguments!.arguments;
    final name = oArgs.first as StringLiteral;
    String? version;
    if (oArgs.length == 2) {
      final exp = (oArgs[1] as NamedArgument);
      if (exp.name.lexeme != 'version') {
        throw CompileError(
          'Invalid @RuntimeOverride annotation',
          d,
          ctx.library,
          ctx,
        );
      }
      final version0 = exp.argumentExpression as StringLiteral;
      version = version0.stringValue;
    }
    final overrideName = name.stringValue!;
    ctx.runtimeOverrideMap[overrideName] = OverrideSpec(
      pos,
      version ?? '<${ctx.version}',
    );
  }

  ctx.beginScope();
  final previousTypes = {...?ctx.temporaryTypes[ctx.library]};
  TypeRef.loadTemporaryTypes(
    ctx,
    d.functionExpression.typeParameters?.typeParameters,
    owner: 'function:${ctx.library}:${d.name.lexeme}:$pos',
  );
  final typeParameters =
      d.functionExpression.typeParameters?.typeParameters ??
      const <TypeParameter>[];
  ctx.functionTypeParameterBounds[pos] = [
    for (final parameter in typeParameters)
      ctx
              .temporaryTypes[ctx.library]![parameter.name.lexeme]!
              .typeParameterBound ??
          CoreTypes.dynamic.ref(ctx),
  ];

  final resolvedParams = resolveFPLDefaults(
    ctx,
    d.functionExpression.parameters,
    false,
    allowUnboxed: true,
  );

  var i = 0;
  final parameterRepresentations = <MachineRepresentation>[];

  for (final p in resolvedParams) {
    Variable vRep;

    var type = CoreTypes.dynamic.ref(ctx);
    if (p.type != null) {
      type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
    }
    vRep = Variable.of(ctx, SSA('arg_$i'), type.typeAcrossFunctionBoundary);

    // `_` parameters are wildcards: non-binding and repeatable.
    if (p.name!.lexeme != '_') {
      ctx.setLocal(p.name!.lexeme, vRep.captureBinding(ctx, p));
    }
    parameterRepresentations.add(representationForType(vRep.type));

    i++;
  }

  final b = d.functionExpression.body;

  if (b.isAsynchronous) {
    setupAsyncFunction(
      ctx,
      returnType: d.returnType == null
          ? null
          : TypeRef.fromAnnotation(ctx, ctx.library, d.returnType!),
    );
  }

  final expectedReturnType = AlwaysReturnType.fromAnnotation(
    ctx,
    ctx.library,
    d.returnType,
    CoreTypes.dynamic.ref(ctx),
  );
  final returnType = expectedReturnType.type;
  ctx.functionSignatures[pos] = MachineFunctionSignature(
    parameterRepresentations,
    returnType == CoreTypes.voidType.ref(ctx) && !b.isAsynchronous
        ? null
        : representationForType(
            (returnType ?? CoreTypes.dynamic.ref(ctx)).copyWith(
              boxed:
                  b.isAsynchronous ||
                  !(returnType?.isUnboxedAcrossFunctionBoundaries ?? false),
            ),
          ),
  );
  StatementInfo? stInfo;
  if (b is BlockFunctionBody) {
    stInfo = compileBlock(
      b.block,
      expectedReturnType,
      ctx,
      name: '${d.name.lexeme}()',
    );
  } else if (b is ExpressionFunctionBody) {
    ctx.beginScope();
    stInfo = doReturn(
      ctx,
      expectedReturnType,
      compileExpression(b.expression, ctx, expectedReturnType.type),
      isAsync: b.isAsynchronous,
    );
    stInfo = StatementInfo(willAlwaysReturn: true);
    ctx.endScope();
  } else {
    throw CompileError('Unsupported function body type: ${b.runtimeType}');
  }

  ctx.temporaryTypes[ctx.library] = previousTypes;

  if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
    if (b.isAsynchronous) {
      asyncComplete(ctx, null);
      ctx.endScope();
      return;
    }
  }

  ctx.endScope();

  if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
    ctx.pushOp(Return(null));
  }
}
